// microservices/transaction_service/lib/data/repositories/transaction_repository_supabase.dart
import 'dart:async';
import 'package:core_domain/core_domain.dart';
import 'package:supabase/supabase.dart';

class TransactionRepositorySupabase implements ITransactionRepository {
  final String supabaseUrl;
  final String supabaseKey;

  TransactionRepositorySupabase(this.supabaseUrl, this.supabaseKey);

  /// Trái tim của việc kích hoạt RLS: 
  /// Thay vì dùng chung 1 cỗ máy không định danh, chúng ta tạo ra client
  /// có đính kèm JWT Token của chính xác Request đang gọi tới.
  PostgrestClient get _db {
    final token = Zone.current[#token] as String?;
    print('🔑 [Transaction DB] Token present: ${token != null}');
    
    return PostgrestClient(
      '$supabaseUrl/rest/v1',
      headers: {
        'apikey': supabaseKey,
        'Authorization': token != null ? 'Bearer $token' : 'Bearer $supabaseKey',
      },
      schema: 'public',
    );
  }

  // Helper method to convert JSON map to TransactionEntity
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
      isSynced: true, // It is in the cloud so it's synced
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  // Helper method to convert Entity to JSON for Supabase
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
      'is_deleted': t.isDeleted,
      // user_id MUST be handled by RLS if using auth header, or passed properly if service role
    };
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    throw UnimplementedError('watchTransactions not used in REST backend');
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final data = await _db
        .from('transactions')
        .select()
        .eq('is_deleted', false)
        .order('date', ascending: false);

    return (data as List).map((row) => _fromJson(row)).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionBySyncId(String syncId) async {
    final data = await _db
        .from('transactions')
        .select()
        .eq('sync_id', syncId)
        .maybeSingle();

    if (data == null) return null;
    return _fromJson(data);
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    await _db
        .from('transactions')
        .upsert(_toJson(transaction), onConflict: 'sync_id');
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    await _db
        .from('transactions')
        .upsert(_toJson(transaction), onConflict: 'sync_id');
  }

  @override
  Future<void> deleteTransaction(String syncId) async {
    await _db
        .from('transactions')
        .update({'is_deleted': true}).eq('sync_id', syncId);
  }

  @override
  Future<void> syncAll() async {
  }
}
