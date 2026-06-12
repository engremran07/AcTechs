import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final monthClosureNoticeRepositoryProvider =
    Provider<MonthClosureNoticeRepository>((ref) {
  return MonthClosureNoticeRepository();
});

class MonthClosureNoticeRepository {
  static const String _prefix = 'seen_month_closure_';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _key(String techId, String companyId, String monthKey) =>
      '$_prefix${techId.trim()}_${companyId.trim()}_$monthKey';

  Future<bool> hasSeen({
    required String techId,
    required String companyId,
    required String monthKey,
  }) async {
    final prefs = await _prefs;
    return prefs.getBool(_key(techId, companyId, monthKey)) ?? false;
  }

  Future<void> markSeen({
    required String techId,
    required String companyId,
    required String monthKey,
  }) async {
    final prefs = await _prefs;
    await prefs.setBool(_key(techId, companyId, monthKey), true);
  }
}
