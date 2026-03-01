import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'add_transaction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sử dụng IndexedStack để giữ State của các màn hình khi chuyển đổi tab
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'chatbot_fab',
              onPressed: () {
                // TODO: Triển khai Chatbot AI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🤖 AI Assistant is coming soon!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              backgroundColor: AppTheme.incomeColor,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 28),
            ),
          ),
        ],
      ),
      // Imports in top section handled automatically by linter if missing, but let's replace the FAB block directly
      // Floating Action Button lơ lửng ở giữa (Dành riêng cho tính năng cốt lõi: Thêm giao dịch)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Push popup màn hình Add Transaction từ mạn dưới lên
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
              fullscreenDialog:
                  true, // Xài dạng Fullscreen Dialog cho nó xịn xò
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // Thanh Navigation tùy chỉnh Bo tròn theo Material 3
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomAppBar(
          color: Theme.of(context).cardTheme.color,
          surfaceTintColor: Colors.transparent, // Sửa lỗi ám nền trắng của M3
          shadowColor: Colors.black.withValues(alpha: 0.5),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(Icons.home_rounded, 0, 'Home'),
                _buildNavItem(Icons.bar_chart_rounded, 1, 'Stats'),
                const SizedBox(width: 48), // Chừa không gian cho nút FAB ở giữa
                _buildNavItem(
                  Icons.account_balance_wallet_rounded,
                  2,
                  'Wallet',
                ),
                _buildNavItem(Icons.person_rounded, 3, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? AppTheme.primaryColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isSelected ? 26 : 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
