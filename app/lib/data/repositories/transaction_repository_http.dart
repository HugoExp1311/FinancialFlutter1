import 'package:core_domain/core_domain.dart';

/// Implementation of [ITransactionRepository] via HTTP for Microservices architecture.
/// Replaces direct Isar/Supabase calls with API requests to `transaction_service`.
class TransactionRepositoryHttp implements ITransactionRepository {
  final String baseUrl;
  TransactionRepositoryHttp({required this.baseUrl});

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    // TODO: Implement polling stream hoặc WebSocket connection
    throw UnimplementedError('HTTP stream not implemented yet');
  }

  // MỚI: Thêm hàm theo dõi Ví (Từ nhánh Thu)
  @override
  Stream<List<WalletEntity>> watchWallets() {
    // Tạm thời để trống cho bản Microservices
    return const Stream.empty();
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    // TODO: Implement GET $baseUrl/transactions
    throw UnimplementedError();
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    // TODO: Implement GET $baseUrl/transactions/$syncId
    throw UnimplementedError();
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    // TODO: Implement POST $baseUrl/transactions
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    // TODO: Implement PUT $baseUrl/transactions/${transaction.syncId}
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String syncId) async {
    // TODO: Implement DELETE $baseUrl/transactions/$syncId
    throw UnimplementedError();
  }

  @override
  Future<void> syncAll() async {
    // No-op for Microservices (real-time via HTTP)
  }
}