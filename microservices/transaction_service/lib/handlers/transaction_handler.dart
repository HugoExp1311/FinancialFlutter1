import 'dart:convert';
import 'package:shelf/shelf.dart';

/// [TransactionHandler] — Xử lý HTTP requests cho Transaction Resource.
///
/// Hiện tại là STUB (trả về mock data). Khi đi sâu vào Bước 3:
///   1. Inject `ITransactionRepository` (sẽ dùng Supabase trực tiếp hoặc PostgreSQL)
///   2. Inject Use Cases từ `core_domain`
///   3. Map JSON ↔ TransactionEntity
///
/// Ví dụ flow đầy đủ sau này:
///   POST /transactions
///     → parse JSON body → TransactionEntity
///     → AddTransactionUseCase.execute(entity)
///     → return 201 Created
class TransactionHandler {
  // --- HEALTH CHECK ---

  Future<Response> health(Request request) async {
    return _jsonResponse({'status': 'ok', 'service': 'transaction-service'});
  }

  // --- GET /transactions ---

  Future<Response> getTransactions(Request request) async {
    // TODO: Inject SyncTransactionsUseCase + ITransactionRepository
    // TODO: Lấy user_id từ JWT token trong Authorization header
    return _jsonResponse([
      {
        'sync_id': 'stub-uuid-001',
        'amount': 50000.0,
        'is_expense': true,
        'category_name': 'Food',
        'category_icon_code': 0xe56c,
        'category_color_hex': 0xFFFF5722,
        'note': 'Phở bò sáng',
        'date': '2026-03-24T07:30:00.000Z',
        'updated_at': '2026-03-24T07:30:00.000Z',
        'is_deleted': false,
      }
    ]);
  }

  // --- POST /transactions ---

  Future<Response> createTransaction(Request request) async {
    // TODO: Parse body → TransactionEntity → AddTransactionUseCase.execute()
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    // Validation ngắn gọn (Use Case sẽ validate đầy đủ khi implement)
    if (data['amount'] == null || (data['amount'] as num) <= 0) {
      return _jsonResponse({'error': 'amount must be positive'}, status: 400);
    }

    // Stub response — trả lại chính data đã nhận
    return _jsonResponse({'message': 'created', 'data': data}, status: 201);
  }

  // --- PUT /transactions/<syncId> ---

  Future<Response> updateTransaction(Request request, String syncId) async {
    // TODO: Inject UpdateTransactionUseCase
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return _jsonResponse({'message': 'updated', 'sync_id': syncId, 'data': data});
  }

  // --- DELETE /transactions/<syncId> ---

  Future<Response> deleteTransaction(Request request, String syncId) async {
    // TODO: Inject DeleteTransactionUseCase
    return _jsonResponse({'message': 'soft-deleted', 'sync_id': syncId});
  }

  // ---------------------------------------------------------------------------
  // HELPER
  // ---------------------------------------------------------------------------

  Response _jsonResponse(dynamic body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
