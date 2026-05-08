import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static String normalizeNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (digits.isEmpty) return '';
    if (digits.startsWith('+')) {
      return digits.substring(1);
    }
    if (digits.startsWith('00')) {
      return digits.substring(2);
    }
    return digits;
  }

  static Future<bool> openChat(String rawPhone) async {
    final normalized = normalizeNumber(rawPhone);
    if (normalized.isEmpty) return false;

    final uri = Uri.parse('https://wa.me/$normalized');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Opens a WhatsApp chat with [rawPhone] pre-populated with [message].
  ///
  /// Returns true if the URL was successfully launched, false if WhatsApp is
  /// not available on this device or the phone number is empty.
  static Future<bool> openChatWithMessage(
    String rawPhone,
    String message,
  ) async {
    final normalized = normalizeNumber(rawPhone);
    if (normalized.isEmpty) return false;

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$normalized?text=$encoded');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
