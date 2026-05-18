import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [DeleteTransactionUseCase] — xử lý xóa tạm thời giao dịch

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
