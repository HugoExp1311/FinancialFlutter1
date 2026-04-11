import 'package:core_domain/entities/transaction_entity.dart';
import 'package:core_domain/entities/wallet_entity.dart'; // Thêm dòng này

abstract interface class ITransactionRepository {
  // --- Các hàm cũ giữ nguyên ---
  Stream<List<TransactionEntity>> watchTransactions();
  Future<List<TransactionEntity>> getTransactions();
  Future<TransactionEntity?> getTransactionBySyncId(String syncId);

  // MỚI: Thêm hàm theo dõi ví vào Interface
  Stream<List<WalletEntity>> watchWallets();

  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String syncId);
  Future<void> syncAll();
}