import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_domain/core_domain.dart'; 
import 'package:isar_community/isar.dart'; 
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
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

  // =========================================================================
  // 1. THÊM / SỬA VÍ 
  // =========================================================================
  void _showWalletModal(BuildContext context, {WalletEntity? existingWallet}) {
    final isEditing = existingWallet != null;
    final nameController = TextEditingController(text: isEditing ? existingWallet.name : '');
    final balanceController = TextEditingController(text: isEditing ? existingWallet.balance.toString() : '');

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
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(isEditing ? 'Update Wallet' : 'Create New Wallet', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(isEditing ? 'Modify your wallet details' : 'Add a new source of funds', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 32),
            
            // Input Tên Ví
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Wallet Name',
                hintText: 'e.g., Cash, Credit Card, Momo...',
                prefixIcon: const Icon(Icons.label_outline_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Số Dư (Bị khoá nếu đang Edit)
            TextField(
              controller: balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !isEditing, 
              decoration: InputDecoration(
                labelText: 'Initial Balance',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.grey),
                filled: true,
                fillColor: !isEditing ? Colors.grey.shade50 : Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200)),
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
                      final response = await Supabase.instance.client.from('wallets').insert({
                        'name': nameController.text.trim(),
                        'balance': amount,
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

  // =========================================================================
  // 2. CẢNH BÁO XÓA & XÓA CÙNG GIAO DỊCH (CASCADE SOFT DELETE)
  // =========================================================================
  void _showWalletOptions(BuildContext context, WalletEntity wallet, bool isMainWallet) {
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
                    _showWalletModal(context, existingWallet: wallet);
                  },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isMainWallet ? Colors.grey.withOpacity(0.1) : AppTheme.expenseColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.delete_rounded, color: isMainWallet ? Colors.grey : AppTheme.expenseColor)),
                  title: Text('Delete Wallet', style: TextStyle(color: isMainWallet ? Colors.grey : AppTheme.expenseColor, fontWeight: FontWeight.w500)),
                  subtitle: isMainWallet ? const Text('Ví chính không thể xoá') : null,
                  enabled: !isMainWallet, 
                  onTap: () async {
                    Navigator.pop(context); // Đóng menu Option
                    
                    // --- HIỂN THỊ POPUP CẢNH BÁO ---
                    bool confirmDelete = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28), SizedBox(width: 8), Text('Warning')]),
                        content: Text('Xoá ví "${wallet.name}" sẽ xoá luôn tất cả giao dịch thuộc ví này. Bạn có chắc chắn không?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(ctx, true), 
                            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (!confirmDelete) return; // Nếu user bấm Cancel thì dừng

                    // --- TIẾN HÀNH XOÁ ---
                    try {
                      // 1. Soft Delete toàn bộ Transactions thuộc ví này trên Supabase
                      await Supabase.instance.client.from('transactions').update({
                        'is_deleted': true,
                        'updated_at': DateTime.now().toIso8601String(),
                      }).eq('wallet_id', wallet.id);

                      // 2. Hard Delete Ví trên Supabase
                      await Supabase.instance.client.from('wallets').delete().eq('id', wallet.id);
                      
                      // 3. Cập nhật xoá trên Isar Local
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        // Cập nhật giao dịch thành isDeleted = true ở local
                        final txsToSoftDelete = await isar.appTransactions.filter().walletIdEqualTo(wallet.id).findAll();
                        for (var t in txsToSoftDelete) {
                          t.isDeleted = true;
                          t.updatedAt = DateTime.now();
                          await isar.appTransactions.put(t);
                        }
                        
                        // Xoá ví ở local
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

  // =========================================================================
  // 3. UI
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Wallets', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            
            Expanded(
              child: walletsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi tải dữ liệu: $err')),
                data: (wallets) {
                  if (wallets.isEmpty) return const Center(child: Text("Chưa có ví nào, vui lòng tạo mới!"));

                  return RefreshIndicator(
                    onRefresh: () => ref.read(transactionRepositoryProvider).syncAll(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final walletId = wallet.id;
                        final isMainWallet = index == 0; 

                        // Tính số dư (Balance Khởi tạo + Tổng Thu - Tổng Chi)
                        double txSum = 0;
                        for (var tx in allTransactions) {
                          if (!tx.isDeleted && tx.walletId == walletId) {
                            txSum += tx.isExpense ? -tx.amount : tx.amount;
                          }
                        }
                        final currentBalance = wallet.balance + txSum; 
                        
                        final Color color1 = isMainWallet ? const Color(0xFF0F2027) : const Color(0xFF4CA1AF);
                        final Color color2 = isMainWallet ? const Color(0xFF1F4C74) : const Color(0xFF2C3E50);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _buildCreditCard(
                            context,
                            color1: color1, color2: color2,
                            name: wallet.name + (isMainWallet ? ' (Default)' : ''),
                            number: '**** **** **** ${walletId.length > 4 ? walletId.substring(0, 4) : walletId}',
                            balance: '\$${currentBalance.toStringAsFixed(2)}', 
                            onTap: () => _showWalletOptions(context, wallet, isMainWallet),
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
                  onTap: () => _showWalletModal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor, size: 28),
                          SizedBox(width: 12),
                          Text('Add New Wallet', style: TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildCreditCard(BuildContext context, {required Color color1, required Color color2, required String name, required String number, required String balance, required VoidCallback onTap}) {
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
                    const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
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