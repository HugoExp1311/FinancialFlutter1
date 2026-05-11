import 'package:core_domain/entities/transaction_entity.dart';

/// Interface định nghĩa các hành vi tương tác với dữ liệu Giao dịch.
/// Cho phép linh hoạt chuyển đổi giữa Local DB (Isar) và Remote API (HTTP).
abstract interface class ITransactionRepository {
  // -------------------------------------------------------------------------
  // READ
  // -------------------------------------------------------------------------

  /// lắng nghe thay đổi danh sách giao dịch (Stream).
  Stream<List<TransactionEntity>> watchTransactions();

  /// lấy danh sách toàn bộ giao dịch.
  Future<List<TransactionEntity>> getTransactions();

  /// tìm kiếm giao dịch qua mã định danh syncId.
  Future<TransactionEntity?> getTransactionBySyncId(String syncId);

  // -------------------------------------------------------------------------
  // WRITE
  // -------------------------------------------------------------------------

  ///  thêm giao dịch mới.
  Future<void> addTransaction(TransactionEntity transaction);

  /// cập nhật tt giao dịch
  Future<void> updateTransaction(TransactionEntity transaction);

  /// xóa giao dịch
  Future<void> deleteTransaction(String syncId);

  // -------------------------------------------------------------------------
  // SYNC
  // -------------------------------------------------------------------------

  /// đồng bộ dữ liệu giữa Local và Cloud.
  Future<void> syncAll();
}