import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool _isExpense = true;
  String _selectedCategory = 'Food';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
              surface: Theme.of(context).cardTheme.color!,
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
    {
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': Colors.pink,
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Salary', 'icon': Icons.work_rounded, 'color': Colors.green},
    {'name': 'Invest', 'icon': Icons.trending_up_rounded, 'color': Colors.teal},
    {
      'name': 'Rent',
      'icon': Icons.real_estate_agent_rounded,
      'color': Colors.indigo,
    },
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
    final lang = ref.watch(languageProvider); // LẤY NGÔN NGỮ

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppTranslations.getText(lang, 'new_transaction'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income / Expense Toggle
                    _buildTypeToggle(lang),
                    const SizedBox(height: 32),

                    // Amount Input
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                prefixStyle: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Category Selection
                    Text(
                      AppTranslations.getText(lang, 'category'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100, // Fixed height for horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _currentCategories.length,
                        itemBuilder: (context, index) {
                          final category = _currentCategories[index];
                          final isSelected =
                              _selectedCategory == category['name'];
                          return _buildCategoryItem(
                            lang,
                            category['name'], // Giữ nguyên name gốc tiếng Anh để xử lý logic
                            category['icon'],
                            category['color'],
                            isSelected,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Date Selection
                    Text(
                      AppTranslations.getText(lang, 'date'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _presentDatePicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "${_selectedDate.day.toString().padLeft(2, '0')} / ${_selectedDate.month.toString().padLeft(2, '0')} / ${_selectedDate.year}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Note Input
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
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button docked to bottom
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppTranslations.getText(lang, 'please_enter_amount'))),
                      );
                      return;
                    }

                    final amountInput =
                        double.tryParse(_amountController.text) ?? 0.0;
                    if (amountInput <= 0) return;

                    final selectedCat = _currentCategories.firstWhere(
                      (c) => c['name'] == _selectedCategory,
                    );
                    final color = selectedCat['color'] as Color;
                    final icon = selectedCat['icon'] as IconData;

                    // Gọi Use Case — không cần biết Isar hay Supabase
                    await ref
                        .read(addTransactionUseCaseProvider)
                        .execute(
                          amount: amountInput,
                          isExpense: _isExpense,
                          date: _selectedDate,
                          note: _noteController.text,
                          categoryName: _selectedCategory, // LƯU TÊN TIẾNG ANH GỐC ('Food', 'Transport')
                          categoryIconCode: icon.codePoint,
                          categoryColorHex: color.toARGB32(),
                        );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppTranslations.getText(lang, 'transaction_saved')),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    AppTranslations.getText(lang, 'save_transaction'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = true;
                if (!_expenseCategories.any(
                  (c) => c['name'] == _selectedCategory,
                )) {
                  _selectedCategory = _expenseCategories.first['name'];
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExpense
                      ? AppTheme.expenseColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    AppTranslations.getText(lang, 'expense'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isExpense
                          ? AppTheme.expenseColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isExpense = false;
                if (!_incomeCategories.any(
                  (c) => c['name'] == _selectedCategory,
                )) {
                  _selectedCategory = _incomeCategories.first['name'];
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExpense
                      ? AppTheme.incomeColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    AppTranslations.getText(lang, 'income'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: !_isExpense
                          ? AppTheme.incomeColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String lang,
    String name,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    // Dịch nhãn hiển thị trên màn hình dựa theo chữ tiếng anh gốc (chuyển sang chữ thường)
    final displayName = AppTranslations.getText(lang, name.toLowerCase());

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name), // VẪN LƯU NAME GỐC KHI ĐƯỢC CHỌN
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).cardTheme.color,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? color
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}