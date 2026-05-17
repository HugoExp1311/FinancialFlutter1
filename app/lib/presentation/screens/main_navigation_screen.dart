import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'add_transaction_screen.dart';
import 'chatbot_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Sync lần đầu khi vào màn chính
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionRepositoryProvider).syncAll();

      // Lắng nghe realtime từ Supabase (web/thiết bị khác cập nhật -> app tự sync)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Supabase.instance.client
            .from('transactions')
            .stream(primaryKey: ['sync_id'])
            .eq('user_id', user.id)
            .listen((event) {
          ref.read(transactionRepositoryProvider).syncAll();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'chatbot_fab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
              fullscreenDialog: true,
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomAppBar(
          color: Theme.of(context).cardTheme.color,
          surfaceTintColor: Colors.transparent, // fix lỗi ám nền M3
          shadowColor: Colors.black.withValues(alpha: 0.5),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  Icons.home_rounded,
                  0,
                  AppTranslations.getText(lang, 'home'),
                ),
                _buildNavItem(
                  Icons.bar_chart_rounded,
                  1,
                  AppTranslations.getText(lang, 'statistics'),
                ),
                const SizedBox(width: 48),
                _buildNavItem(
                  Icons.account_balance_wallet_rounded,
                  2,
                  AppTranslations.getText(lang, 'wallet'),
                ),
                _buildNavItem(
                  Icons.person_rounded,
                  3,
                  AppTranslations.getText(lang, 'profile'),
                ),
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