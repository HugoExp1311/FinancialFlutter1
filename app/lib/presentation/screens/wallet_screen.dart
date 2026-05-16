import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../utils/format_utils.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    double totalNet = 0;

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      for (var tx in txAsyncValue.value!) {
        if (!tx.isDeleted) {
          totalNet += tx.isExpense ? -tx.amount : tx.amount;
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getText(lang, 'my_wallets'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildCreditCard(
              context,
              lang: lang,
              color1: const Color(0xFF0F2027),
              color2: const Color(0xFF1F4C74),
              name: AppTranslations.getText(lang, 'main_wallet'),
              number: '**** **** **** 1234',
              balance: FormatUtils.formatCurrency(totalNet, lang),
            ),
            const SizedBox(height: 20),
            _buildCreditCard(
              context,
              lang: lang,
              color1: const Color(0xFF8E2DE2),
              color2: const Color(0xFF4A00E0),
              name: AppTranslations.getText(lang, 'savings'),
              number: '**** **** **** 5678',
              balance: FormatUtils.formatCurrency(0, lang),
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppTranslations.getText(lang, 'add_new_wallet'),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(
    BuildContext context, {
    required String lang,
    required Color color1,
    required Color color2,
    required String name,
    required String number,
    required String balance,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color2.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.wifi_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.getText(lang, 'total_balance'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    balance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.credit_score_rounded,
                color: Colors.white70,
                size: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }
}