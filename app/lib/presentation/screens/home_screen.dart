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
import '../utils/format_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, ref),
            const SizedBox(height: 24),
            const BalanceCard(),
            const SizedBox(height: 32),
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
                    AppTranslations.getText(
                      lang,
                      'see_all',
                    ),
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
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
    final lang = ref.watch(languageProvider);

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

            final displayCategoryName = AppTranslations.getText(
              lang,
              tx.categoryName.toLowerCase(),
            );

            final sign = tx.isExpense ? '-' : '+';
            final formattedAmt = FormatUtils.formatCurrency(tx.amount.abs(), lang);

            return GestureDetector(
              onLongPress: () =>
                  TransactionActions.showOptions(context, ref, tx),
              onTap: () => TransactionActions.showOptions(context, ref, tx),
              child: TransactionItem(
                title: displayCategoryName,
                date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                amountText: '$sign$formattedAmt',
                isExpense: tx.isExpense,
                icon: CategoryUtils.getIcon(
                  tx.categoryName,
                ),
                iconColor: CategoryUtils.getColor(
                  tx.categoryName,
                ),
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
              'vvinh!',
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
                    content: Text(
                      AppTranslations.getText(lang, 'syncing_with_cloud'),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
                await ref.read(syncTransactionsUseCaseProvider).execute();
              },
            ),
            const SizedBox(width: 4),
            const CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://thf.bing.com/th/id/OIP.NifcFumqU3GDz-nL_NKS-AHaE-?o=7&cb=thfc1rm=3&rs=1&pid=ImgDetMain&o=7&rm=3'),
              backgroundColor: Colors.transparent,
            ),
          ],
        ),
      ],
    );
  }
}