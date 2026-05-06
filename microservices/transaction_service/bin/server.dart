import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:transaction_service/handlers/transaction_handler.dart';
import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';
import 'package:transaction_service/data/repositories/transaction_repository_supabase.dart';
import 'package:core_domain/core_domain.dart';

void main() async {
  // Load .env from monolith root since we are sharing it for the homework
  var env = DotEnv(includePlatformEnvironment: true)..load(['../../app/.env']);
  
  final supabaseUrl = env['SUPABASE_URL'] ?? Platform.environment['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'] ?? Platform.environment['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Missing Supabase credentials in .env');
    exit(1);
  }

  // Initialize dependencies
  final repository = TransactionRepositorySupabase(supabaseUrl, supabaseKey);
  final addUseCase = AddTransactionUseCase(repository);
  final updateUseCase = UpdateTransactionUseCase(repository);
  final deleteUseCase = DeleteTransactionUseCase(repository);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? 'localhost';

  final router = Router();
  final handler = TransactionHandler(
    repository: repository,
    addUseCase: addUseCase,
    updateUseCase: updateUseCase,
    deleteUseCase: deleteUseCase,
  );

  router.get('/health', handler.health);
  router.get('/transactions', handler.getTransactions);
  router.post('/transactions', handler.createTransaction);
  router.put('/transactions/<syncId>', handler.updateTransaction);
  router.delete('/transactions/<syncId>', handler.deleteTransaction);

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(pipeline, host, port);
  print('✅ Transaction Service running at http://${server.address.host}:${server.port}');
}
