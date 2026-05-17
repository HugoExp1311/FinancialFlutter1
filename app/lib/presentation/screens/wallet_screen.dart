import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart'; 
import 'package:isar_community/isar.dart'; 
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../utils/format_utils.dart';
import '../../data/models/app_wallet.dart';
import '../../data/models/app_transaction.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionRepositoryProvider).syncAll();
    });
  }

  // THÊM / SỬA VÍ 
  void _showWalletModal(BuildContext context, String lang, {WalletEntity? existingWallet}) {
    final isEditing = existingWallet != null;
    final nameController = TextEditingController(text: isEditing ? existingWallet.name : '');
    final balanceController = TextEditingController(text: isEditing ? existingWallet.balance.toString() : '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(isEditing ? 'Update Wallet' : 'Create New Wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(isEditing ? 'Modify your wallet details' : 'Add a new source of funds', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14)),
            const SizedBox(height: 32),
            
            TextField(
              controller: nameController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Wallet Name',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                hintText: 'e.g., Cash, Credit Card, Momo...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.label_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Số Dư (Bị khoá nếu đang Edit)
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !isEditing,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                hintText: '0.00',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.attach_money_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                filled: true,
                fillColor: !isEditing ? (isDark ? Colors.grey.shade800 : Colors.grey.shade50) : (isDark ? Colors.grey.shade900 : Colors.grey.shade200),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                ),
                onPressed: () async {
                  final amount = double.tryParse(balanceController.text) ?? -1;
                  
                  if (!isEditing && amount < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư ban đầu phải >= 0! ⚠️')));
                    return;
                  }
                  if (nameController.text.trim().isEmpty) return;

                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;
                    final isar = ref.read(isarProvider);

                    if (isEditing) {
                      await Supabase.instance.client.from('wallets').update({
                        'name': nameController.text.trim(),
                      }).eq('id', existingWallet.id);

                      final appWalletToUpdate = await isar.appWallets.filter().syncIdEqualTo(existingWallet.id).findFirst();
                      if (appWalletToUpdate != null) {
                        appWalletToUpdate.name = nameController.text.trim();
                        appWalletToUpdate.updatedAt = DateTime.now();
                        await isar.writeTxn(() async => await isar.appWallets.put(appWalletToUpdate));
                      }
                    } else {
                      double balanceInUsd = amount;
                      if (lang == 'vi') {
                        balanceInUsd = amount / 25000;
                      }

                      final response = await Supabase.instance.client.from('wallets').insert({
                        'name': nameController.text.trim(),
                        'balance': balanceInUsd,
                        'user_id': user.id,
                        'color_hex': '0xFF4CA1AF', 
                      }).select().single();

                      final newWallet = AppWallet()
                        ..syncId = response['id']
                        ..name = response['name']
                        ..balance = (response['balance'] as num).toDouble()
                        ..colorHex = response['color_hex']
                        ..userId = user.id
                        ..updatedAt = DateTime.now()
                        ..isSynced = true;

                      await isar.writeTxn(() async => await isar.appWallets.put(newWallet));
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Wallet', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CẢNH BÁO XÓA VÀ XÓA CÙNG GIAO DỊCH
  void _showWalletOptions(BuildContext context, WalletEntity wallet, bool isMainWallet, String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor)),
                  title: const Text('Edit Wallet Info', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _showWalletModal(context, lang, existingWallet: wallet);
                  },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isMainWallet ? Colors.grey.withOpacity(0.1) : AppTheme.expenseColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.delete_rounded, color: isMainWallet ? Colors.grey : AppTheme.expenseColor)),
                  title: Text('Delete Wallet', style: TextStyle(color: isMainWallet ? Colors.grey : AppTheme.expenseColor, fontWeight: FontWeight.w500)),
                  subtitle: isMainWallet ? const Text('Ví chính không thể xoá') : null,
                  enabled: !isMainWallet, 
                  onTap: () async {
                    Navigator.pop(context);
                    
                    // POPUP CẢNH BÁO
                    bool confirmDelete = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28), SizedBox(width: 8), Text('Warning')]),
                        content: Text('Xoá ví "${wallet.name}" sẽ xoá luôn tất cả giao dịch thuộc ví này. Bạn có chắc chắn không?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppTranslations.getText(lang, 'cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(ctx, true), 
                            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (!confirmDelete) return;

                    try {
                      await Supabase.instance.client.from('transactions').update({
                        'is_deleted': true,
                        'updated_at': DateTime.now().toUtc().toIso8601String(),
                      }).eq('wallet_id', wallet.id);

                      await Supabase.instance.client.from('wallets').delete().eq('id', wallet.id);
                      
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        // Cập nhật giao dịch thành isDeleted = true ở local
                        final txsToSoftDelete = await isar.appTransactions.filter().walletIdEqualTo(wallet.id).findAll();
                        for (var t in txsToSoftDelete) {
                          t.isDeleted = true;
                          t.updatedAt = DateTime.now();
                          await isar.appTransactions.put(t);
                        }
                        
                        final appWalletToDelete = await isar.appWallets.filter().syncIdEqualTo(wallet.id).findFirst();
                        if (appWalletToDelete != null) {
                          await isar.appWallets.delete(appWalletToDelete.id); 
                        }
                      });
                      
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá ví và các giao dịch liên quan! 🗑️')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xoá: $e')));
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

  // UI
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppTranslations.getText(lang, 'my_wallets'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            
            Expanded(
              child: walletsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
                data: (wallets) {
                  if (wallets.isEmpty) return const Center(child: Text("Chưa có ví nào, vui lòng tạo mới!"));

                  final sortedWallets = wallets.toList()..sort((a, b) {
                    final isDefA = a.isDefault;
                    final isDefB = b.isDefault;
                    
                    if (isDefA && !isDefB) return -1; 
                    if (!isDefA && isDefB) return 1;

                    final dateA = a.createdAt ?? DateTime(0);
                    final dateB = b.createdAt ?? DateTime(0);

                    return dateA.compareTo(dateB);
                  });

                  return RefreshIndicator(
                    onRefresh: () => ref.read(transactionRepositoryProvider).syncAll(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: sortedWallets.length,
                      itemBuilder: (context, index) {
                        final wallet = sortedWallets[index];
                        final walletId = wallet.id;
                        final isMainWallet = wallet.isDefault;

                        // Tính số dư (Balance Khởi tạo + Tổng Thu - Tổng Chi)
                        double txSum = 0;
                        for (var tx in allTransactions) {
                          if (!tx.isDeleted && tx.walletId == walletId) {
                            txSum += tx.isExpense ? -tx.amount : tx.amount;
                          }
                        }
                        final currentBalance = wallet.balance + txSum; 
                        
                        final formattedBalance = FormatUtils.formatCurrency(currentBalance, lang);
                        final String sign = currentBalance < 0 ? '-' : '';

                        final Color color1 = isMainWallet ? const Color(0xFF0F2027) : const Color(0xFF4CA1AF);
                        final Color color2 = isMainWallet ? const Color(0xFF1F4C74) : const Color(0xFF2C3E50);
                        
                        final displayName = isMainWallet 
                            ? AppTranslations.getText(lang, 'main_wallet') 
                            : wallet.name;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildCreditCard(
                            context,
                            lang: lang,
                            color1: color1, color2: color2,
                            name: displayName,
                            number: '**** **** **** ${walletId.length > 4 ? walletId.substring(0, 4) : walletId}',
                            balance: '$sign$formattedBalance',
                            onTap: () => _showWalletOptions(context, wallet, isMainWallet, lang),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Giới hạn 3 ví
            walletsAsync.when(
              data: (wallets) {
                if (wallets.length >= 3) {
                  return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text('Đã đạt giới hạn tối đa 3 ví', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))));
                }
                return InkWell(
                  onTap: () => _showWalletModal(context, lang),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor, size: 28),
                          const SizedBox(width: 12),
                          Text(AppTranslations.getText(lang, 'add_new_wallet'), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, {required String lang, required Color color1, required Color color2, required String name, required String number, required String balance, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [color1, color2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: color2.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const Icon(Icons.more_horiz_rounded, color: Colors.white70, size: 32),
              ],
            ),
            const SizedBox(height: 32),
            Text(number, style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 4, fontFamily: 'monospace')),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.getText(lang, 'total_balance'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(balance, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}