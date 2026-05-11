import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../providers/app_providers.dart';
import '../utils/transaction_actions.dart';
import '../utils/category_utils.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    // Không bọc Scaffold ở đây nữa vì đã có Scaffold tổng ở màn MainNavigationScreen
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh chứa chữ Hello + Avatar
            _buildAppBar(context, ref),
            const SizedBox(height: 24),
            // Thẻ Hiển thị Số dư
            const BalanceCard(),
            const SizedBox(height: 32),
            // Tiêu đề Lịch sử
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.getText(lang, 'recent_transactions'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    AppTranslations.getText(lang, 'see_all'), // ĐÃ DỊCH CHỮ SEE ALL
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Danh sách giao dịch
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
    final lang = ref.watch(languageProvider); // LẤY NGÔN NGỮ

    return transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Text(
              AppTranslations.getText(lang, 'no_transactions_yet'),
              style: const TextStyle(color: AppTheme.textSubDark),
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            
            // Dịch tên Category hiển thị
            final displayCategoryName = AppTranslations.getText(lang, tx.categoryName.toLowerCase());

            return GestureDetector(
              onLongPress: () => TransactionActions.showOptions(context, ref, tx),
              onTap: () => TransactionActions.showOptions(context, ref, tx),
              child: TransactionItem(
                title: displayCategoryName,
                date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                amount: tx.isExpense ? -tx.amount : tx.amount,
                icon: CategoryUtils.getIcon(tx.categoryName), // Vẫn dùng tên gốc tiếng Anh để lấy icon
                iconColor: CategoryUtils.getColor(tx.categoryName), // Vẫn dùng tên gốc tiếng Anh để lấy màu
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${AppTranslations.getText(lang, 'error')}: $error'),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getText(lang, 'welcome'),
              style: const TextStyle(fontSize: 14, color: AppTheme.textSubDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Alex Johnson!', // tên mẫu
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AppTranslations.getText(lang, 'sync_data'),
              icon: const Icon(Icons.sync_rounded, color: AppTheme.textSubDark),
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
            const SizedBox(width: 4),
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ],
    );
  }
}