import 'package:core_domain/core_domain.dart';

class TransactionRepositoryHttp implements ITransactionRepository {
  final String baseUrl;
  TransactionRepositoryHttp({required this.baseUrl});

  @override
  Stream<List<TransactionEntity>> watchTransactions() => throw UnimplementedError();

  // MỚI: Thêm hàm này để hết lỗi "Missing concrete implementation"[cite: 9]
  @override
  Stream<List<WalletEntity>> watchWallets() {
    return const Stream.empty(); // Tạm thời để trống cho bản Microservices
  }

  @override Future<List<TransactionEntity>> getTransactions() async => [];
  @override Future<TransactionEntity?> getTransactionBySyncId(String s) async => null;
  @override Future<void> addTransaction(TransactionEntity t) async {}
  @override Future<void> updateTransaction(TransactionEntity t) async {}
  @override Future<void> deleteTransaction(String s) async {}
  @override Future<void> syncAll() async {}
}