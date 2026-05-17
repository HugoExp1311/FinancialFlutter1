import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../utils/format_utils.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    final lang = ref.watch(languageProvider); // Ngôn ngữ (Từ nhánh bạn)
    final isHideBalance = ref.watch(hideBalanceProvider); // Tính năng ẩn số dư (Từ nhánh Thu)

    double income = 0;
    double expense = 0;

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      for (var tx in txAsyncValue.value!) {
        if (!tx.isDeleted) {
          if (tx.isExpense) {
            expense += tx.amount;
          } else {
            income += tx.amount;
          }
        }
      }
    }

    double total = income - expense;
    
    // HỢP NHẤT LOGIC: Nếu đang ẩn thì hiện '••••••', nếu không thì dùng FormatUtils của bạn
    final String displayTotal = isHideBalance ? '••••••' : FormatUtils.formatCurrency(total, lang);
    final String displayIncome = isHideBalance ? '••••••' : FormatUtils.formatCurrency(income, lang);
    final String displayExpense = isHideBalance ? '••••••' : FormatUtils.formatCurrency(expense, lang);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32), // UI bo góc xịn của Thu
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E), // Midnight
            Color(0xFF4338CA), // Royal Indigo
            Color(0xFF6366F1), // Modern Violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Các vòng tròn trang trí background của Thu
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          // Nội dung chính
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getText(lang, 'total_balance'), // Áp dụng Đa ngôn ngữ
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayTotal,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    // Biểu tượng thẻ hoặc logo app mini
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
                // Income & Expense Row 
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        context,
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFF34D399), // Emerald Green
                        title: AppTranslations.getText(lang, 'income'), // Áp dụng Đa ngôn ngữ
                        amount: displayIncome,
                      ),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildInfoItem(
                        context,
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFFF87171), // Soft Red
                        title: AppTranslations.getText(lang, 'expense'), // Áp dụng Đa ngôn ngữ
                        amount: displayExpense,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, {required IconData icon, required Color color, required String title, required String amount}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}