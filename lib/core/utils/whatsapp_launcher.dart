import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ac_techs/core/models/country_dial_code.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Launcher for WhatsApp chats with correct package detection.
///
/// **Root cause of prior bug**: `canLaunchUrl()` with an `intent://` URI
/// checks whether *any* app handles the `whatsapp://` scheme, not whether
/// the specific `package=` value is installed. This caused both
/// `_isInstalled('com.whatsapp')` and `_isInstalled('com.whatsapp.w4b')` to
/// return `true` when only one was installed, leading to the chooser appearing
/// and the tapped option silently failing.
///
/// **Fix**: Use a `MethodChannel` to call `PackageManager.getPackageInfo()`
/// directly, which is the only reliable per-package installation check on
/// Android 11+. Both packages are declared in `<queries>` in
/// AndroidManifest.xml so Android permits the queries.
class WhatsAppLauncher {
  WhatsAppLauncher._();

  static const _waPackage = 'com.whatsapp';
  static const _waBizPackage = 'com.whatsapp.w4b';
  static const _waColor = Color(0xFF25D366);
  static const _channel = MethodChannel('com.actechs.pk/packages');

  // ── Number normalisation ──────────────────────────────────────────────────

  /// Normalises [raw] to E.164 digits-only (no '+').
  /// Handles:
  ///   '+966554123456'  → '966554123456'
  ///   '00966554123456' → '966554123456'
  ///   '0554123456'     → '966554123456'  (KSA local with leading 0)
  ///   '00554123456'    → '966554123456'  (double-zero local)
  ///   '966554123456'   → '966554123456'  (already E.164)
  static String normalizeNumber(
    String raw, {
    CountryDialCode defaultCountry = CountryDialCode.ksa,
  }) {
    var n = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    if (n.isEmpty) return '';
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('00')) n = n.substring(2);
    n = n.replaceAll(RegExp(r'\D'), '');

    if (_looksLikeNanpLocal(n)) {
      return '1$n';
    }

    if (_looksLikeSaudiLocal(n) && defaultCountry == CountryDialCode.ksa) {
      return '${defaultCountry.dialCode}$n';
    }

    // Strip ALL leading zeros then prepend country code
    if (n.startsWith('0')) {
      n = '${defaultCountry.dialCode}${n.replaceFirst(RegExp(r'^0+'), '')}';
    }
    return n;
  }

  /// NANP local format: NXXNXXXXXX where N is 2-9.
  static bool _looksLikeNanpLocal(String digits) {
    return RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits);
  }

  /// KSA local mobile format (9 digits starting with 5).
  static bool _looksLikeSaudiLocal(String digits) {
    return RegExp(r'^5\d{8}$').hasMatch(digits);
  }

  // ── Reliable package detection via MethodChannel ──────────────────────────

  /// Returns `true` only if [package] is actually installed on this device.
  ///
  /// Uses `PackageManager.getPackageInfo()` via a native MethodChannel — the
  /// only reliable per-package check on Android 11+. Falls back to `false`
  /// on web, non-Android, or if the channel is unavailable (e.g. in tests).
  static Future<bool> _isInstalled(String package) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isInstalled', {
        'package': package,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  // ── Open in a specific WhatsApp package ────────────────────────────────────

  /// Opens [normalized] phone in [package] using Intent.setPackage() via
  /// MethodChannel — the only reliable mechanism on Samsung One UI and other
  /// OEM Android skins where intent:// package= constraints are silently
  /// ignored by the modified ActivityManagerService.
  ///
  /// Falls back to the universal wa.me link when:
  ///   - Running on web or non-Android platform
  ///   - MethodChannel reports ActivityNotFoundException (app not installed)
  ///   - Any exception occurs
  static Future<void> _openInPackage(
    String normalized,
    String package, {
    String? message,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final launched = await _channel.invokeMethod<bool>('openWhatsApp', {
          'phone': normalized,
          'package': package,
          'message': message ?? '',
        });
        if (launched == true) return;
        // false = ActivityNotFoundException — package not installed.
        // Fall through to wa.me universal link.
      } on PlatformException {
        // Channel error — fall through.
      } on MissingPluginException {
        // Test environment — fall through.
      }
    }
    // Universal fallback: opens in browser or OS default WA handler.
    final textParam = (message != null && message.isNotEmpty)
        ? '?text=${Uri.encodeComponent(message)}'
        : '';
    await launchUrl(
      Uri.parse('https://wa.me/$normalized$textParam'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ── Public chooser ──────────────────────────────────────────────────────────

  /// Shows a bottom sheet letting the user choose between WhatsApp Business
  /// and regular WhatsApp. Correctly detects which variants are installed
  /// and either opens directly (single variant) or shows the picker (both).
  static Future<void> showChooser(
    BuildContext context,
    String rawPhone, {
    String? message,
    CountryDialCode defaultCountry = CountryDialCode.ksa,
  }) async {
    final normalized = normalizeNumber(
      rawPhone,
      defaultCountry: defaultCountry,
    );
    if (normalized.isEmpty) return;

    final hasBiz = await _isInstalled(_waBizPackage);
    final hasWa = await _isInstalled(_waPackage);

    if (!context.mounted) return;

    // Neither installed — open wa.me directly (browser or OS handler).
    if (!hasBiz && !hasWa) {
      final textParam = (message != null && message.isNotEmpty)
          ? '?text=${Uri.encodeComponent(message)}'
          : '';
      await launchUrl(
        Uri.parse('https://wa.me/$normalized$textParam'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // Only one variant installed — open it directly, no dialog.
    if (hasBiz && !hasWa) {
      await _openInPackage(normalized, _waBizPackage, message: message);
      return;
    }
    if (hasWa && !hasBiz) {
      await _openInPackage(normalized, _waPackage, message: message);
      return;
    }

    // Both installed — show the chooser bottom sheet.
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.whatsapp, color: _waColor),
              title: Text(l.whatsappBusinessLabel),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _openInPackage(
                  normalized,
                  _waBizPackage,
                  message: message,
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.whatsapp, color: _waColor),
              title: Text(l.whatsappAppLabel),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _openInPackage(normalized, _waPackage, message: message);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Convenience wrapper for [showChooser] with a pre-filled [message].
  static Future<void> showChooserWithMessage(
    BuildContext context,
    String rawPhone,
    String message,
  ) => showChooser(context, rawPhone, message: message);

  // ── Legacy direct methods kept for batch / programmatic flows ─────────────

  /// Direct open via wa.me (no chooser). Use for batch team notifications
  /// where showing a per-contact dialog would be disruptive.
  static Future<bool> openChat(
    String rawPhone, {
    CountryDialCode defaultCountry = CountryDialCode.ksa,
  }) async {
    final normalized = normalizeNumber(
      rawPhone,
      defaultCountry: defaultCountry,
    );
    if (normalized.isEmpty) return false;
    try {
      return launchUrl(
        Uri.parse('https://wa.me/$normalized'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  /// Direct open with message via wa.me (no chooser).
  static Future<bool> openChatWithMessage(
    String rawPhone,
    String message,
  ) async {
    final normalized = normalizeNumber(rawPhone);
    if (normalized.isEmpty) return false;
    try {
      return launchUrl(
        Uri.parse(
          'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
