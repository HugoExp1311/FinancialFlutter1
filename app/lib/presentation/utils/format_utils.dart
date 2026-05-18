class FormatUtils {
  static String formatCurrency(double amountInUsd, String lang) {
    if (lang == 'vi') {
      final amountInVnd = amountInUsd * 25000;
      String formattedVnd = amountInVnd.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
          (Match m) => '${m[1]}.'
      );
      return '$formattedVnd đ';
    } else {
      return '\$${amountInUsd.toStringAsFixed(2)}';
    }
  }
}