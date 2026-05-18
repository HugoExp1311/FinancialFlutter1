import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [SyncTransactionsUseCase] — Điều phối logic đồng bộ dữ liệu 2 chiều.
///

class SyncTransactionsUseCase {
  final ITransactionRepository _repository;

  SyncTransactionsUseCase(this._repository);

  Future<void> execute() async {
    await _repository.syncAll();
  }
}
