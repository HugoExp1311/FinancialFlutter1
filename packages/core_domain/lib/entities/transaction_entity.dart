import 'package:equatable/equatable.dart';

/// Thực thể Giao dịch chính trong hệ thống.
/// Chứa toàn bộ thông tin cơ bản về chi tiêu và thu nhập.
class TransactionEntity extends Equatable {
  /// ID cục bộ dùng cho Isar DB
  final int? localId;

  /// Mã UUID dùng để đồng bộ giữa máy và cloud
  final String syncId;

  final double amount;
  final bool isExpense;
  final DateTime date;
  final String? note;

  // --- Thông tin danh mục ---
  final String categoryName;
  final int categoryIconCode;
  final int categoryColorHex;

  // --- Thông tin đồng bộ ---
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

  /// Tạo bản sao mới khi cần thay đổi dữ liệu
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
      'TransactionEntity(syncId: $syncId, amount: $amount, isExpense: $isExpense)';
}