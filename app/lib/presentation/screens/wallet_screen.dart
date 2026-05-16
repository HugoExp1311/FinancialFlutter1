import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../../data/models/app_wallet.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _showAddWalletModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Wallet Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.incomeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;

                    // 1. Insert vào Supabase VÀ DÙNG .select().single() để lấy lại data
                    final response = await Supabase.instance.client.from('wallets').insert({
                      'name': nameController.text.trim(),
                      'balance': double.tryParse(balanceController.text) ?? 0.0,
                      'user_id': user.id,
                      'color_hex': '0xFF1F4C74',
                    }).select().single();

                    // 2. Lưu trực tiếp xuống Isar để UI cập nhật NGAY
                    final newWallet = AppWallet()
                      ..syncId = response['id']
                      ..name = response['name']
                      ..balance = (response['balance'] as num).toDouble()
                      ..colorHex = response['color_hex']
                      ..userId = user.id
                      ..updatedAt = DateTime.now()
                      ..isSynced = true;

                    final isar = ref.read(isarProvider);
                    await isar.writeTxn(() async {
                      await isar.appWallets.put(newWallet);
                    });

                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    debugPrint('Lỗi tạo ví: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  }
                },
                child: const Text(
                  'Create Wallet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];

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

            Expanded(
              child: walletsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return Center(
                      child: Text(
                        AppTranslations.getText(lang, 'no_wallets_yet'),
                        style: const TextStyle(color: AppTheme.textSubDark),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(transactionRepositoryProvider).syncAll(),
                    child: ListView.builder(
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final colorInt = int.tryParse(wallet.colorHex ?? '') ?? 0xFF1F4C74;
                        final walletId = wallet.id;

                        // Tính toán số dư dựa trên balance gốc + giao dịch
                        double txSum = 0;
                        for (var tx in allTransactions) {
                          if (!tx.isDeleted && tx.walletId == walletId) {
                            txSum += tx.isExpense ? -tx.amount : tx.amount;
                          }
                        }

                        final currentBalance = wallet.balance + txSum;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildCreditCard(
                            context,
                            lang: lang,
                            color1: Color(colorInt).withAlpha(204),
                            color2: Color(colorInt),
                            name: wallet.name,
                            number: '**** **** **** ${walletId.length > 4 ? walletId.substring(0, 4) : walletId}',
                            balance: '\$${currentBalance.toStringAsFixed(2)}',
                            onTap: () {},
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            InkWell(
              onTap: () => _showAddWalletModal(context, ref),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

// ============================================================================
// COMMENT: Code cũ sử dụng walletType (70/30 split) - KHÔNG XÓA
// ============================================================================
/*
  // Code cũ tính toán dựa trên walletType:
  double mainWalletTotal = 0;
  double savingsTotal = 0;

  if (txAsyncValue.hasValue && txAsyncValue.value != null) {
    for (var tx in txAsyncValue.value!) {
      if (!tx.isDeleted) {
        final amount = tx.isExpense ? -tx.amount : tx.amount;
        
        // Phân loại theo walletType thực tế từ database
        if (tx.walletType == 'savings') {
          savingsTotal += amount;
        } else {
          // Mặc định là 'main' nếu không có hoặc là 'main'
          mainWalletTotal += amount;
        }
      }
    }
  }

  final mainWalletBalance = mainWalletTotal.toStringAsFixed(2);
  final savingsBalance = savingsTotal.toStringAsFixed(2);
*/