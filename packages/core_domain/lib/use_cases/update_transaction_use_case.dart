import 'package:core_domain/entities/transaction_entity.dart';
import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [UpdateTransactionUseCase] — Xử lý logic cập nhật giao dịch.
///
/// Nhận vào entity đã có (với syncId hoặc localId), áp dụng thay đổi
/// và ghi lại timestamp `updatedAt` đúng thời điểm — đảm bảo
/// logic đồng bộ Cloud-Local luôn nhất quán.
class UpdateTransactionUseCase {
  final ITransactionRepository _repository;

  UpdateTransactionUseCase(this._repository);

  Future<void> execute(TransactionEntity existing, {
    double? amount,
    bool? isExpense,
    DateTime? date,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorHex,
    String? note,
  }) async {
    // --- VALIDATION ---
    final newAmount = amount ?? existing.amount;
    if (newAmount <= 0) {
      throw ArgumentError('Số tiền phải lớn hơn 0. Giá trị nhận được: $newAmount');
    }

    final newCategory = categoryName ?? existing.categoryName;
    if (newCategory.trim().isEmpty) {
      throw ArgumentError('Danh mục không được để trống.');
    }

    // --- TẠO BẢN SAO MỚI (Immutable entity) ---
    final updated = existing.copyWith(
      amount: amount,
      isExpense: isExpense,
      date: date,
      categoryName: categoryName?.trim(),
      categoryIconCode: categoryIconCode,
      categoryColorHex: categoryColorHex,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      updatedAt: DateTime.now().toUtc(), // Bắt buộc cập nhật timestamp
      isSynced: false,           // Đánh dấu cần sync lại
    );

    await _repository.updateTransaction(updated);
  }
}
