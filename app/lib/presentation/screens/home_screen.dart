import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildAppBar(context, ref),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(child: BalanceCard()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            _buildTransactionList(ref),
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
          return const SliverFillRemaining(
            child: Center(
              child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onLongPress: () => TransactionActions.showOptions(context, ref, tx),
                    onTap: () => TransactionActions.showOptions(context, ref, tx),
                    borderRadius: BorderRadius.circular(20),
                    child: TransactionItem(
                      title: tx.categoryName,
                      date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                      amount: tx.isExpense ? -tx.amount : tx.amount,
                      icon: CategoryUtils.getIcon(tx.categoryName),
                      iconColor: CategoryUtils.getColor(tx.categoryName),
                    ),
                  ),
                );
              },
              childCount: transactions.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;

    String displayName = profileAsync.maybeWhen(
      data: (profile) {
        final name = '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
        return name.isNotEmpty ? name : (user?.email?.split('@')[0] ?? 'User');
      },
      orElse: () => 'Loading...',
    );

    String? avatarUrl = profileAsync.maybeWhen(
      data: (profile) => profile?['avatar_url'],
      orElse: () => null,
    );

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : const NetworkImage('https://i.pravatar.cc/150?img=11'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(
                displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.sync_rounded),
          onPressed: () async {
            await ref.read(syncTransactionsUseCaseProvider).execute();
          },
        ),
      ],
    );
  }
}