import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

const _kThemeKey = 'app_theme_mode';

/// Supported theme modes for the app.
enum AppThemeMode { auto, dark, light, highContrast }

/// Provides the current theme mode, synced to SharedPreferences + Firestore.
final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  bool _syncedFromUser = false;

  @override
  AppThemeMode build() {
    _init();

    // Sync from Firestore user doc after login
    ref.listen(currentUserProvider, (_, next) {
      final user = next.value;
      if (user != null && !_syncedFromUser) {
        _syncedFromUser = true;
        _loadFromFirestore(user.uid);
      }
      if (user == null) {
        _syncedFromUser = false;
      }
    });

    return AppThemeMode.dark;
  }

  Future<void> _init() async {
    // Load from SharedPreferences (works pre-login)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      state = _parse(saved);
    }
  }

  Future<void> _loadFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final raw = doc.data()?['themeMode'] as String?;
      if (raw != null) {
        final mode = _parse(raw);
        state = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kThemeKey, mode.name);
      }
    } catch (_) {
      // Keep current state on failure
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;

    // Save to SharedPreferences (always works)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);

    // Save to Firestore if logged in
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'themeMode': mode.name});
      } catch (_) {
        // Fail silently — local state is already updated
      }
    }
  }

  /// Cycle through modes: auto → dark → light → highContrast → auto
  void cycle() {
    final next = switch (state) {
      AppThemeMode.auto => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.highContrast,
      AppThemeMode.highContrast => AppThemeMode.auto,
    };
    setMode(next);
  }

  static AppThemeMode _parse(String? raw) {
    return switch (raw) {
      'auto' => AppThemeMode.auto,
      'light' => AppThemeMode.light,
      'highContrast' => AppThemeMode.highContrast,
      _ => AppThemeMode.dark,
    };
  }
}
