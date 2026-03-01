import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TransactionRepository(this._isar, this._supabase);

  // --- LẤY DỮ LIỆU TỪ ISAR CỤC BỘ (TỐC ĐỘ O(1), TRỰC TIẾP LÊN UI) ---

  /// Theo dõi danh sách Giao dịch theo thời gian thực (Reactive)
  Stream<List<AppTransaction>> watchTransactions() {
    return _isar.appTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  /// Tính tổng chi tiêu của tất cả các giao dịch (Ví dụ)
  Future<double> getTotalExpense() async {
    final expenseSum = await _isar.appTransactions
        .filter()
        .isExpenseEqualTo(true)
        .isDeletedEqualTo(false)
        .amountProperty()
        .sum();
    return expenseSum;
  }

  // --- CRUD GIAO DỊCH (LOCAL + OFFLINE-FIRST SYNC) ---

  /// 1. TẠO MỚI GIAO DỊCH
  Future<void> addTransaction(AppTransaction tx) async {
    // 1. Chuẩn bị dữ liệu định danh
    tx.syncId = _uuid.v4();
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    // 2. Lưu vào CSDL Isar cục bộ ngay lập tức (Để UI cập nhật ngay)
    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    // 3. Cố gắng đẩy lên Supabase âm thầm dưới Background
    _pushSingleToSupabase(tx);
  }

  /// 2. SỬA GIAO DỊCH
  Future<void> updateTransaction(AppTransaction tx) async {
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushSingleToSupabase(tx);
  }

  /// 3. XOÁ GIAO DỊCH (XOÁ MỀM)
  Future<void> deleteTransaction(int localId) async {
    final tx = await _isar.appTransactions.get(localId);
    if (tx == null) return;

    // Đánh cờ xóa mềm
    tx.isDeleted = true;
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushSingleToSupabase(tx);
  }

  // --- LOGIC ĐỒNG BỘ VỚI ĐÁM MÂY (SUPABASE SYNC LOGIC) ---

  /// Hàm hỗ trợ: Cố gắng đẩy 1 record lên Supabase.
  /// Nếu không có mạng, nó sẽ thất bại (catch error), cờ isSynced vẫn là False ngầm đợi.
  Future<void> _pushSingleToSupabase(AppTransaction tx) async {
    try {
      final data = {
        'sync_id': tx.syncId,
        'amount': tx.amount,
        'is_expense': tx.isExpense,
        'category_name': tx.categoryName,
        'category_icon_code': tx.categoryIconCode,
        'category_color_hex': tx.categoryColorHex,
        'note': tx.note,
        'date': tx.date.toIso8601String(),
        'updated_at': tx.updatedAt.toIso8601String(),
        'is_synced': true, // Lên mây là true
        'is_deleted': tx.isDeleted,
      };

      // Upsert: Nếu trùng ID thì ghi đè, nếu chưa có thì cấy mới
      await _supabase.from('transactions').upsert(data);

      // Nếu thành công không ném lỗi, ta đánh dấu trong máy Local là đã Sync
      tx.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appTransactions.put(tx);
      });
    } catch (e) {
      // Mất mạng hoặc Server lỗi: Không làm gì cả, isSynced vẫn = false
      debugPrint('Push to Supabase failed. Kept offline. Error: $e');
    }
  }

  /// HÀM ĐỒNG BỘ TOÀN DIỆN (Thường gọi khi vừa mở App HOẶC vuốt để Refresh)
  Future<void> syncAll() async {
    // -------------------------------------------------------------------
    // BƯỚC 1: PUSH (Đẩy những gì chưa được đưa lên Mây lên Mây)
    // -------------------------------------------------------------------
    final offlineTxs = await _isar.appTransactions
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

    for (var tx in offlineTxs) {
      await _pushSingleToSupabase(tx);
    }

    // -------------------------------------------------------------------
    // BƯỚC 2: PULL (Kéo những dữ liệu mới/bị sửa từ thiết bị khác về Máy)
    // -------------------------------------------------------------------
    try {
      // Tối ưu: Chỉ lấy những Record mà Cập Nhật (updated_at) trên Supabase MỚI HƠN
      // cái Record có updatedAt trễ nhất ở Local.
      // Nhưng để đơn giản MVP, ta tạm kéo tất cả thay đổi về (hoặc kéo theo tháng).
      final response = await _supabase.from('transactions').select();

      final List<AppTransaction> pulledTxs = [];

      for (var row in response) {
        // Tìm xem trong máy đã có giao dịch này chưa
        final existingTx = await _isar.appTransactions
            .filter()
            .syncIdEqualTo(row['sync_id'])
            .findFirst();

        final cloudUpdatedAt = DateTime.parse(row['updated_at']);

        // Nếu Máy chưa có -> Bắt buộc nhận
        // Nếu Máy có rồi, nhưng Data trên Mây MỚI HƠN (hoặc ai đó sửa trên Web) -> Chấp nhận ghi đè
        if (existingTx == null ||
            existingTx.updatedAt.isBefore(cloudUpdatedAt)) {
          final newTx = existingTx ?? AppTransaction();
          newTx.syncId = row['sync_id'];
          newTx.amount = (row['amount'] as num).toDouble();
          newTx.isExpense = row['is_expense'];
          newTx.categoryName = row['category_name'];
          newTx.categoryIconCode = row['category_icon_code'];
          newTx.categoryColorHex = row['category_color_hex'];
          newTx.note = row['note'];
          newTx.date = DateTime.parse(row['date']);
          newTx.updatedAt = cloudUpdatedAt;
          newTx.isDeleted = row['is_deleted'];
          newTx.isSynced = true; // Kéo từ Mây về nên mặc định là True

          pulledTxs.add(newTx);
        }
      }

      // Lưu 1 cục thay đổi (WriteBatch) vào CSDL cực nhanh
      if (pulledTxs.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.appTransactions.putAll(pulledTxs);
        });
      }
    } catch (e) {
      debugPrint(
        'Pull from Supabase failed. Working with local Data. Error: $e',
      );
    }
  }
}
