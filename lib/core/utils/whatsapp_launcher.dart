import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static const _waPackage = 'com.whatsapp';
  static const _waBizPackage = 'com.whatsapp.w4b';
  static const _waColor = Color(0xFF25D366);

  static String normalizeNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (digits.isEmpty) return '';
    if (digits.startsWith('+')) return digits.substring(1);
    if (digits.startsWith('00')) return digits.substring(2);
    return digits;
  }

  /// Returns true when the given app package is installed on this Android
  /// device. Always false on web.
  static Future<bool> _isInstalled(String package) async {
    if (kIsWeb) return false;
    final uri = Uri.parse(
      'intent://send?phone=0'
      '#Intent;scheme=whatsapp;package=$package;end',
    );
    return canLaunchUrl(uri);
  }

  /// Opens a chat in the specified WhatsApp package via Android intent.
  /// Falls back to the universal wa.me link if the intent cannot be resolved.
  static Future<void> _openInPackage(
    String normalized,
    String package, {
    String? message,
  }) async {
    final textParam =
        message != null ? '?text=${Uri.encodeComponent(message)}' : '';
    if (!kIsWeb) {
      final intentUri = Uri.parse(
        'intent://send?phone=$normalized'
        '#Intent;scheme=whatsapp;package=$package;end',
      );
      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    await launchUrl(
      Uri.parse('https://wa.me/$normalized$textParam'),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Shows a bottom sheet asking the user to choose between WhatsApp and
  /// WhatsApp Business. When only one app is installed it is opened directly
  /// (no dialog). When neither is installed the universal wa.me link is used.
  ///
  /// Pass [message] to pre-fill the chat text.
  static Future<void> showChooser(
    BuildContext context,
    String rawPhone, {
    String? message,
  }) async {
    final normalized = normalizeNumber(rawPhone);
    if (normalized.isEmpty) return;

    final hasBiz = await _isInstalled(_waBizPackage);
    final hasWa = await _isInstalled(_waPackage);

    if (!context.mounted) return;

    // Neither app installed — open web link directly.
    if (!hasBiz && !hasWa) {
      final textParam =
          message != null ? '?text=${Uri.encodeComponent(message)}' : '';
      await launchUrl(
        Uri.parse('https://wa.me/$normalized$textParam'),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // Only one app installed — open it directly without a dialog.
    if (hasBiz && !hasWa) {
      await _openInPackage(normalized, _waBizPackage, message: message);
      return;
    }
    if (hasWa && !hasBiz) {
      await _openInPackage(normalized, _waPackage, message: message);
      return;
    }

    // Both installed — let the user choose.
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: _waColor,
              ),
              title: const Text('WhatsApp Business'),
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
              leading: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: _waColor,
              ),
              title: const Text('WhatsApp'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _openInPackage(
                  normalized,
                  _waPackage,
                  message: message,
                );
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
  ) =>
      showChooser(context, rawPhone, message: message);

  // ── Legacy direct methods kept for bulk / programmatic flows ──────────────

  /// Direct open via wa.me (no chooser). Use for batch notifications where
  /// showing a per-contact dialog would be disruptive.
  static Future<bool> openChat(String rawPhone) async {
    final normalized = normalizeNumber(rawPhone);
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
