import 'dart:convert';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:core_domain/core_domain.dart';

class TransactionHandler {
  final ITransactionRepository repository;
  final AddTransactionUseCase addUseCase;
  final UpdateTransactionUseCase updateUseCase;
  final DeleteTransactionUseCase deleteUseCase;

  TransactionHandler({
    required this.repository,
    required this.addUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
  });

  /// Hàm trích xuất token từ Authorization Header của App Mobile gửi qua
  String? _extractToken(Request request) {
    final authHeader = request.headers['authorization'] ?? request.headers['Authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }
    return null;
  }

  Future<Response> health(Request request) async {
    return _jsonResponse({'status': 'ok', 'service': 'transaction-service', 'rls_forward_auth': true});
  }

  Future<Response> getTransactions(Request request) async {
    final token = _extractToken(request);
    
    // Gói luồng thực thi vào 1 Zone chứa token, Repository ở tầng đáy có thể móc token này ra!
    return await runZoned(() async {
      try {
        final transactions = await repository.getTransactions();
        final data = transactions.map((t) => {
          'sync_id': t.syncId,
          'amount': t.amount,
          'is_expense': t.isExpense,
          'date': t.date.toIso8601String(),
          'note': t.note,
          'category_name': t.categoryName,
          'category_icon_code': t.categoryIconCode,
          'category_color_hex': t.categoryColorHex,
          'updated_at': t.updatedAt.toIso8601String(),
          'is_deleted': t.isDeleted,
          'wallet_type': t.walletType,
        }).toList();
        return _jsonResponse(data);
      } catch (e) {
        return _jsonResponse({'error': e.toString()}, status: 500);
      }
    }, zoneValues: {#token: token});
  }

  Future<Response> createTransaction(Request request) async {
    final token = _extractToken(request);
    return await runZoned(() async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        // DEBUG: Log wallet_type
        print('🔍 BACKEND DEBUG: Received wallet_type = ${data['wallet_type']}');

        await addUseCase.execute(
          amount: (data['amount'] as num).toDouble(),
          isExpense: data['is_expense'] as bool,
          date: DateTime.parse(data['date'] as String),
          note: data['note'] as String?,
          categoryName: data['category_name'] as String,
          categoryIconCode: data['category_icon_code'] as int,
          categoryColorHex: data['category_color_hex'] as int,
          walletType: data['wallet_type'] as String? ?? 'main',
        );

        return _jsonResponse({'message': 'created successfully'}, status: 201);
      } catch (e) {
        return _jsonResponse({'error': e.toString()}, status: 400);
      }
    }, zoneValues: {#token: token});
  }

  Future<Response> updateTransaction(Request request, String syncId) async {
    final token = _extractToken(request);
    return await runZoned(() async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final existingTx = await repository.getTransactionBySyncId(syncId);
        if (existingTx == null) {
          return _jsonResponse({'error': 'Not found'}, status: 404);
        }

        await updateUseCase.execute(
          existingTx,
          amount: (data['amount'] as num?)?.toDouble(),
          isExpense: data['is_expense'] as bool?,
          date: data['date'] != null ? DateTime.parse(data['date'] as String) : null,
          note: data['note'] as String?,
          categoryName: data['category_name'] as String?,
          categoryIconCode: data['category_icon_code'] as int?,
          categoryColorHex: data['category_color_hex'] as int?,
          walletType: data['wallet_type'] as String?,
        );

        return _jsonResponse({'message': 'updated', 'sync_id': syncId});
      } catch (e) {
        return _jsonResponse({'error': e.toString()}, status: 400);
      }
    }, zoneValues: {#token: token});
  }

  Future<Response> deleteTransaction(Request request, String syncId) async {
    final token = _extractToken(request);
    return await runZoned(() async {
      try {
        await deleteUseCase.execute(syncId);
        return _jsonResponse({'message': 'soft-deleted', 'sync_id': syncId});
      } catch (e) {
        return _jsonResponse({'error': e.toString()}, status: 400);
      }
    }, zoneValues: {#token: token});
  }

  Response _jsonResponse(dynamic body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
