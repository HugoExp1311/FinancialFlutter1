import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Đã thêm import này
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../providers/app_providers.dart';
import '../utils/transaction_actions.dart';
import '../utils/category_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, ref), // Header giờ sẽ đọc trực tiếp từ DB
            const SizedBox(height: 24),
            const BalanceCard(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(syncTransactionsUseCaseProvider).execute();
                },
                child: _buildTransactionList(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Text('No transactions yet. Add some!', style: TextStyle(color: AppTheme.textSubDark)),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return GestureDetector(
              onLongPress: () => TransactionActions.showOptions(context, ref, tx),
              onTap: () => TransactionActions.showOptions(context, ref, tx),
              child: TransactionItem(
                title: tx.categoryName,
                date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                amount: tx.isExpense ? -tx.amount : tx.amount,
                icon: CategoryUtils.getIcon(tx.categoryName),
                iconColor: CategoryUtils.getColor(tx.categoryName),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  // --- LOGIC 5: CẬP NHẬT HEADER TRANG HOME ---
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;

    String displayName = 'Người dùng';
    String avatarUrl = 'https://i.pravatar.cc/150?img=11';

    // Đọc data từ Provider giống bên màn Profile
    profileAsync.whenData((profile) {
      final firstName = profile?['first_name'] as String? ?? '';
      final lastName = profile?['last_name'] as String? ?? '';
      displayName = '$firstName $lastName'.trim();
      if (displayName.isEmpty) displayName = user?.email?.split('@')[0] ?? 'Người dùng';
      if (profile?['avatar_url'] != null) {
        avatarUrl = profile!['avatar_url'];
      }
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good Morning,', style: TextStyle(fontSize: 14, color: AppTheme.textSubDark)),
              const SizedBox(height: 4),
              Text(
                '$displayName!', // Tên thay đổi linh hoạt
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Sync Data',
              icon: const Icon(Icons.sync_rounded, color: AppTheme.textSubDark),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing with Cloud...'), duration: Duration(seconds: 1)));
                await ref.read(syncTransactionsUseCaseProvider).execute();
              },
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(avatarUrl), // Avatar thay đổi linh hoạt
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ],
    );
  }
}