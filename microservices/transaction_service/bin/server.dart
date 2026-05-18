import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:transaction_service/handlers/transaction_handler.dart';

void main() async {
  // Cấu hình Port và Host từ môi trường hệ thống
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? 'localhost';

  final router = Router();
  final handler = TransactionHandler();

  // --- ROUTES ---
  router.get('/health', handler.health);
  router.get('/transactions', handler.getTransactions);
  router.post('/transactions', handler.createTransaction);
  router.put('/transactions/<syncId>', handler.updateTransaction);
  router.delete('/transactions/<syncId>', handler.deleteTransaction);

  // --- PIPELINE CẤU HÌNH ---
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())         // Ghi nhật ký truy cập
      .addMiddleware(_corsMiddleware())     // Cấu hình CORS cho Client
      .addHandler(router.call);

  final server = await shelf_io.serve(pipeline, host, port);
  print('✅ Server đang chạy tại: http://${server.address.host}:${server.port}');
}

/// Middleware xử lý CORS để cho phép các yêu cầu từ Web/Mobile
Middleware _corsMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};