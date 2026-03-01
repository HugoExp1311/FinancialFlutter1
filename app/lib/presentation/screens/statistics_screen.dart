import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../providers/app_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _timeFilter = 'Month'; // Các tab bộ lọc thời gian
  int _statType = 0; // 0: Net Income, 1: Expense, 2: Income

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Bộ lọc thời gian
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                _buildTimeFilters(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab chọn Loại Báo Cáo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildStatTypeToggle(),
                  ),
                  const SizedBox(height: 24),

                  // Biểu đồ đường (Line Chart) & Tổng Thu Nhập Ròng
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildSummaryAndLineChart(),
                  ),
                  const SizedBox(height: 32),

                  // Biểu đồ hình tròn (Pie Chart) cho phân bổ danh mục
                  if (_statType !=
                      0) // Chỉ hiện Pie Chart nếu đang xem Income/Expense
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPieChartSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                  // Danh sách Giao dịch chi tiết theo Ngày
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Details by Date',
                          style: TextStyle(
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
                              const SnackBar(
                                content: Text('Search filter active!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailsList(ref),
                  const SizedBox(
                    height: 80,
                  ), // Thêm khoảng trống dưới cùng để cuộn không cấn nút
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Week', 'Month', 'Year'].map((filter) {
          final isSelected = _timeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _timeFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                filter,
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

  Widget _buildStatTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleTab(0, 'Net', AppTheme.primaryColor),
          _buildToggleTab(1, 'Expense', AppTheme.expenseColor),
          _buildToggleTab(2, 'Income', AppTheme.incomeColor),
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

  Widget _buildSummaryAndLineChart() {
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    double income = 0;
    double expense = 0;

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      for (var tx in txAsyncValue.value!) {
        if (!tx.isDeleted) {
          if (tx.isExpense) {
            expense += tx.amount;
          } else {
            income += tx.amount;
          }
        }
      }
    }
    double net = income - expense;

    String title = "Net Income";
    String amount = "\$${net.toStringAsFixed(2)}";
    Color mainColor = AppTheme.primaryColor;

    if (_statType == 1) {
      title = "Total Expense";
      amount = "\$${expense.toStringAsFixed(2)}";
      mainColor = AppTheme.expenseColor;
    } else if (_statType == 2) {
      title = "Total Income";
      amount = "\$${income.toStringAsFixed(2)}";
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
          // Biểu đồ đường Tự Cốt (Tự vẽ bằng CustomPaint chuyên nghiệp)
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(lineColor: mainColor),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week 1',
                style: TextStyle(color: AppTheme.textSubDark, fontSize: 12),
              ),
              Text(
                'Week 2',
                style: TextStyle(color: AppTheme.textSubDark, fontSize: 12),
              ),
              Text(
                'Week 3',
                style: TextStyle(color: AppTheme.textSubDark, fontSize: 12),
              ),
              Text(
                'Week 4',
                style: TextStyle(color: AppTheme.textSubDark, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    final txAsyncValue = ref.watch(transactionsStreamProvider);
    Map<String, double> categorySums = {};
    double totalFilterAmount = 0;

    if (txAsyncValue.hasValue && txAsyncValue.value != null) {
      for (var tx in txAsyncValue.value!) {
        if (!tx.isDeleted &&
            ((_statType == 1 && tx.isExpense) ||
                (_statType == 2 && !tx.isExpense))) {
          categorySums[tx.categoryName] =
              (categorySums[tx.categoryName] ?? 0) + tx.amount;
          totalFilterAmount += tx.amount;
        }
      }
    }

    // Sắp xếp các danh mục lớn nhất
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
      if (i < 3) {
        double percentage = totalFilterAmount > 0
            ? (sortedEntries[i].value / totalFilterAmount)
            : 0;
        sweeps.add(percentage);
        legendWidgets.add(
          _buildLegendItem(
            pieColors[i],
            sortedEntries[i].key,
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
          'Other',
          '${(percentage * 100).toStringAsFixed(1)}%',
        ),
      );
    }

    if (sweeps.isEmpty)
      sweeps.add(1.0); // Hiển thị 1 vòng tròn trống nếu ko có data

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
                    const Text(
                      'No data for this category.',
                      style: TextStyle(color: AppTheme.textSubDark),
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

  Widget _buildDetailsList(WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(transactionsStreamProvider);

    return transactionsAsyncValue.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No transactions found.',
                style: TextStyle(color: AppTheme.textSubDark),
              ),
            ),
          );
        }

        // Lọc theo loại thống kê
        var filteredTxs = transactions.where((tx) => !tx.isDeleted).toList();
        if (_statType == 1) {
          filteredTxs = filteredTxs.where((tx) => tx.isExpense).toList();
        } else if (_statType == 2) {
          filteredTxs = filteredTxs.where((tx) => !tx.isExpense).toList();
        }

        if (filteredTxs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No data match.',
                style: TextStyle(color: AppTheme.textSubDark),
              ),
            ),
          );
        }

        // Ghi trực tiếp ListView
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTxs.length,
          itemBuilder: (context, index) {
            final tx = filteredTxs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TransactionItem(
                title: tx.note != null && tx.note!.isNotEmpty
                    ? tx.note!
                    : tx.categoryName,
                date: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                amount: tx.isExpense ? -tx.amount : tx.amount,
                icon: IconData(
                  tx.categoryIconCode,
                  fontFamily: 'MaterialIcons',
                ),
                iconColor: Color(tx.categoryColorHex),
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

// ============== CUSTOM PAINTERS THỂ HIỆN TRÌNH ĐỘ CODE EXPERT ================

class _LineChartPainter extends CustomPainter {
  final Color lineColor;
  _LineChartPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Giả lập dữ liệu đường cong
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.8,
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.4,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.6,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.1,
      size.width,
      size.height * 0.3,
    );

    canvas.drawPath(path, paint);

    // Vẽ vùng Gradient bên dưới đường Line
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
      // Dùng stroke Cap round nên vẽ lùi lại 1 chút để có khoảng hở giữa các phần (trừ khi có mỗi 1 đoạn 100%)
      final gap = sweeps.length > 1 ? 0.1 : 0.0;
      canvas.drawArc(rect, startAngle, sweepAngle - gap, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
