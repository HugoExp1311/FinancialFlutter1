import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

// Port configurations mapping
const int gatewayPort = 3000;
const String transactionServiceUrl = 'http://localhost:3001';
const String chatbotServiceUrl = 'http://localhost:3002';

void main(List<String> args) async {
  // 1. Debugging/Logging Middleware (Chuẩn theo debugging-strategies)
  var pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addMiddleware(_errorHandler());

  // 2. Định tuyến (Chuẩn theo microservices-architect)
  final router = Router();

  // Route 1: Rẽ nhánh sang Transaction Service
  router.all('/transactions/<ignored|.*>', (Request request) {
    print('[Gateway 🚀] Forwarding to Transaction Service: ${request.url}');
    return proxyHandler(transactionServiceUrl)(request);
  });

  // Route 2: Rẽ nhánh sang Chatbot Service
  router.all('/chat/<ignored|.*>', (Request request) {
    print('[Gateway 🤖] Forwarding to Chatbot Service: ${request.url}');
    return proxyHandler(chatbotServiceUrl)(request);
  });
  
  // Route check Health (Giành cho Docker Test sức khoẻ mircroservice)
  router.get('/health', (Request request) {
    return Response.ok('{"status": "API Gateway is healthy!"}', headers: {'Content-Type': 'application/json'});
  });

  // Default Route fallback
  router.all('/<ignored|.*>', (Request request) {
    return Response.notFound('{"error": "API Gateway: Route not found"}', headers: {'Content-Type': 'application/json'});
  });

  // 3. Khởi chạy Server
  final handler = pipeline.addHandler(router.call);
  final server = await serve(handler, InternetAddress.anyIPv4, gatewayPort);
  
  print('===================================================');
  print('🛡️  API GATEWAY IS RUNNING (Port: ${server.port})');
  print('===================================================');
  print('Service Matrix:');
  print(' 🟢 Transactions -> $transactionServiceUrl');
  print(' 🟢 Chat AI      -> $chatbotServiceUrl');
  print('---------------------------------------------------');
}

// Global Error Handler (Đón đầu lỗi sập trạm)
Middleware _errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        print('[GATEWAY ERROR CRASH] $e\n$stackTrace');
        return Response.internalServerError(
            body: '{"error": "API Gateway Internal Server Error"}',
            headers: {'Content-Type': 'application/json'});
      }
    };
  };
}

// CORS Middleware giúp Flutter App (Web/Desktop) cắm thoải mái KHÔNG BỊ CHẶN
Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Requested-With',
  };

  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: headers);
    };
  };
}
