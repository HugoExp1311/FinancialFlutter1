import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_domain/core_domain.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

class TransactionActions {
  /// Hiển thị Menu Edit / Delete chung cho tất cả các màn hình
  static void showOptions(BuildContext context, WidgetRef ref, TransactionEntity tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                title: const Text('Edit Transaction'),
                onTap: () {
                  Navigator.pop(context); // Đóng menu
                  _showEditDialog(context, ref, tx); // Mở dialog sửa
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppTheme.expenseColor),
                title: const Text('Delete Transaction', style: TextStyle(color: AppTheme.expenseColor)),
                onTap: () async {
                  Navigator.pop(context); // Đóng menu
                  // Gọi rễ UseCase để Soft Delete
                  try {
                    await ref.read(deleteTransactionUseCaseProvider).execute(tx.syncId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Hiển thị Hộp thoại Popup nhập số liệu sửa
  static void _showEditDialog(BuildContext context, WidgetRef ref, TransactionEntity tx) {
    final amountController = TextEditingController(text: tx.amount.toString());
    final noteController = TextEditingController(text: tx.note ?? '');

    final List<Map<String, dynamic>> expenseCategories = [
      {'name': 'Food', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
      {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': Colors.blue},
      {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Colors.pink},
      {'name': 'Bills', 'icon': Icons.receipt_long_rounded, 'color': Colors.purple},
    ];

    final List<Map<String, dynamic>> incomeCategories = [
      {'name': 'Salary', 'icon': Icons.work_rounded, 'color': Colors.green},
      {'name': 'Invest', 'icon': Icons.trending_up_rounded, 'color': Colors.teal},
      {'name': 'Rent', 'icon': Icons.real_estate_agent_rounded, 'color': Colors.indigo},
      {'name': 'Other', 'icon': Icons.star_rounded, 'color': Colors.grey},
    ];

    final currentCategories = tx.isExpense ? expenseCategories : incomeCategories;
    String selectedCategory = tx.categoryName;
    
    // Nếu category cũ của tx ko có trong mảng thì lấy thằng đầu tiên làm fallback
    if (!currentCategories.any((c) => c['name'] == selectedCategory)) {
      selectedCategory = currentCategories.first['name'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: Theme.of(context).cardTheme.color,
                items: currentCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['name'],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c['icon'] as IconData, color: c['color'] as Color, size: 20),
                        const SizedBox(width: 12),
                        Text(c['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSubDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newAmount = double.tryParse(amountController.text);
                if (newAmount == null) return;

                final selectedCatConfig = currentCategories.firstWhere((c) => c['name'] == selectedCategory);
                final color = selectedCatConfig['color'] as Color;
                final icon = selectedCatConfig['icon'] as IconData;

                final updatedTx = tx.copyWith(
                  amount: newAmount,
                  note: noteController.text,
                  categoryName: selectedCategory,
                  categoryIconCode: icon.codePoint,
                  // Tương thích API flutter cũ vs mới:
                  categoryColorHex: color.toARGB32(),
                  isSynced: false,
                  updatedAt: DateTime.now(),
                );

                try {
                  await ref.read(updateTransactionUseCaseProvider).execute(updatedTx);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
          },
        );
      },
    );
  }
}
