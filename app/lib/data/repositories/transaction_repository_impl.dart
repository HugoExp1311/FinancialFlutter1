import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:app/data/models/app_wallet.dart'; 
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TransactionRepositoryImpl(this._isar, this._supabase);

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

  // ==========================================================
  // 1. THÊM GIAO DỊCH
  // ==========================================================
  @override
  Future<void> addTransaction(TransactionEntity entity) async {
    // Tự sinh UUID nếu giao dịch chưa có ID
    final String newId = (entity.syncId.isEmpty) ? _uuid.v4() : entity.syncId;
    final tx = AppTransaction.fromEntity(entity.copyWith(syncId: newId));
    
    // Lưu Local trước 
    await _isar.writeTxn(() => _isar.appTransactions.put(tx));
    // Đẩy lên Cloud
    await _pushToSupabase(tx);
  }

  // ==========================================================
  // 2. SỬA GIAO DỊCH 
  // ==========================================================
  @override
  Future<void> updateTransaction(TransactionEntity entity) async {
    // Tìm giao dịch cũ trong máy
    final existingTx = await _isar.appTransactions.filter().syncIdEqualTo(entity.syncId).findFirst();
    
    if (existingTx != null) {
      existingTx.applyFromEntity(entity); // Cập nhật walletId và các trường mới
      existingTx.updatedAt = DateTime.now();
      
      // Lưu Local
      await _isar.writeTxn(() => _isar.appTransactions.put(existingTx));
      // Đẩy lên Cloud 
      await _pushToSupabase(existingTx);
    }
  }

  // ==========================================================
  // 3. XÓA GIAO DỊCH
  // ==========================================================
  @override 
  Future<void> deleteTransaction(String syncId) async {
    final existingTx = await _isar.appTransactions.filter().syncIdEqualTo(syncId).findFirst();
    if (existingTx != null) {
      existingTx.isDeleted = true;
      existingTx.updatedAt = DateTime.now();
      
      // Lưu Local
      await _isar.writeTxn(() => _isar.appTransactions.put(existingTx));
      // Đẩy lên Cloud
      await _pushToSupabase(existingTx);
    }
  }

  @override
  Future<void> syncAll() async {
    // 1. PUSH Transactions
    final offlineTxs = await _isar.appTransactions.filter().isSyncedEqualTo(false).findAll();
    for (final tx in offlineTxs) { await _pushToSupabase(tx); }

    // 2. PULL WALLETS 
    try {
      final walletResponse = await _supabase.from('wallets').select().eq('user_id', _supabase.auth.currentUser?.id ?? '');
      final List<AppWallet> pulledWallets = [];
      for (var row in walletResponse) {
        final existing = await _isar.appWallets.filter().syncIdEqualTo(row['id']).findFirst();
        final wallet = existing ?? AppWallet();
        wallet.syncId = row['id'];
        wallet.name = row['name'] ?? 'Main Wallet';
        wallet.balance = (row['balance'] as num?)?.toDouble() ?? 0.0;
        wallet.userId = row['user_id'];
        wallet.isSynced = true;
        wallet.updatedAt = DateTime.now();
        pulledWallets.add(wallet);
      }
      if (pulledWallets.isNotEmpty) {
        await _isar.writeTxn(() => _isar.appWallets.putAll(pulledWallets));
      }
    } catch (e) { debugPrint('🔴 Lỗi Pull Wallets: $e'); }

    // 3. PULL TRANSACTIONS
    try {
      final response = await _supabase.from('transactions').select();
      final List<AppTransaction> pulledTxs = [];
      for (final row in response) {
        final existingTx = await _isar.appTransactions.filter().syncIdEqualTo(row['sync_id']).findFirst();
        final cloudUpdatedAt = DateTime.parse(row['updated_at']);
        if (existingTx == null || existingTx.updatedAt.isBefore(cloudUpdatedAt)) {
          final newTx = existingTx ?? AppTransaction();
          newTx.applyFromRow(row); 
          pulledTxs.add(newTx);
        }
      }
      if (pulledTxs.isNotEmpty) {
        await _isar.writeTxn(() => _isar.appTransactions.putAll(pulledTxs));
      }
    } catch (e) { debugPrint('🔴 Pull Transactions failed: $e'); }
  }

  @override Future<List<TransactionEntity>> getTransactions() async => [];
  @override Future<TransactionEntity?> getTransactionBySyncId(String s) async => null;
  
  // ==========================================================
  // HÀM SYNC CLOUD 
  // ==========================================================
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
        'wallet_id': tx.walletId, 
      };

      // Đẩy lên Supabase 
      await _supabase.from('transactions').upsert(data, onConflict: 'sync_id');

      // Nếu API gọi thành công thì update cờ local = đồng bộ
      tx.isSynced = true;
      await _isar.writeTxn(() async {
        await _isar.appTransactions.put(tx);
      });
      
      debugPrint('🟢 Push Supabase thành công sync_id: ${tx.syncId} (Wallet: ${tx.walletId})');
    } catch (e) {
      debugPrint('🔴 Lỗi Push Supabase: $e');
    }
  }
}