import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:core_domain/core_domain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepositoryHttp implements ITransactionRepository {
  final String baseUrl;

  TransactionRepositoryHttp({required this.baseUrl});

  Future<Map<String, String>> _getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  TransactionEntity _fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      syncId: json['sync_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      isExpense: json['is_expense'] as bool,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      categoryName: json['category_name'] as String,
      categoryIconCode: json['category_icon_code'] as int,
      categoryColorHex: json['category_color_hex'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSynced: true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      walletType: json['wallet_type'] as String? ?? 'main',
    );
  }

  Map<String, dynamic> _toJson(TransactionEntity t) {
    return {
      'sync_id': t.syncId,
      'amount': t.amount,
      'is_expense': t.isExpense,
      'date': t.date.toIso8601String(),
      'note': t.note,
      'category_name': t.categoryName,
      'category_icon_code': t.categoryIconCode,
      'category_color_hex': t.categoryColorHex,
      'updated_at': t.updatedAt.toIso8601String(),
      'wallet_type': t.walletType,
    };
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() async* {
    while (true) {
      try {
        final txs = await getTransactions();
        yield txs;
      } catch (e) {
        print('🚨 HTTP GET Error: $e'); // In lỗi ra Console
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final url = Uri.parse('$baseUrl/transactions');
    final response = await http.get(url, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load transactions: ${response.body}');
    }
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    final all = await getTransactions();
    try {
      return all.firstWhere((element) => element.syncId == syncId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final url = Uri.parse('$baseUrl/transactions');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(_toJson(transaction)),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add transaction: ${response.body}');
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final url = Uri.parse('$baseUrl/transactions/${transaction.syncId}');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(_toJson(transaction)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction: ${response.body}');
    }
  }

  @override
  Future<void> deleteTransaction(String syncId) async {
    final url = Uri.parse('$baseUrl/transactions/$syncId');
    final response = await http.delete(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction: ${response.body}');
    }
  }

  @override
  Future<void> syncAll() async {
    // No-op for HTTP repository
  }
}
