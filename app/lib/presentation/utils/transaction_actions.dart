import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_domain/core_domain.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class TransactionActions {
  /// Hiển thị Menu Edit / Delete chung cho tất cả các màn hình
  static void showOptions(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    final lang = ref.read(languageProvider);

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
                leading: const Icon(
                  Icons.edit_rounded,
                  color: AppTheme.primaryColor,
                ),
                title: Text(AppTranslations.getText(lang, 'edit_transaction')),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref, tx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppTheme.expenseColor,
                ),
                title: Text(
                  AppTranslations.getText(lang, 'delete_transaction'),
                  style: const TextStyle(color: AppTheme.expenseColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(deleteTransactionUseCaseProvider)
                        .execute(tx.syncId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppTranslations.getText(
                              lang,
                              'transaction_deleted',
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppTranslations.getText(lang, 'failed_to_delete')}: $e',
                          ),
                        ),
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
  static void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    final lang = ref.read(languageProvider);

    double displayAmount = tx.amount;
    if (lang == 'vi') {
      displayAmount = tx.amount * 25000;
    }
    
    final amountController = TextEditingController(
      text: lang == 'vi' ? displayAmount.toStringAsFixed(0) : displayAmount.toStringAsFixed(2)
    );
    final noteController = TextEditingController(text: tx.note ?? '');

    final List<Map<String, dynamic>> expenseCategories = [
      {'name': 'Food', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
      {
        'name': 'Transport',
        'icon': Icons.directions_car_rounded,
        'color': Colors.blue,
      },
      {
        'name': 'Shopping',
        'icon': Icons.shopping_bag_rounded,
        'color': Colors.pink,
      },
      {
        'name': 'Bills',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.purple,
      },
    ];

    final List<Map<String, dynamic>> incomeCategories = [
      {'name': 'Salary', 'icon': Icons.work_rounded, 'color': Colors.green},
      {
        'name': 'Invest',
        'icon': Icons.trending_up_rounded,
        'color': Colors.teal,
      },
      {
        'name': 'Rent',
        'icon': Icons.real_estate_agent_rounded,
        'color': Colors.indigo,
      },
      {'name': 'Other', 'icon': Icons.star_rounded, 'color': Colors.grey},
    ];

    final currentCategories = tx.isExpense
        ? expenseCategories
        : incomeCategories;
    String selectedCategory = tx.categoryName;

    if (!currentCategories.any((c) => c['name'] == selectedCategory)) {
      selectedCategory = currentCategories.first['name'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                AppTranslations.getText(lang, 'edit_transaction'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppTranslations.getText(lang, 'amount'),
                      prefixText: lang == 'en' ? '\$ ' : null,
                      suffixText: lang == 'vi' ? ' đ' : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue:
                        selectedCategory,
                    decoration: InputDecoration(
                      labelText: AppTranslations.getText(lang, 'category'),
                      prefixIcon: const Icon(Icons.category_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    dropdownColor: Theme.of(context).cardTheme.color,
                    items: currentCategories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['name'],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c['icon'] as IconData,
                              color: c['color'] as Color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppTranslations.getText(
                                lang,
                                (c['name'] as String).toLowerCase(),
                              ),
                            ),
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
                      labelText: AppTranslations.getText(lang, 'note'),
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppTranslations.getText(lang, 'cancel'),
                    style: const TextStyle(color: AppTheme.textSubDark),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final rawAmount = double.tryParse(amountController.text);
                    if (rawAmount == null) return;

                    double amountInUsd = rawAmount;
                    if (lang == 'vi') {
                      amountInUsd = rawAmount / 25000;
                    }

                    final selectedCatConfig = currentCategories.firstWhere(
                      (c) => c['name'] == selectedCategory,
                    );
                    final color = selectedCatConfig['color'] as Color;
                    final icon = selectedCatConfig['icon'] as IconData;

                    final updatedTx = tx.copyWith(
                      amount: amountInUsd,
                      note: noteController.text,
                      categoryName:
                          selectedCategory,
                      categoryIconCode: icon.codePoint,
                      categoryColorHex: color.toARGB32(),
                      isSynced: false,
                      updatedAt: DateTime.now(),
                    );

                    try {
                      await ref
                          .read(updateTransactionUseCaseProvider)
                          .execute(updatedTx);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppTranslations.getText(
                                lang,
                                'transaction_updated',
                              ),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppTranslations.getText(lang, 'failed_to_update')}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    AppTranslations.getText(lang, 'save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}