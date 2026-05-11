import 'package:uuid/uuid.dart';
import 'package:core_domain/entities/transaction_entity.dart';
import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [AddTransactionUseCase] — Xử lý logic tạo mới giao dịch.
///
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
