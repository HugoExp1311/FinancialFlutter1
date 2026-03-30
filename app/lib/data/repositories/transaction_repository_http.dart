import 'package:core_domain/core_domain.dart';

/// [TransactionRepositoryHttp] — Implementation thứ 2 của [ITransactionRepository].
///
/// Dành cho phiên bản MICROSERVICES (Môn học 2).
/// Thay vì gọi Isar/Supabase trực tiếp, mọi thao tác đều là HTTP call
/// đến `transaction_service` backend.
///
/// Để KÍCH HOẠT phiên bản Microservices:
///   Vào `app_providers.dart`, đổi dòng trong `transactionRepositoryProvider`:
///
///   // TẮT Monolith:
///   // return TransactionRepositoryImpl(isar, supabase);
///
///   // BẬT Microservices:
///   return TransactionRepositoryHttp(baseUrl: 'http://localhost:8080');
///
/// ⚠️ Hiện tại là SKELETON — tất cả method đều throw UnimplementedError.
///    Triển khai chi tiết sẽ thực hiện ở Bước 3 (giai đoạn 2).
class TransactionRepositoryHttp implements ITransactionRepository {
  final String baseUrl;

  // TODO: Inject http.Client để dễ mock trong unit tests
  // final http.Client _client;

  TransactionRepositoryHttp({required this.baseUrl});

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    // NOTE: HTTP không hỗ trợ reactive stream tự nhiên.
    // Phương án: Polling (gọi getTransactions() mỗi N giây)
    //           hoặc WebSocket / SSE (Server-Sent Events).
    // TODO: Implement polling stream hoặc WebSocket connection
    throw UnimplementedError('watchTransactions — TODO in Bước 3');
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    // TODO:
    // final response = await _client.get(Uri.parse('$baseUrl/transactions'));
    // final List data = jsonDecode(response.body);
    // return data.map((row) => _mapRowToEntity(row)).toList();
    throw UnimplementedError('getTransactions — TODO in Bước 3');
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    // TODO: GET $baseUrl/transactions/$syncId
    throw UnimplementedError('getTransactionBySyncId — TODO in Bước 3');
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    // TODO:
    // final body = jsonEncode(_mapEntityToJson(transaction));
    // await _client.post(Uri.parse('$baseUrl/transactions'), body: body, ...);
    throw UnimplementedError('addTransaction — TODO in Bước 3');
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    // TODO: PUT $baseUrl/transactions/${transaction.syncId}
    throw UnimplementedError('updateTransaction — TODO in Bước 3');
  }

  @override
  Future<void> deleteTransaction(String syncId) async {
    // TODO: DELETE $baseUrl/transactions/$syncId
    throw UnimplementedError('deleteTransaction — TODO in Bước 3');
  }

  @override
  Future<void> syncAll() async {
    // NOTE: Microservices không cần syncAll() theo nghĩa Offline-First.
    // Mọi thao tác đã real-time qua HTTP — đây là no-op.
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS (TODO — sẽ implement khi đi sâu)
  // ---------------------------------------------------------------------------

  // TransactionEntity _mapRowToEntity(Map<String, dynamic> row) { ... }
  // Map<String, dynamic> _mapEntityToJson(TransactionEntity entity) { ... }
}
