import 'package:equatable/equatable.dart';

/// [TransactionEntity] — Pure domain entity.
///
/// KHÔNG phụ thuộc vào bất kỳ framework nào (Isar, Supabase, Flutter).
/// Đây là "Ngôn ngữ chung" giữa Monolith và Microservices.
///
/// - Monolith:      `TransactionRepositoryImpl` map entity này ↔ Isar collection
/// - Microservices: `TransactionRepositoryHttp` map entity này ↔ JSON từ REST API
class TransactionEntity extends Equatable {
  /// ID cục bộ (dùng trong Isar). Null nếu chưa có (entity mới chưa lưu).
  final int? localId;

  /// UUID — Khóa đồng bộ chính giữa Local và Cloud.
  /// Sinh bởi Use Case, không phải UI.
  final String syncId;

  final double amount;
  final bool isExpense;
  final DateTime date;
  final String? note;

  // --- Category (Flat architecture: nhúng trực tiếp tránh JOIN) ---
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorHex;

  // --- Sync flags (Offline-first) ---
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;
  final String? walletId;

  const TransactionEntity({
    this.localId,
    required this.syncId,
    required this.amount,
    required this.isExpense,
    required this.date,
    this.note,
    required this.categoryName,
    required this.categoryIconCode,
    required this.categoryColorHex,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
    this.walletId,
  });

  /// Tạo bản sao với một số field được thay đổi (Immutable pattern).
  TransactionEntity copyWith({
    int? localId,
    String? syncId,
    double? amount,
    bool? isExpense,
    DateTime? date,
    String? note,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorHex,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
    String? walletId,
  }) {
    return TransactionEntity(
      localId: localId ?? this.localId,
      syncId: syncId ?? this.syncId,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      date: date ?? this.date,
      note: note ?? this.note,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorHex: categoryColorHex ?? this.categoryColorHex,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      walletId: walletId ?? this.walletId,
    );
  }

  @override
  List<Object?> get props => [
        syncId,
        amount,
        isExpense,
        date,
        note,
        categoryName,
        categoryIconCode,
        categoryColorHex,
        updatedAt,
        isSynced,
        isDeleted,
        walletId,
      ];

  @override
  String toString() =>
      'TransactionEntity(syncId: $syncId, amount: $amount, isExpense: $isExpense, date: $date)';
}
