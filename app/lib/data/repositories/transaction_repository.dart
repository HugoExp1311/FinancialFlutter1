import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:app/data/models/app_wallet.dart';
import 'package:core_domain/core_domain.dart'; // Import domain để dùng Entity[cite: 6]
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements ITransactionRepository { // Thêm Implements[cite: 6]
  final Isar _isar;
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TransactionRepositoryImpl(this._isar, this._supabase);

  // Cập nhật hàm này để trả về Entity cho UI[cite: 6]
  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    return _isar.appTransactions
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .watch(fireImmediately: true)
        .map((list) => list.map((tx) => tx.toEntity()).toList());
  }

  // MỚI: Trả về danh sách WalletEntity từ Isar[cite: 6]
  @override
  Stream<List<WalletEntity>> watchWallets() {
    return _isar.appWallets
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.map((wallet) => wallet.toEntity()).toList());
  }

  // --- Các hàm add/update/delete bà giữ nguyên logic cũ ---
  // Lưu ý: Nhớ thêm @override trước các hàm addTransaction, syncAll...[cite: 6]

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    // Logic mapper từ Entity sang AppTransaction rồi mới save Isar[cite: 6]
  }

  @override
  Future<void> syncAll() async {
    // 1. PUSH...
    // 2. PULL WALLETS (Giữ nguyên logic pull bà đã viết rất tốt ở trên)[cite: 6]
    // 3. PULL TRANSACTIONS...
  }

  // Bổ sung các hàm còn thiếu từ Interface để không bị lỗi đỏ class
  @override Future<List<TransactionEntity>> getTransactions() async => [];
  @override Future<TransactionEntity?> getTransactionBySyncId(String s) async => null;
  @override Future<void> updateTransaction(TransactionEntity t) async {}
  @override Future<void> deleteTransaction(String s) async {}
}