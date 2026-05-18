import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final router = Router();

  // Route 1: Đường dẫn Test sức khoẻ của Chatbot (cho Docker health check)
  router.get('/health', (Request request) {
    return Response.ok(
        '{"status": "healthy", "service": "chatbot_service", "version": "1.0.0"}',
        headers: {'Content-Type': 'application/json'});
  });

  // Route 2: Health check với path đầy đủ (backward compatibility)
  router.get('/chat/health', (Request request) {
    print('[Chatbot Service] Có người gõ cửa phòng Health Check!');
    return Response.ok(
        '{"status": "Phòng khách Chatbot mọc rêu chờ bạn! Service đã sẵn sàng!"}',
        headers: {'Content-Type': 'application/json'});
  });

  // Route 3: Chỗ này hứng Data từ ĐT -> Xử lý mông má -> Bắn sang N8N
  router.post('/chat/send', (Request request) async {
    final payload = await request.readAsString();
    print('[Chatbot Service 🤖] Vừa nhận được tin nhắn từ Cổng Gateway dội xuống!');
    
    try {
      // Lấy URL Webhook từ file cấu hình (nếu có), nếu không có thì xài mặc định localhost
      final webhookUrl = Platform.environment['N8N_WEBHOOK_URL'] ?? 'http://host.docker.internal:5678/webhook/ai-chat';
      print('[Chatbot Service 🤖] Đang rẽ nhánh tin nhắn sang não AI tại: $webhookUrl');

      // Bắn payload sang thẳng link Webhook n8n
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      print('[Chatbot Service 🤖] Đã lấy được hồi âm từ AI. Chuyển phát ngược về App...');
      return Response.ok(response.body, headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print('[Chatbot Service 🤖] Lỗi cắm mỏ xuống N8N: $e');
      return Response.internalServerError(
          body: '{"replyMessage": "Chatbot Service đang mất mạng tới bộ não N8N!"}',
          headers: {'Content-Type': 'application/json'});
    }
  });

  // Mặc giáp (Middleware báo Log)
  var pipeline = Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  // Chạy trên cổng từ biến môi trường (mặc định 3002)
  final port = int.parse(Platform.environment['PORT'] ?? '3002');
  final server = await serve(pipeline, InternetAddress.anyIPv4, port);
  print('===================================================');
  print('🤖 CHATBOT SERVICE ĐANG CHỜ LỆNH (Port: ${server.port})');
  print('===================================================');
}
