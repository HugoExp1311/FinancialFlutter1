import 'package:core_domain/repositories/i_transaction_repository.dart';

/// [SyncTransactionsUseCase] — Điều phối logic đồng bộ dữ liệu 2 chiều.
///
/// Use case này đặc biệt quan trọng trong kiến trúc Offline-First:
///   - PUSH: đẩy những gì Local thay đổi khi offline lên Cloud.
///   - PULL: kéo những gì thay đổi từ thiết bị khác / web dashboard về Local.
///
/// Về phía Microservices, use case này vẫn tồn tại nhưng
/// `ITransactionRepository.syncAll()` có thể là no-op (vì Microservices
/// không có local DB, mọi thứ đã real-time qua HTTP).
class SyncTransactionsUseCase {
  final ITransactionRepository _repository;

  SyncTransactionsUseCase(this._repository);

  Future<void> execute() async {
    await _repository.syncAll();
  }
}
