/// Centralized date/time formatting that respects locale.
class AppFormatters {
  AppFormatters._();

  /// Format a date as dd/MM/yyyy.
  static String date(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// SAR currency with no decimals.
  static String currency(double amount) {
    return 'SAR ${amount.toStringAsFixed(0)}';
  }

  /// Plural-safe unit count.
  static String units(int count) {
    return '$count ${count == 1 ? 'unit' : 'units'}';
  }

  /// Short name for display (first 8 chars + ..).
  static String shortName(String name, [int max = 8]) {
    if (name.length <= max) return name;
    return '${name.substring(0, max)}..';
  }
}
