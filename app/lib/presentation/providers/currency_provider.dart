import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Currency Notifier - Quản lý đơn vị tiền tệ (USD/VND)
class CurrencyNotifier extends Notifier<String> {
  static const String _key = 'app_currency';

  @override
  String build() {
    _loadCurrency();
    return 'USD'; // Mặc định là USD
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_key) ?? 'USD';
    state = savedCurrency;
  }

  Future<void> setCurrency(String currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, currency);
  }

  /// Format số tiền theo đơn vị hiện tại
  String formatAmount(double amount) {
    if (state == 'VND') {
      // Chuyển đổi USD sang VND (tỷ giá mẫu: 1 USD = 24,000 VND)
      final vndAmount = amount * 24000;
      return '${vndAmount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} ₫';
    } else {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Lấy ký hiệu tiền tệ
  String getCurrencySymbol() {
    return state == 'VND' ? '₫' : '\$';
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});
