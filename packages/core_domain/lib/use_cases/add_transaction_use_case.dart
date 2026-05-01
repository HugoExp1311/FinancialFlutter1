import 'package:uuid/uuid.dart';
import 'package:core_domain/entities/transaction_entity.dart';
import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [AddTransactionUseCase] — Xử lý logic tạo mới giao dịch.
///
/// Trách nhiệm:
///   1. Validate dữ liệu đầu vào (rules thuần túy, không phụ thuộc DB).
///   2. Sinh syncId (UUID) và timestamp — đảm bảo nhất quán giữa 2 phiên bản.
///   3. Gọi repository để lưu trữ.
///
/// Cả Monolith và Microservices đều DÙNG CHUNG use case này.
/// Chỉ khác ở `ITransactionRepository` được inject vào.
class AddTransactionUseCase {
  final ITransactionRepository _repository;
  final _uuid = const Uuid();

  AddTransactionUseCase(this._repository);

  Future<void> execute({
    required double amount,
    required bool isExpense,
    required DateTime date,
    required String categoryName,
    required int categoryIconCode,
    required int categoryColorHex,
    String? note,
  }) async {
    // --- VALIDATION (Business Rules) ---
    if (amount <= 0) {
      throw ArgumentError('Số tiền phải lớn hơn 0. Giá trị nhận được: $amount');
    }
    if (categoryName.trim().isEmpty) {
      throw ArgumentError('Danh mục không được để trống.');
    }

    // --- SINH ĐỊNH DANH (Domain responsibility, không phải UI) ---
    final entity = TransactionEntity(
      syncId: _uuid.v4(),
      amount: amount,
      isExpense: isExpense,
      date: date,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      categoryName: categoryName.trim(),
      categoryIconCode: categoryIconCode,
      categoryColorHex: categoryColorHex,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
      isDeleted: false,
    );

    await _repository.addTransaction(entity);
  }
}
