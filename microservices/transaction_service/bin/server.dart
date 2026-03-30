import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:transaction_service/handlers/transaction_handler.dart';

/// Entry point cho Transaction Microservice.
///
/// Chạy bằng lệnh:
///   dart run bin/server.dart
///
/// Mặc định lắng nghe tại: http://localhost:8080
void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? 'localhost';

  // --- ROUTER ---
  final router = Router();
  final handler = TransactionHandler();

  // Đăng ký các routes
  router.get('/health', handler.health);
  router.get('/transactions', handler.getTransactions);
  router.post('/transactions', handler.createTransaction);
  router.put('/transactions/<syncId>', handler.updateTransaction);
  router.delete('/transactions/<syncId>', handler.deleteTransaction);

  // --- MIDDLEWARE PIPELINE ---
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())        // Log mọi request ra console
      .addMiddleware(_corsMiddleware())     // Cho phép Flutter Web gọi API
      .addHandler(router.call);

  final server = await shelf_io.serve(pipeline, host, port);
  print('✅ Transaction Service running at http://${server.address.host}:${server.port}');
}

/// CORS Middleware — Cho phép Flutter Web (hoặc Postman) gọi API.
Middleware _corsMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      // Với OPTIONS preflight request, trả về luôn
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
