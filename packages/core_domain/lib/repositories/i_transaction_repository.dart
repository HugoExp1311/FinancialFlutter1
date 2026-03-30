import 'package:core_domain/entities/transaction_entity.dart';

/// [ITransactionRepository] — Abstract Contract (Hợp đồng trừu tượng).
///
/// Đây là ranh giới giữa Domain Logic và Infrastructure.
/// Có 2 Implementation "cắm vào" (Dependency Inversion):
///   1. `TransactionRepositoryImpl`  → dùng Isar + Supabase (Monolith)
///   2. `TransactionRepositoryHttp`  → gọi REST API (Microservices client)
///
/// ⚠️ Tuyệt đối KHÔNG import Isar, Supabase, http vào file này.
abstract interface class ITransactionRepository {
  // -------------------------------------------------------------------------
  // READ
  // -------------------------------------------------------------------------

  /// Theo dõi danh sách giao dịch real-time (push-based / reactive).
  /// UI lắng nghe stream này để tự động cập nhật khi có thay đổi.
  Stream<List<TransactionEntity>> watchTransactions();

  /// Lấy tất cả giao dịch một lần (pull-based).
  Future<List<TransactionEntity>> getTransactions();

  /// Lấy một giao dịch theo syncId. Trả về null nếu không tìm thấy.
  Future<TransactionEntity?> getTransactionBySyncId(String syncId);

  // -------------------------------------------------------------------------
  // WRITE
  // -------------------------------------------------------------------------

  /// Tạo mới một giao dịch.
  Future<void> addTransaction(TransactionEntity transaction);

  /// Cập nhật giao dịch đã có (xác định bởi syncId / localId).
  Future<void> updateTransaction(TransactionEntity transaction);

  /// Xóa mềm (soft delete) — đánh cờ isDeleted = true thay vì xóa khỏi DB.
  Future<void> deleteTransaction(String syncId);

  // -------------------------------------------------------------------------
  // SYNC (Dành cho Offline-First / Cross-device sync)
  // -------------------------------------------------------------------------

  /// Đồng bộ toàn diện:
  ///   1. Push các record chưa sync lên Cloud.
  ///   2. Pull các record mới/thay đổi từ Cloud về Local.
  Future<void> syncAll();
}
