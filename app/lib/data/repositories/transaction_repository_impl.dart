import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/models/app_transaction.dart';

/// [TransactionRepositoryImpl] — Phiên bản Monolith.
///
/// Implements [ITransactionRepository] bằng Isar (offline-first local DB)
/// và Supabase (cloud sync). Đây là "Infrastructure Layer" của Monolith app.
///
/// ⚡ UI / Use Cases KHÔNG biết class này tồn tại — chúng chỉ thấy [ITransactionRepository].
class TransactionRepositoryImpl implements ITransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  TransactionRepositoryImpl(this._isar, this._supabase);

  // ---------------------------------------------------------------------------
  // READ
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
  Future<List<TransactionEntity>> getTransactions() async {
    final list = await _isar.appTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .findAll();
    return list.map((tx) => tx.toEntity()).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    final tx = await _isar.appTransactions
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
    return tx?.toEntity();
  }

  // ---------------------------------------------------------------------------
  // WRITE
  // ---------------------------------------------------------------------------

  @override
  Future<void> addTransaction(TransactionEntity entity) async {
    // Entity đã có syncId và updatedAt được sinh bởi Use Case
    final tx = AppTransaction.fromEntity(entity);

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    // Âm thầm push lên Supabase dưới background
    _pushToSupabase(tx);
  }

  @override
  Future<void> updateTransaction(TransactionEntity entity) async {
    // Tìm record Isar cũ theo syncId để giữ lại localId (Isar Id)
    final existing = await _isar.appTransactions
        .filter()
        .syncIdEqualTo(entity.syncId)
        .findFirst();

    final tx = existing ?? AppTransaction();
    tx.applyFromEntity(entity);

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
    if (tx == null) { return; }

    tx.isDeleted = true;
    tx.updatedAt = DateTime.now().toUtc();
    tx.isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.appTransactions.put(tx);
    });

    _pushToSupabase(tx);
  }

  // ---------------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------------

  @override
  Future<void> syncAll() async {
    // BƯỚC 1: PUSH — Đẩy những gì chưa sync lên Cloud
    final offlineTxs = await _isar.appTransactions
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

    for (final tx in offlineTxs) {
      await _pushToSupabase(tx);
    }

    // BƯỚC 2: PULL — Kéo những dữ liệu mới/bị sửa từ thiết bị khác về
    try {
      final response = await _supabase.from('transactions').select();
      final List<AppTransaction> pulledTxs = [];

      for (final row in response) {
        final existingTx = await _isar.appTransactions
            .filter()
            .syncIdEqualTo(row['sync_id'])
            .findFirst();

        final cloudUpdatedAt = DateTime.parse(row['updated_at']);

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
      debugPrint('Pull from Supabase failed. Working with local data. Error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPER
  // ---------------------------------------------------------------------------

  /// Cố gắng đẩy 1 record lên Supabase. Nếu offline → thất bại yên lặng,
  /// cờ isSynced = false sẽ chờ đến lần syncAll() tiếp theo.
  Future<void> _pushToSupabase(AppTransaction tx) async {
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

      await _supabase.from('transactions').upsert(
            data,
            onConflict: 'sync_id',
          );

      tx.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appTransactions.put(tx);
      });
    } on PostgrestException catch (e) {
      debugPrint('Supabase 🔴 DB ERROR: ${e.message} | Hint: ${e.hint} | Code: ${e.code}');
    } catch (e) {
      debugPrint('Supabase 🔴 NETWORK/EXCEPTION ERROR: $e');
    }
  }
}
