import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TransactionRepository(this._isar, this._supabase);

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  Stream<List<AppTransaction>> watchTransactions() {
    return _isar.appTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<double> getTotalExpense() async {
    final expenseSum = await _isar.appTransactions
        .filter()
        .isExpenseEqualTo(true)
        .isDeletedEqualTo(false)
        .amountProperty()
        .sum();
    return expenseSum;
  }

  // ---------------------------------------------------------------------------
  // WRITE (Local DB + Cloud Sync)
  // ---------------------------------------------------------------------------

  Future<void> addTransaction(AppTransaction tx) async {
    tx.syncId = _uuid.v4();
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    // Lưu local trước để UI phản hồi nhanh
    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushSingleToSupabase(tx);
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushSingleToSupabase(tx);
  }

  Future<void> deleteTransaction(int localId) async {
    final tx = await _isar.appTransactions.get(localId);
    if (tx == null) return;

    // Đánh cờ xóa (Soft delete)
    tx.isDeleted = true;
    tx.updatedAt = DateTime.now();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushSingleToSupabase(tx);
  }

  // ---------------------------------------------------------------------------
  // SYNC LOGIC
  // ---------------------------------------------------------------------------

  // Hàm phụ đẩy 1 record lên Supabase
  Future<void> _pushSingleToSupabase(AppTransaction tx) async {
    try {
      final data = {
        'sync_id': tx.syncId,
        'user_id': _supabase.auth.currentUser?.id,
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
      };

      await _supabase.from('transactions').upsert(data, onConflict: 'sync_id');

      // Nếu API gọi thành công thì update cờ local
      tx.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appTransactions.put(tx);
      });
    } catch (e) {
      debugPrint('Lỗi Push Supabase: $e');
    }
  }

  // Đồng bộ hai chiều
  Future<void> syncAll() async {
    // 1. PUSH
    final offlineTxs = await _isar.appTransactions
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

    for (var tx in offlineTxs) {
      await _pushSingleToSupabase(tx);
    }

    // 2. PULL
    try {
      final response = await _supabase.from('transactions').select();
      final List<AppTransaction> pulledTxs = [];

      for (var row in response) {
        final existingTx = await _isar.appTransactions
            .filter()
            .syncIdEqualTo(row['sync_id'])
            .findFirst();

        final cloudUpdatedAt = DateTime.parse(row['updated_at']);

        // Check logic ghi đè nếu data cloud mới hơn
        if (existingTx == null || existingTx.updatedAt.isBefore(cloudUpdatedAt)) {
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
          newTx.isSynced = true; 

          pulledTxs.add(newTx);
        }
      }

      if (pulledTxs.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.appTransactions.putAll(pulledTxs);
        });
      }
    } catch (e) {
      debugPrint('Lỗi Pull Supabase: $e');
    }
  }
}