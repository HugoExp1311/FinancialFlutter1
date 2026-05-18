import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:app/data/models/app_wallet.dart'; 
import 'package:uuid/uuid.dart';

// Lớp triển khai các thao tác với DB
// Lưu local bằng Isar, sau đó đồng bộ ngầm lên Supabase
class TransactionRepositoryImpl implements ITransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TransactionRepositoryImpl(this._isar, this._supabase);

  // ---------------------------------------------------------------------------
  // READ (đọc dữ liệu)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    return _isar.appTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true)
        .map((list) => list.map((tx) => tx.toEntity()).toList());
  }

  @override
  Stream<List<WalletEntity>> watchWallets() {
    return _isar.appWallets
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.map((wallet) => wallet.toEntity()).toList());
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final txs = await _isar.appTransactions.filter().isDeletedEqualTo(false).findAll();
    return txs.map((tx) => tx.toEntity()).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    final tx = await _isar.appTransactions
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
    return tx?.toEntity();
  }

  // -----------------------------------------------------------
  // WRITE (Thêm, Sửa, Xóa)
  // -----------------------------------------------------------

  @override
  Future<void> addTransaction(TransactionEntity entity) async {
    // Tự sinh UUID nếu giao dịch chưa có ID
    final String newId = (entity.syncId.isEmpty) ? _uuid.v4() : entity.syncId;
    final tx = AppTransaction.fromEntity(entity.copyWith(syncId: newId));

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    // Đẩy lên Supabase chạy background (Offline-first)
    _pushToSupabase(tx);
  }

  @override
  Future<void> updateTransaction(TransactionEntity entity) async {
    // Tìm record cũ để giữ nguyên local Id
    final existing = await _isar.appTransactions
        .filter()
        .syncIdEqualTo(entity.syncId)
        .findFirst();

    final tx = existing ?? AppTransaction();
    tx.applyFromEntity(entity);
    tx.updatedAt = DateTime.now().toUtc();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushToSupabase(tx);
  }

  @override
  Future<void> deleteTransaction(String syncId) async {
    final tx = await _isar.appTransactions
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
    
    if (tx == null) return;

    tx.isDeleted = true;
    tx.updatedAt = DateTime.now().toUtc();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushToSupabase(tx);
  }

  // ----------------------------------------------------------
  // SYNC (đồng bộ Cloud)
  // ----------------------------------------------------------

  @override
  Future<void> syncAll() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return; // Bảo mật: Chưa đăng nhập thì không sync

    // PUSH: Đẩy data local chưa sync lên cloud
    final offlineTxs = await _isar.appTransactions
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    
    for (final tx in offlineTxs) { 
      await _pushToSupabase(tx); 
    }

    // PULL WALLETS: Lấy ví và số dư từ Cloud về
    try {
      final walletResponse = await _supabase.from('wallets').select().eq('user_id', currentUser.id);
      final List<AppWallet> pulledWallets = [];
      for (var row in walletResponse) {
        final existing = await _isar.appWallets.filter().syncIdEqualTo(row['id']).findFirst();
        final wallet = existing ?? AppWallet();
        wallet.syncId = row['id'];
        wallet.name = row['name'] ?? 'Main Wallet';
        wallet.balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
        wallet.userId = row['user_id'];
        // wallet.colorHex = row['color_hex']; // tạm thời ko xài vì set cứng màu cho ví chính ví phụ ở trang ví rồi
        wallet.isDefault = row['is_default'] ?? false;
        if (row['created_at'] != null) {
          wallet.createdAt = DateTime.tryParse(row['created_at']);
        }

        wallet.isSynced = true;
        wallet.updatedAt = DateTime.now();
        pulledWallets.add(wallet);
      }
      if (pulledWallets.isNotEmpty) {
        await _isar.writeTxn(() => _isar.appWallets.putAll(pulledWallets));
      }
    } catch (e) { 
      debugPrint('🔴 Lỗi Pull Wallets: $e'); 
    }

    // PULL TRANSACTIONS: Lấy data mới từ cloud về
    try {
      final response = await _supabase.from('transactions').select().eq('user_id', currentUser.id);
      final List<AppTransaction> pulledTxs = [];
      
      for (final row in response) {
        final existingTx = await _isar.appTransactions.filter().syncIdEqualTo(row['sync_id']).findFirst();
        final cloudUpdatedAt = DateTime.parse(row['updated_at']);

        // Chỉ cập nhật nếu trên cloud mới hơn
        if (existingTx == null || existingTx.updatedAt.isBefore(cloudUpdatedAt)) {
          final newTx = existingTx ?? AppTransaction();
          newTx.applyFromRow(row); 
          pulledTxs.add(newTx);
        }
      }

      // Lưu hàng loạt vào local
      if (pulledTxs.isNotEmpty) {
        await _isar.writeTxn(() => _isar.appTransactions.putAll(pulledTxs));
      }
    } catch (e) {
      debugPrint('🔴 Lỗi khi Pull Transactions từ Supabase: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER
  // ---------------------------------------------------------------------------

  // Hàm phụ: Upsert lên Supabase
  Future<void> _pushToSupabase(AppTransaction tx) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final data = {
        'sync_id': tx.syncId,
        'user_id': currentUser.id,
        'amount': tx.amount,
        'is_expense': tx.isExpense,
        'category_name': tx.categoryName,
        'category_icon_code': tx.categoryIconCode,
        'category_color_hex': tx.categoryColorHex,
        'note': tx.note,
        'date': tx.date.toUtc().toIso8601String(),
        'updated_at': tx.updatedAt.toUtc().toIso8601String(),
        'is_synced': true,
        'is_deleted': tx.isDeleted,
        'wallet_id': tx.walletId, 
      };

      // Đẩy lên Supabase 
      await _supabase.from('transactions').upsert(data, onConflict: 'sync_id');

      // Thành công thì đổi cờ isSynced
      tx.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appTransactions.put(tx);
      });
      
      debugPrint('🟢 Push Supabase thành công sync_id: ${tx.syncId} (Wallet: ${tx.walletId})');
    } catch (e) {
      debugPrint('🔴 Lỗi Push Supabase (Có thể do mất mạng): $e');
    }
  }
}