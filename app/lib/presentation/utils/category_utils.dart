import 'package:flutter/material.dart';

class CategoryUtils {
  static final Map<String, Map<String, dynamic>> _mapping = {
    'Food': {'icon': Icons.fastfood_rounded, 'color': Colors.orange},
    'Transport': {'icon': Icons.directions_car_rounded, 'color': Colors.blue},
    'Shopping': {'icon': Icons.shopping_bag_rounded, 'color': Colors.pink},
    'Bills': {'icon': Icons.receipt_long_rounded, 'color': Colors.purple},
    'Salary': {'icon': Icons.work_rounded, 'color': Colors.green},
    'Invest': {'icon': Icons.trending_up_rounded, 'color': Colors.teal},
    'Rent': {'icon': Icons.real_estate_agent_rounded, 'color': Colors.indigo},
    'Other': {'icon': Icons.star_rounded, 'color': Colors.grey},
  };

  static IconData getIcon(String categoryName) {
    return _mapping[categoryName]?['icon'] as IconData? ?? Icons.star_rounded;
  }

  static Color getColor(String categoryName) {
    return _mapping[categoryName]?['color'] as Color? ?? Colors.grey;
  }
}
