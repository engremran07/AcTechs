class InvoiceUtils {
  InvoiceUtils._();

  /// Normalizes invoice values for storage and duplicate checks.
  /// Strips legacy "INV-"/"INV " prefixes and trims whitespace.
  static String normalize(String invoice) {
    final trimmed = invoice.trim();
    if (trimmed.isEmpty) return '';

    final upper = trimmed.toUpperCase();
    if (upper.startsWith('INV-') || upper.startsWith('INV ')) {
      return trimmed.substring(4).trim();
    }

    return trimmed;
  }
}
