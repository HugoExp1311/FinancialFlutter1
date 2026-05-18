import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../providers/app_providers.dart';
import '../utils/transaction_actions.dart';
import '../utils/category_utils.dart';
import 'package:core_domain/core_domain.dart';
import '../providers/language_provider.dart';
import '../utils/app_translations.dart';
import '../utils/format_utils.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _timeFilter = 'Day'; 
  DateTime? _selectedDate; 
  int _statType = 0; // 0: Net, 1: Expense, 2: Income

  List<TransactionEntity> _getFilteredTransactions(
    List<TransactionEntity> allTxs,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    if (_timeFilter == 'Day') {
      final target = _selectedDate ?? DateTime.now();
      return allTxs.where((tx) {
        if (tx.isDeleted) return false;
        return tx.date.year == target.year &&
            tx.date.month == target.month &&
            tx.date.day == target.day;
      }).toList();
    } else if (_timeFilter == 'Week') {
      startDate = now.subtract(const Duration(days: 7));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    } else if (_timeFilter == 'Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    return allTxs.where((tx) {
      if (tx.isDeleted) return false;
      return tx.date.isAfter(
        startDate.subtract(const Duration(microseconds: 1)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider); 

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppTranslations.getText(lang, 'statistics'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: AppTranslations.getText(lang, 'sync_data'),
                      icon: const Icon(
                        Icons.sync_rounded,
                        color: AppTheme.textSubDark,
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppTranslations.getText(
                                lang,
                                'syncing_with_cloud',
                              ),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        await ref
                            .read(syncTransactionsUseCaseProvider)
                            .execute();
                      },
                    ),
                  ],
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _buildTimeFilters(lang),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(syncTransactionsUseCaseProvider).execute();
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildStatTypeToggle(lang),
                    ),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _buildSummaryAndLineChart(lang),
                    ),
                    const SizedBox(height: 32),

                    if (_statType != 0) 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.getText(
                                lang,
                                'category_breakdown',
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildPieChartSection(lang),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppTranslations.getText(lang, 'details_by_date'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppTranslations.getText(
                                      lang,
                                      'search_filter_active',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailsList(ref, lang),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Day', 'Week', 'Month', 'Year'].map((filter) {
          final isSelected = _timeFilter == filter;
          String label = AppTranslations.getText(lang, filter.toLowerCase());
          if (filter == 'Day' && isSelected) {
            final d = _selectedDate ?? DateTime.now();
            label = '${d.day}/${d.month}';
          }

          return GestureDetector(
            onTap: () async {
              if (filter == 'Day') {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppTheme.primaryColor,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _timeFilter = 'Day';
                  });
                } else if (!isSelected) {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _timeFilter = 'Day';
                  });
                }
              } else {
                setState(() => _timeFilter = filter);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatTypeToggle(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleTab(
            0,
            AppTranslations.getText(lang, 'net'),
            AppTheme.primaryColor,
          ),
          _buildToggleTab(
            1,
            AppTranslations.getText(lang, 'expense'),
            AppTheme.expenseColor,
          ),
          _buildToggleTab(
            2,
            AppTranslations.getText(lang, 'income'),
            AppTheme.incomeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(int index, String title, Color activeColor) {
    final isSelected = _statType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _statType = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? activeColor
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryAndLineChart(String lang) {
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    double income = 0;
    double expense = 0;

    int numBuckets = 7;
    if (_timeFilter == 'Year') numBuckets = 12;
    if (_timeFilter == 'Month') numBuckets = 31;
    if (_timeFilter == 'Day') numBuckets = 24;

    List<double> buckets = List.filled(numBuckets, 0.0);

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      final timeFiltered = _getFilteredTransactions(txAsyncValue.value!);

      for (var tx in timeFiltered) {
        if (tx.isExpense) {
          expense += tx.amount;
        } else {
          income += tx.amount;
        }

        int bucketIndex = 0;
        if (_timeFilter == 'Year') {
          bucketIndex = tx.date.month - 1;
        } else if (_timeFilter == 'Month') {
          bucketIndex = tx.date.day - 1;
        } else if (_timeFilter == 'Week') {
          bucketIndex = tx.date.weekday - 1;
        } else if (_timeFilter == 'Day') {
          bucketIndex = tx.date.hour;
        }

        if (bucketIndex >= 0 && bucketIndex < numBuckets) {
          if (_statType == 0) {
            buckets[bucketIndex] += tx.isExpense ? -tx.amount : tx.amount;
          } else if (_statType == 1 && tx.isExpense) {
            buckets[bucketIndex] += tx.amount;
          } else if (_statType == 2 && !tx.isExpense) {
            buckets[bucketIndex] += tx.amount;
          }
        }
      }
    }
    
    double net = income - expense;

    String title = AppTranslations.getText(lang, 'net_income');
    String sign = net < 0 ? '-' : '';
    String amount = "$sign${FormatUtils.formatCurrency(net.abs(), lang)}";
    Color mainColor = AppTheme.primaryColor;

    if (_statType == 1) {
      title = AppTranslations.getText(lang, 'total_expense');
      amount = FormatUtils.formatCurrency(expense, lang);
      mainColor = AppTheme.expenseColor;
    } else if (_statType == 2) {
      title = AppTranslations.getText(lang, 'total_income');
      amount = FormatUtils.formatCurrency(income, lang);
      mainColor = AppTheme.incomeColor;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSubDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(lineColor: mainColor, points: buckets),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLabels(),
        ],
      ),
    );
  }

  Widget _buildChartLabels() {
    List<String> labels = [];
    if (_timeFilter == 'Day') {
      labels = ['00:00', '06:00', '12:00', '18:00', '23:59'];
    } else if (_timeFilter == 'Week') {
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    } else if (_timeFilter == 'Month') {
      labels = ['1', '8', '15', '22', '31'];
    } else if (_timeFilter == 'Year') {
      labels = ['Jan', 'Apr', 'Jul', 'Oct', 'Dec'];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((l) {
        return Text(
          l,
          style: const TextStyle(color: AppTheme.textSubDark, fontSize: 10),
        );
      }).toList(),
    );
  }

  Widget _buildPieChartSection(String lang) {
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    Map<String, double> categorySums = {};
    double totalFilterAmount = 0;

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      final timeFiltered = _getFilteredTransactions(txAsyncValue.value!);

      for (var tx in timeFiltered) {
        if ((_statType == 1 && tx.isExpense) ||
            (_statType == 2 && !tx.isExpense)) {
          categorySums[tx.categoryName] =
              (categorySums[tx.categoryName] ?? 0) + tx.amount;
          totalFilterAmount += tx.amount;
        }
      }
    }

    var sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Color> pieColors = [
      Colors.orange,
      Colors.blue,
      Colors.pink,
      Colors.grey,
    ];
    if (_statType == 2) {
      pieColors = [Colors.green, Colors.teal, Colors.indigo, Colors.grey];
    }

    List<Widget> legendWidgets = [];
    List<double> sweeps = [];

    double otherSum = 0;

    for (int i = 0; i < sortedEntries.length; i++) {
      if (i < 4) {
        double percentage = totalFilterAmount > 0
            ? (sortedEntries[i].value / totalFilterAmount)
            : 0;
        sweeps.add(percentage);

        final categoryColor = CategoryUtils.getColor(sortedEntries[i].key);
        if (sweeps.length - 1 >= pieColors.length) {
          pieColors.add(categoryColor);
        } else {
          pieColors[sweeps.length - 1] = categoryColor;
        }

        legendWidgets.add(
          _buildLegendItem(
            categoryColor,
            AppTranslations.getText(lang, sortedEntries[i].key.toLowerCase()),
            '${(percentage * 100).toStringAsFixed(1)}%',
          ),
        );
      } else {
        otherSum += sortedEntries[i].value;
      }
    }

    if (otherSum > 0) {
      double percentage = totalFilterAmount > 0
          ? (otherSum / totalFilterAmount)
          : 0;
      sweeps.add(percentage);
      legendWidgets.add(
        _buildLegendItem(
          Colors.grey,
          AppTranslations.getText(lang, 'other'),
          '${(percentage * 100).toStringAsFixed(1)}%',
        ),
      );
    }

    if (sweeps.isEmpty) {
      sweeps.add(1.0);
    }

    return Row(
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CustomPaint(
            painter: _PieChartPainter(
              colors: sweeps.length == 1 && legendWidgets.isEmpty
                  ? [Colors.grey.withValues(alpha: 0.2)]
                  : pieColors,
              sweeps: sweeps,
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendWidgets.isEmpty
                ? [
                    Text(
                      AppTranslations.getText(lang, 'no_data_category'),
                      style: const TextStyle(color: AppTheme.textSubDark),
                    ),
                  ]
                : legendWidgets,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String name, String percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailsList(WidgetRef ref, String lang) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppTranslations.getText(lang, 'no_transactions_found'),
                style: const TextStyle(color: AppTheme.textSubDark),
              ),
            ),
          );
        }

        var filteredTxs = _getFilteredTransactions(transactions);

        if (_statType == 1) {
          filteredTxs = filteredTxs.where((tx) => tx.isExpense).toList();
        } else if (_statType == 2) {
          filteredTxs = filteredTxs.where((tx) => !tx.isExpense).toList();
        }

        if (filteredTxs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppTranslations.getText(lang, 'no_data_match'),
                style: const TextStyle(color: AppTheme.textSubDark),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTxs.length,
          itemBuilder: (context, index) {
            final tx = filteredTxs[index];
            
            final sign = tx.isExpense ? '-' : '+';
            final formattedAmt = FormatUtils.formatCurrency(tx.amount.abs(), lang);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GestureDetector(
                onLongPress: () =>
                    TransactionActions.showOptions(context, ref, tx),
                onTap: () => TransactionActions.showOptions(context, ref, tx),
                child: TransactionItem(
                  title: tx.note != null && tx.note!.isNotEmpty
                      ? tx.note!
                      : AppTranslations.getText(lang, tx.categoryName.toLowerCase()),
                  date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                  amountText: '$sign$formattedAmt',
                  isExpense: tx.isExpense,
                  icon: CategoryUtils.getIcon(tx.categoryName),
                  iconColor: CategoryUtils.getColor(tx.categoryName),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

// --- CUSTOM PAINTERS ---

class _LineChartPainter extends CustomPainter {
  final Color lineColor;
  final List<double> points;
  _LineChartPainter({required this.lineColor, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double maxVal = points.isNotEmpty ? points.reduce(math.max) : 0;
    double minVal = points.isNotEmpty ? points.reduce(math.min) : 0;

    if (minVal == maxVal) {
      minVal -= 10;
      maxVal += 10;
    }
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    double stepX = size.width / (points.length <= 1 ? 1 : points.length - 1);

    for (int i = 0; i < points.length; i++) {
      double normalized = (points[i] - minVal) / range;
      double y = size.height * 0.9 - (normalized * size.height * 0.8);
      double x = i * stepX;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * stepX;
        double prevNormalized = (points[i - 1] - minVal) / range;
        double prevY = size.height * 0.9 - (prevNormalized * size.height * 0.8);

        path.cubicTo(prevX + stepX / 2.5, prevY, x - stepX / 2.5, y, x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.3),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> sweeps;
  _PieChartPainter({required this.colors, required this.sweeps});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < sweeps.length; i++) {
      paint.color = colors[i % colors.length];
      final sweepAngle = sweeps[i] * 2 * math.pi;
      
      final gap = sweeps.length > 1 ? 0.1 : 0.0;
      canvas.drawArc(rect, startAngle, sweepAngle - gap, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}