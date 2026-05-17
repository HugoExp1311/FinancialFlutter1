import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart';
import 'package:app/data/repositories/transaction_repository_impl.dart';
import '../../data/models/app_wallet.dart';

// --- INFRASTRUCTURE ---

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// --- REPOSITORY ---

// Note: Đổi return sang TransactionRepositoryHttp nếu chuyển qua chạy Microservices
final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = ref.watch(supabaseProvider);
  return TransactionRepositoryImpl(isar, supabase);
});

// --- USE CASES ---

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

// --- STREAM & COMPUTED LOGIC ---

final transactionsStreamProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions();
});

final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsStreamProvider).value ?? [];
  return txs
      .where((t) => t.isExpense && !t.isDeleted)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});

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


// fetch dữ liệu từ bảng user_profile
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final response = await Supabase.instance.client
      .from('user_profile')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  
  return response;
});

// =============================================================================
// GLOBAL SETTINGS PROVIDERS
// =============================================================================

/// Trạng thái ẩn/hiện số dư ở màn hình Home
final hideBalanceProvider = StateProvider<bool>((ref) => false);

/// Trạng thái đơn vị tiền tệ (Mặc định là $)
final currencyProvider = StateProvider<String>((ref) => '\$');
