import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Từ nhánh Thu: Thêm để fetch ví
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart'; // Từ nhánh Bạn
import '../utils/app_translations.dart'; // Từ nhánh Bạn

// Model đơn giản để hứng dữ liệu ví
class Wallet {
  final String id;
  final String name;
  Wallet({required this.id, required this.name});
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  String? _selectedWalletId; // Biến lưu Ví được chọn
  List<Wallet> _wallets = []; // Danh sách ví từ Database
  bool _isLoadingWallets = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchWallets(); // Lấy danh sách ví khi mở màn hình
  }

  // Hàm lấy danh sách ví từ Supabase (Của Thu)
  Future<void> _fetchWallets() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('wallets')
          .select('id, name')
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _wallets = (data as List).map((e) => Wallet(id: e['id'], name: e['name'])).toList();
          if (_wallets.isNotEmpty) {
            _selectedWalletId = _wallets.first.id; // Mặc định chọn ví đầu tiên
          }
          _isLoadingWallets = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWallets = false);
    }
  }

  Future<void> _presentDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Food', 'icon': Icons.fastfood_rounded, 'color': Colors.orange},
    {'name': 'Transport', 'icon': Icons.directions_car_rounded, 'color': Colors.blue},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Colors.pink},
    {'name': 'Bills', 'icon': Icons.receipt_long_rounded, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Salary', 'icon': Icons.work_rounded, 'color': Colors.green},
    {'name': 'Invest', 'icon': Icons.trending_up_rounded, 'color': Colors.teal},
    {'name': 'Rent', 'icon': Icons.real_estate_agent_rounded, 'color': Colors.indigo},
    {'name': 'Other', 'icon': Icons.star_rounded, 'color': Colors.grey},
  ];

  List<Map<String, dynamic>> get _currentCategories =>
      _isExpense ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider); // Ngôn ngữ từ nhánh Bạn

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText(lang, 'new_transaction'), // Đa ngôn ngữ
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeToggle(lang), // Truyền ngôn ngữ vào Toggle
                    const SizedBox(height: 32),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            AppTranslations.getText(lang, 'enter_amount'),
                            style: const TextStyle(
                              color: AppTheme.textSubDark,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IntrinsicWidth(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 48, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).colorScheme.onSurface
                              ),
                              decoration: InputDecoration(
                                // LOGIC TIỀN TỆ TỪ NHÁNH CỦA BẠN
                                prefixText: lang == 'en' ? '\$ ' : null,
                                prefixStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                suffixText: lang == 'vi' ? ' đ' : null,
                                suffixStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                border: InputBorder.none,
                                hintText: lang == 'vi' ? '0' : '0.00',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // WALLET SELECTION (CỦA THU)
                    Text(
                      AppTranslations.getText(lang, 'wallet'), // Đa ngôn ngữ cho chữ Wallet
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 12),
                    _isLoadingWallets 
                      ? const LinearProgressIndicator() 
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedWalletId,
                              isExpanded: true,
                              hint: const Text("Choose a wallet"),
                              items: _wallets.map((wallet) {
                                return DropdownMenuItem(
                                  value: wallet.id,
                                  child: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedWalletId = val),
                            ),
                          ),
                        ),
                    const SizedBox(height: 32),

                    Text(
                      AppTranslations.getText(lang, 'category'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _currentCategories.length,
                        itemBuilder: (context, index) {
                          final category = _currentCategories[index];
                          final isSelected = _selectedCategory == category['name'];
                          return _buildCategoryItem(
                            lang, // Truyền ngôn ngữ vào
                            category['name'],
                            category['icon'],
                            category['color'],
                            isSelected,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      AppTranslations.getText(lang, 'date'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionTile( // Helper của Thu
                      icon: Icons.calendar_today_rounded,
                      text: "${_selectedDate.day.toString().padLeft(2, '0')} / ${_selectedDate.month.toString().padLeft(2, '0')} / ${_selectedDate.year}",
                      onTap: _presentDatePicker,
                      trailing: Icons.edit_calendar_rounded,
                    ),
                    const SizedBox(height: 32),

                    Text(
                      AppTranslations.getText(lang, 'note'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: AppTranslations.getText(lang, 'what_was_this_for'),
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _saveTransaction(lang), // Gọi hàm save kèm ngôn ngữ
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Text(
                    AppTranslations.getText(lang, 'save_transaction'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM SAVE GỘP LOGIC CỦA BẠN VÀ THU
  Future<void> _saveTransaction(String lang) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.getText(lang, 'please_enter_amount'))));
      return;
    }
    // Check ví của Thu
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
      return;
    }

    final amountInputRaw = double.tryParse(_amountController.text) ?? 0.0;
    if (amountInputRaw <= 0) return;

    // QUY ĐỔI TIỀN TỆ CỦA BẠN
    double amountInUsd = amountInputRaw;
    if (lang == 'vi') {
      amountInUsd = amountInputRaw / 25000;
    }

    final selectedCat = _currentCategories.firstWhere((c) => c['name'] == _selectedCategory);
    final color = selectedCat['color'] as Color;
    final icon = selectedCat['icon'] as IconData;

    // Đẩy đủ bộ tham số vào backend
    await ref.read(addTransactionUseCaseProvider).execute(
      amount: amountInUsd,
      isExpense: _isExpense,
      date: _selectedDate,
      note: _noteController.text,
      categoryName: _selectedCategory,
      categoryIconCode: icon.codePoint,
      categoryColorHex: color.toARGB32(),
      walletId: _selectedWalletId, 
    );

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.getText(lang, 'transaction_saved'))));
  }

  // --- WIDGET HELPER ---
  Widget _buildActionTile({required IconData icon, required String text, required VoidCallback onTap, required IconData trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            Icon(trailing, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String lang) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _buildToggleItem(AppTranslations.getText(lang, 'expense'), _isExpense, AppTheme.expenseColor, () => setState(() {
            _isExpense = true;
            if (!_expenseCategories.any((c) => c['name'] == _selectedCategory)) {
              _selectedCategory = _expenseCategories.first['name'];
            }
          })),
          _buildToggleItem(AppTranslations.getText(lang, 'income'), !_isExpense, AppTheme.incomeColor, () => setState(() {
            _isExpense = false;
            if (!_incomeCategories.any((c) => c['name'] == _selectedCategory)) {
              _selectedCategory = _incomeCategories.first['name'];
            }
          })),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isActive, Color activeColor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String lang, String name, IconData icon, Color color, bool isSelected) {
    final displayName = AppTranslations.getText(lang, name.toLowerCase());

    return GestureDetector(
      onTap: () => setState(
        () => _selectedCategory = name,
      ),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).cardTheme.color,
          border: Border.all(color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              displayName, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}