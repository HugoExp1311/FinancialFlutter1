import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:app/data/models/app_wallet.dart'; // Import model ví của bà

class TransactionRepositoryImpl implements ITransactionRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

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

  // MỚI: Thực hiện lấy ví từ Isar và chuyển sang Entity
  @override
  Stream<List<WalletEntity>> watchWallets() {
    return _isar.appWallets
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.map((wallet) => wallet.toEntity()).toList());
  }

  @override
  Future<void> addTransaction(TransactionEntity entity) async {
    final tx = AppTransaction.fromEntity(entity);
    await _isar.writeTxn(() => _isar.appTransactions.put(tx));
    _pushToSupabase(tx);
  }

  @override
  Future<void> syncAll() async {
    // 1. PUSH Transactions
    final offlineTxs = await _isar.appTransactions.filter().isSyncedEqualTo(false).findAll();
    for (final tx in offlineTxs) { await _pushToSupabase(tx); }

    // 2. PULL WALLETS - Cập nhật số dư balance từ Web về App[cite: 8]
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
          newTx.applyFromRow(row); // Đảm bảo hàm này có trong model AppTransaction[cite: 10]
          pulledTxs.add(newTx);
        }
      }
      if (pulledTxs.isNotEmpty) {
        await _isar.writeTxn(() => _isar.appTransactions.putAll(pulledTxs));
      }
    } catch (e) { debugPrint('🔴 Pull Transactions failed: $e'); }
  }

  // Các hàm override khác bà để trống hoặc throw Unimplemented để hết lỗi
  @override Future<List<TransactionEntity>> getTransactions() async => [];
  @override Future<TransactionEntity?> getTransactionBySyncId(String s) async => null;
  @override Future<void> updateTransaction(TransactionEntity e) async {}
  @override Future<void> deleteTransaction(String s) async {}
  
  Future<void> _pushToSupabase(AppTransaction tx) async { /* Logic push bà đã có sẵn */ }
}