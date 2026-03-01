import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/data/models/app_transaction.dart';
import 'package:app/data/repositories/transaction_repository.dart';

/// Provider cho Isar Database phụ thuộc vào việc được gài giá trị thực (override) ở main.dart
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

/// Provider cho Supabase Client (Lấy trực tiếp từ thư viện sau khi đã initialize ở main.dart)
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider trung tâm cho mọi thao tác C-R-U-D Logic
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = ref.watch(supabaseProvider);
  return TransactionRepository(isar, supabase);
});

/// StreamProvider: Lắng nghe danh sách giao dịch Realtime từ Isar, trả ra Danh sách Tự động Cập nhật UI
final transactionsStreamProvider = StreamProvider<List<AppTransaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.watchTransactions();
});

/// FutureProvider: Hàm tính Tổng Chi Tiêu, tự động chớp lấy sự thay đổi của Stream trên
final totalExpenseProvider = FutureProvider<double>((ref) async {
  // .value giúp lấy ra dữ liệu đang có của Stream ở thì hiện tại
  final txs = ref.watch(transactionsStreamProvider).value ?? [];
  return txs
      .where((t) => t.isExpense && !t.isDeleted)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});
