import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../providers/app_providers.dart';
import '../utils/transaction_actions.dart';
import '../utils/category_utils.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../utils/format_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider); // Ngôn ngữ từ nhánh bạn

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        // Giữ cấu trúc Slivers cuộn mượt của Thu
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildAppBar(context, ref, lang), // Truyền ngôn ngữ vào AppBar
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
                    Text(
                      AppTranslations.getText(lang, 'recent_transactions'), // Đa ngôn ngữ
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        AppTranslations.getText(lang, 'see_all'), // Đa ngôn ngữ
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildTransactionList(ref, lang), // Truyền ngôn ngữ vào List
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref, String lang) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                AppTranslations.getText(lang, 'no_transactions_yet'), // Đa ngôn ngữ
                style: const TextStyle(color: Colors.grey)
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tx = transactions[index];
                
                // LOGIC ĐA NGÔN NGỮ VÀ TIỀN TỆ CỦA BẠN
                final displayCategoryName = AppTranslations.getText(
                  lang,
                  tx.categoryName.toLowerCase(),
                );
                final sign = tx.isExpense ? '-' : '+';
                final formattedAmt = FormatUtils.formatCurrency(tx.amount.abs(), lang);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onLongPress: () => TransactionActions.showOptions(context, ref, tx),
                    onTap: () => TransactionActions.showOptions(context, ref, tx),
                    borderRadius: BorderRadius.circular(20),
                    child: TransactionItem(
                      title: displayCategoryName,
                      date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                      amountText: '$sign$formattedAmt', // Dùng chuỗi tiền tệ đã format
                      isExpense: tx.isExpense,
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
      error: (error, stack) => SliverFillRemaining(
        child: Center(child: Text('${AppTranslations.getText(lang, 'error')}: $error'))
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, String lang) {
    // Logic kéo Avatar và Tên từ Supabase của Thu
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
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
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
              Text(
                AppTranslations.getText(lang, 'welcome'), // Chữ "Chào mừng trở lại" đa ngôn ngữ
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)
              ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppTranslations.getText(lang, 'syncing_with_cloud')),
                duration: const Duration(seconds: 1),
              ),
            );
            await ref.read(syncTransactionsUseCaseProvider).execute();
          },
        ),
      ],
    );
  }
}