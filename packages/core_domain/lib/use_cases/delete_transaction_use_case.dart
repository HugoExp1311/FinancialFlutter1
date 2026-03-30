import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [DeleteTransactionUseCase] — Xử lý xóa mềm (Soft Delete) giao dịch.
///
/// Không xóa khỏi database. Đánh cờ `isDeleted = true` để:
///   1. Giữ lại lịch sử đồng bộ (sync history).
///   2. Cho phép phục hồi (undo) trong tương lai.
///   3. Lan truyền lệnh xóa tới Cloud và các thiết bị khác.
class DeleteTransactionUseCase {
  final ITransactionRepository _repository;

  DeleteTransactionUseCase(this._repository);

  Future<void> execute(String syncId) async {
    if (syncId.trim().isEmpty) {
      throw ArgumentError('syncId không được để trống.');
    }
    await _repository.deleteTransaction(syncId);
  }
}
