import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

const _kLocaleKey = 'app_locale';

/// App locale as a Notifier — works pre-login (SharedPreferences)
/// and syncs with Firestore user doc after login.
final appLocaleProvider = NotifierProvider<LocaleNotifier, String>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<String> {
  bool _syncedFromUser = false;

  @override
  String build() {
    _init();

    // When user logs in, pick up their Firestore language
    ref.listen(currentUserProvider, (_, next) {
      final user = next.value;
      if (user != null && !_syncedFromUser) {
        _syncedFromUser = true;
        if (user.language.isNotEmpty && user.language != state) {
          state = user.language;
        }
      }
      if (user == null) {
        _syncedFromUser = false;
      }
    });

    return 'en';
  }

  Future<void> _init() async {
    // Load from SharedPreferences first (pre-login)
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null && saved != state) {
      state = saved;
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale);
  }
}
