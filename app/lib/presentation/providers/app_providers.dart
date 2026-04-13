import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/repositories/transaction_repository_impl.dart';
import '../../data/models/app_wallet.dart';

// =============================================================================
// INFRASTRUCTURE PROVIDERS (Monolith — Isar + Supabase)
// =============================================================================

/// Provider cho Isar Database — được override với giá trị thực tại main.dart.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

/// Provider cho Supabase Client.
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// =============================================================================
// DOMAIN PROVIDERS (Typed bằng Interface — không phụ thuộc Infrastructure cụ thể)
// =============================================================================

/// Provider trung tâm: trả về Interface [ITransactionRepository].
///
/// UI và Use Cases CHỈ biết Interface này, không biết Impl cụ thể.
/// Khi chuyển sang Microservices, chỉ cần swap dòng này:
///   TransactionRepositoryImpl → TransactionRepositoryHttp
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = ref.watch(supabaseProvider);
  return TransactionRepositoryImpl(isar, supabase);
});

// =============================================================================
// USE CASE PROVIDERS
// =============================================================================

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  return AddTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final syncTransactionsUseCaseProvider = Provider<SyncTransactionsUseCase>((ref) {
  return SyncTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

// =============================================================================
// STREAM / COMPUTED PROVIDERS (UI-facing)
// =============================================================================

/// Lắng nghe danh sách giao dịch Realtime → trả ra [TransactionEntity] list.
final transactionsStreamProvider =
    StreamProvider<List<TransactionEntity>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions();
});

/// Tính tổng chi tiêu từ stream hiện tại.
final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsStreamProvider).value ?? [];
  return txs
      .where((t) => t.isExpense && !t.isDeleted)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});

/// Tính tổng thu nhập từ stream hiện tại.
final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsStreamProvider).value ?? [];
  return txs
      .where((t) => !t.isExpense && !t.isDeleted)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});

// Provider để theo dõi danh sách ví từ Isar theo thời gian thực
final walletsStreamProvider = StreamProvider<List<WalletEntity>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchWallets(); 
});


