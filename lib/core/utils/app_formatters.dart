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

  /// Format a date+time as dd/MM/yyyy HH:mm.
  static String dateTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${date(dt)}  $hh:$mm';
  }

  /// Returns '' for null; strips newlines and trims whitespace.
  static String safeText(String? value) {
    if (value == null) return '';
    return value.replaceAll('\n', ' ').trim();
  }

  /// Returns true when the delivery/expense note indicates the customer paid
  /// in cash (used in PDF and Excel export to suppress SAR charge display).
  static bool isCustomerCashPaid(String? note) {
    final normalized = safeText(note).toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('cash') ||
        normalized.contains('customer paid') ||
        normalized.contains('paid by customer');
  }

  /// Midnight at the start of [dt] (defaults to today).
  static DateTime startOfDay([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// 23:59:59.999 at the end of [dt] (defaults to today).
  static DateTime endOfDay([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
  }

  /// First moment of the month containing [dt] (defaults to today).
  static DateTime startOfMonth([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month);
  }

  /// Last moment of the month containing [dt] (defaults to today).
  static DateTime endOfMonth([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59, 999);
  }

  /// Short name for display (first 8 chars + ..).
  static String shortName(String name, [int max = 8]) {
    if (name.length <= max) return name;
    return '${name.substring(0, max)}..';
  }
}
