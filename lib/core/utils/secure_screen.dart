import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Enables or disables FLAG_SECURE (prevent screenshots / screen-recording)
/// on the current Activity window via a native MethodChannel.
///
/// Call [enable] in initState() of screens showing sensitive financial or
/// personal data (settlement screens, invoice details, job details).
/// Call [disable] in dispose() to restore default behavior.
class SecureScreen {
  SecureScreen._();

  static const _channel = MethodChannel('com.actechs.pk/packages');

  static Future<void> enable() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecureScreen', {'secure': true});
    } on PlatformException {
      // Non-fatal — proceed without FLAG_SECURE on unsupported platforms.
    } on MissingPluginException {
      // Test environment or channel not yet registered.
    }
  }

  static Future<void> disable() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecureScreen', {'secure': false});
    } on PlatformException {
      // Non-fatal.
    } on MissingPluginException {
      // Test environment.
    }
  }
}
