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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    AppTranslations.getText(lang, 'edit_transaction'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, ref, tx);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.expenseColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppTheme.expenseColor),
                  ),
                  title: Text(
                    AppTranslations.getText(lang, 'delete_transaction'),
                    style: const TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.w500),
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
                              AppTranslations.getText(lang, 'transaction_deleted'),
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

    // Quy đổi USD -> VND nếu đang dùng tiếng Việt
    double displayAmount = tx.amount;
    if (lang == 'vi') {
      displayAmount = tx.amount * 25000;
    }
    
    final amountController = TextEditingController(
      text: lang == 'vi' ? displayAmount.toStringAsFixed(0) : displayAmount.toStringAsFixed(2)
    );
    final noteController = TextEditingController(text: tx.note ?? '');

    final wallets = ref.read(walletsStreamProvider).value ?? [];
    String? selectedWalletId = tx.walletId;

    // Đảm bảo ví được chọn hợp lệ
    if (wallets.isNotEmpty && (selectedWalletId == null || !wallets.any((w) => w.id == selectedWalletId))) {
      selectedWalletId = wallets.first.id;
    }

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
    
    if (!currentCategories.any((c) => c['name'] == selectedCategory)) {
      selectedCategory = currentCategories.first['name'];
    }

    InputDecoration customInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                AppTranslations.getText(lang, 'edit_transaction'), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
              ),
              
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: customInputDecoration(
                        AppTranslations.getText(lang, 'amount'), 
                        Icons.attach_money_rounded
                      ).copyWith(
                        prefixIcon: null,
                        prefixText: lang == 'en' ? '\$ ' : null,
                        suffixText: lang == 'vi' ? ' đ' : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Chọn ví
                    if (wallets.isNotEmpty)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedWalletId,
                        decoration: customInputDecoration(
                          AppTranslations.getText(lang, 'wallet'),
                          Icons.account_balance_wallet_outlined
                        ).copyWith(prefixIcon: null),
                        dropdownColor: Theme.of(context).cardTheme.color ?? Colors.white,
                        items: wallets.map((w) {
                          return DropdownMenuItem<String>(
                            value: w.id,
                            child: Row(
                              children: [
                                const Icon(Icons.wallet_rounded, color: Colors.blueGrey, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedWalletId = val);
                        },
                      ),
                    if (wallets.isNotEmpty) const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      decoration: customInputDecoration(
                        AppTranslations.getText(lang, 'category'), 
                        Icons.category_rounded
                      ).copyWith(prefixIcon: null),
                      dropdownColor: Theme.of(context).cardTheme.color ?? Colors.white,
                      items: currentCategories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['name'],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c['icon'] as IconData, color: c['color'] as Color, size: 20),
                              const SizedBox(width: 12),
                              Text(AppTranslations.getText(lang, (c['name'] as String).toLowerCase())),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      decoration: customInputDecoration(
                        AppTranslations.getText(lang, 'note'), 
                        Icons.notes_rounded
                      ),
                    ),
                    const SizedBox(height: 8), 
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 20, right: 24, left: 24, top: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  child: Text(
                    AppTranslations.getText(lang, 'cancel'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final rawAmount = double.tryParse(amountController.text);
                    if (rawAmount == null) return;

                    // Quy đổi tiền Việt sang Đô trước khi lưu
                    double amountInUsd = rawAmount;
                    if (lang == 'vi') {
                      amountInUsd = rawAmount / 25000;
                    }

                    final selectedCatConfig = currentCategories.firstWhere((c) => c['name'] == selectedCategory);
                    final color = selectedCatConfig['color'] as Color;
                    final icon = selectedCatConfig['icon'] as IconData;

                    final updatedTx = tx.copyWith(
                      amount: amountInUsd,
                      note: noteController.text,
                      categoryName: selectedCategory,
                      categoryIconCode: icon.codePoint,
                      categoryColorHex: color.toARGB32(),
                      walletId: selectedWalletId, 
                      isSynced: false,
                      updatedAt: DateTime.now(),
                    );

                    try {
                      await ref.read(updateTransactionUseCaseProvider).execute(updatedTx);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppTranslations.getText(lang, 'transaction_updated'))
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${AppTranslations.getText(lang, 'failed_to_update')}: $e')
                          )
                        );
                      }
                    }
                  },
                  child: Text(
                    AppTranslations.getText(lang, 'save'), 
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
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