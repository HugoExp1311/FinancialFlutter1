import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

// Giả định WalletEntity trong core_domain
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  // Hàm hiển thị Modal thêm ví mới
  void _showAddWalletModal(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Wallet Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
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
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Trong thực tế bà sẽ watch walletsStreamProvider
    // Tạm thời tui giữ logic tính toán của bà nhưng làm nó "sạch" hơn
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
      child: SingleChildScrollView( // Thêm để không bị lỗi tràn màn hình khi list dài
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Wallets',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Ví chính
            _buildCreditCard(
              context,
              color1: const Color(0xFF0F2027),
              color2: const Color(0xFF1F4C74),
              name: 'Main Wallet',
              number: '**** **** **** 1234',
              balance: '\$${(totalNet * 0.7).toStringAsFixed(2)}',
              onTap: () {
                // Điều hướng sang trang chi tiết ví
              },
            ),
            
            const SizedBox(height: 20),
            
            // Ví Tiết kiệm
            _buildCreditCard(
              context,
              color1: const Color(0xFF8E2DE2),
              color2: const Color(0xFF4A00E0),
              name: 'Savings',
              number: '**** **** **** 5678',
              balance: '\$${(totalNet * 0.3).toStringAsFixed(2)}',
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            
            // Nút Thêm ví mới
            InkWell(
              onTap: () => _showAddWalletModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.5),
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
                      Text(
                        'Add New Wallet',
                        style: TextStyle(
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
              color: color2.withOpacity(0.3),
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