import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../../data/models/app_wallet.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  
  @override
  void initState() {
    super.initState();
    // 1. GỌI SYNC NGAY KHI MỞ MÀN HÌNH ĐỂ KÉO SỐ DƯ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionRepositoryProvider).syncAll();
    });
  }

  void _showAddWalletModal(BuildContext context) {
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
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add New Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
              keyboardType: TextInputType.number,
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
                  final user = Supabase.instance.client.auth.currentUser;
                  await Supabase.instance.client.from('wallets').insert({
                    'name': nameController.text,
                    'balance': double.tryParse(balanceController.text) ?? 0.0,
                    'user_id': user?.id,
                    'color_hex': '0xFF1F4C74', 
                  });
                  // Gọi sync lại sau khi thêm mới
                  ref.read(transactionRepositoryProvider).syncAll();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Create Wallet', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
            const Text(
              'My Wallets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: walletsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Lỗi rồi ní: $err')),
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return const Center(child: Text("Ní chưa có ví nào hết, tạo đi!"));
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(transactionRepositoryProvider).syncAll(),
                    child: ListView.builder(
                      itemCount: wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final colorInt = int.tryParse(wallet.colorHex ?? '0xFF1F4C74') ?? 0xFF1F4C74;
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
                            color1: Color(colorInt).withAlpha(204), // alpha 0.8
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
              onTap: () => _showAddWalletModal(context), // Sửa lại để hiện modal
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(128),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text('Add New Wallet', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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
    required Color color1, required Color color2,
    required String name, required String number,
    required String balance, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(colors: [color1, color2]),
          boxShadow: [
            BoxShadow(color: color2.withAlpha(77), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.wifi_rounded, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 32),
            Text(number, style: const TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 3)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(balance, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.credit_score_rounded, color: Colors.white70, size: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}