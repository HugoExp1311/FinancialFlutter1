import 'package:core_domain/entities/transaction_entity.dart';
import 'package:core_domain/entities/wallet_entity.dart'; // Thêm dòng này

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

  // MỚI: Thêm hàm theo dõi ví vào Interface
  Stream<List<WalletEntity>> watchWallets();

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