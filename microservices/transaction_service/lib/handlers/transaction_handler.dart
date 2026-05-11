import 'dart:convert';
import 'package:shelf/shelf.dart';

/// [TransactionHandler] — Handler xử lý các yêu cầu HTTP cho Giao dịch.
class TransactionHandler {
  // --- KIỂM TRA TRẠNG THÁI ---

  Future<Response> health(Request request) async {
    return _jsonResponse({'status': 'ok', 'service': 'transaction-service'});
  }

  // --- LẤY DANH SÁCH ---

  Future<Response> getTransactions(Request request) async {
    // TODO: Kết nối repository và xử lý User ID từ token
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

  // --- TẠO MỚI ---

  Future<Response> createTransaction(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    // Kiểm tra dữ liệu cơ bản
    if (data['amount'] == null || (data['amount'] as num) <= 0) {
      return _jsonResponse({'error': 'amount must be positive'}, status: 400);
    }

    // Tạm thời trả về dữ liệu đã nhận để kiểm tra kết nối
    return _jsonResponse({'message': 'created', 'data': data}, status: 201);
  }

  // --- CẬP NHẬT ---

  Future<Response> updateTransaction(Request request, String syncId) async {
    // TODO: Gọi UpdateTransactionUseCase
    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;
    return _jsonResponse({'message': 'updated', 'sync_id': syncId, 'data': data});
  }

  // --- XÓA ---

  Future<Response> deleteTransaction(Request request, String syncId) async {
    // TODO: Thực hiện xóa mềm (Soft delete)
    return _jsonResponse({'message': 'soft-deleted', 'sync_id': syncId});
  }

  // ---------------------------------------------------------------------------
  // HELPER (Xử lý JSON Response)
  // ---------------------------------------------------------------------------

  Response _jsonResponse(dynamic body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }
}