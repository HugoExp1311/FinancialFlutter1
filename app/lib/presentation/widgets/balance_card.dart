import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsyncValue = ref.watch(transactionsStreamProvider);

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027), // Đen huyền
            Color(0xFF143048), // Xanh xám biển
            Color(0xFF1F4C74), // Xanh đại dương (gradient mượt)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          // Split Income and Expense
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseBlock(
                context,
                icon: Icons.arrow_downward,
                color: AppTheme.incomeColor,
                title: 'Income',
                amount: '\$${income.toStringAsFixed(2)}',
              ),
              _buildIncomeExpenseBlock(
                context,
                icon: Icons.arrow_upward,
                color: AppTheme.expenseColor,
                title: 'Expenses',
                amount: '\$${expense.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBlock(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.2,
            ), // Nhấn màu nền hơi mờ để nổi bật icon
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
