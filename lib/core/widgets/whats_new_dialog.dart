import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Changelog data — add a new version block here whenever you ship a release.
// Key: versionName (e.g. '2.2.2').  Value: locale → list of bullet items.
// ---------------------------------------------------------------------------
const Map<String, Map<String, List<String>>> _changelog = {
  '2.2.2': {
    'en': [
      'WhatsApp chooser: pick Business or regular WhatsApp when opening a contact\'s chat',
      'Phone number field added to technician creation',
      'Transferred badge on job cards — shows when a job was reassigned',
      'Transfer details (from whom, date) on the job detail screen',
      'Bulk job transfer for admins — long-press to select multiple jobs, then transfer all at once',
      'Job list capped at 150 most-recent entries for faster loading',
    ],
    'ur': [
      'واٹس ایپ چوزر: رابطے کی چیٹ کھولتے وقت بزنس یا عام واٹس ایپ منتخب کریں',
      'تکنیشن بنانے میں فون نمبر کا خانہ شامل کیا گیا',
      'جاب کارڈ پر "ٹرانسفرڈ" بیج — دکھاتا ہے کہ جاب کسی اور کو دی گئی',
      'جاب ڈیٹیل اسکرین پر ٹرانسفر کی تفصیل (کس سے، تاریخ)',
      'ایڈمن کے لیے بلک جاب ٹرانسفر — متعدد جابز منتخب کر کے ایک ساتھ ٹرانسفر کریں',
      'جاب لسٹ آخری 150 اندراجات تک محدود کی گئی برائے تیز رفتار لوڈنگ',
    ],
    'ar': [
      'اختيار واتساب: حدد واتساب للأعمال أو العادي عند فتح محادثة جهة اتصال',
      'إضافة حقل رقم الهاتف عند إنشاء فني جديد',
      'شارة "منقول" على بطاقات المهام — تظهر عند إعادة تعيين المهمة',
      'تفاصيل النقل (من من، التاريخ) في شاشة تفاصيل المهمة',
      'نقل مهام متعدد للمسؤولين — اضغط مطولاً لتحديد مهام متعددة ثم انقلها دفعةً واحدة',
      'قائمة المهام محدودة بآخر 150 إدخالاً لتحميل أسرع',
    ],
  },
  '2.2.1': {
    'en': [
      'Fixed: "Request Transfer" button shown even when admin approval is not required',
      'Fixed: Technician transfer dialog showed "No active technicians" error incorrectly',
    ],
    'ur': [
      'درست کیا: "ٹرانسفر کی درخواست" بٹن غیر ضروری طور پر ظاہر ہوتا تھا',
      'درست کیا: تکنیشن ٹرانسفر ڈائیلاگ میں "کوئی فعال تکنیشن نہیں" غلطی',
    ],
    'ar': [
      'إصلاح: ظهور زر "طلب نقل" حتى عندما لا يشترط موافقة المسؤول',
      'إصلاح: خطأ "لا يوجد فنيون نشطون" في نافذة نقل المهمة',
    ],
  },
  '2.1.0': {
    'en': [
      'Job transfer: admin can reassign any unpaid job to a different technician',
      'Minimum build enforcement: techs with outdated APK are guided to update',
      'WhatsApp chat opening now works correctly on Android 11+',
      'Historical import improvements: keyword validation, locked-period warning',
    ],
    'ur': [
      'جاب ٹرانسفر: ایڈمن کسی بھی غیر ادا شدہ جاب کو دوسرے تکنیشن کو دے سکتا ہے',
      'پرانا APK رکھنے والے تکنیشن کو اپڈیٹ کرنے کی ہدایت ملتی ہے',
      'Android 11+ پر واٹس ایپ چیٹ اب درست طریقے سے کھلتی ہے',
      'تاریخی امپورٹ میں بہتری: درست تصدیق، بند پیریڈ کی وارننگ',
    ],
    'ar': [
      'نقل المهام: يمكن للمسؤول إعادة تعيين أي مهمة غير مدفوعة لفني آخر',
      'إلزام الإصدار الأدنى: يُوجَّه الفنيون ذوو APK القديم للتحديث',
      'فتح محادثة واتساب يعمل بشكل صحيح على Android 11+',
      'تحسينات الاستيراد التاريخي: التحقق من الكلمة المفتاحية، تحذير الفترة المقفلة',
    ],
  },
};

// ---------------------------------------------------------------------------
// Checker — call once from shell initState after first frame
// ---------------------------------------------------------------------------

class WhatsNewChecker {
  WhatsNewChecker._();

  static Future<void> checkAndShow(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = '${info.version}+${info.buildNumber}';
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(AppConstants.lastSeenVersionKey) ?? '';

    if (lastSeen == currentVersion) return;

    // Persist immediately so the dialog cannot show twice even if dismissed
    // mid-animation or the app is backgrounded.
    await prefs.setString(AppConstants.lastSeenVersionKey, currentVersion);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsNewDialog(versionName: info.version),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key, required this.versionName});

  /// The versionName from PackageInfo (e.g. '2.2.2').
  final String versionName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Collect entries to display: current version first, then older ones
    // in order, limited to 3 versions total.
    final entries = _buildEntries(lang);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  cs.primary.withValues(alpha: 0.7),
                ],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.new_releases_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.whatsNewTitle,
                        style: tt.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'v$versionName',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: l.cancel,
                ),
              ],
            ),
          ),
          // ── Content ─────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries,
              ),
            ),
          ),
          // ── Footer ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.whatsNewGotIt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEntries(String lang) {
    final widgets = <Widget>[];
    final ordered = _orderedVersions();

    for (final version in ordered) {
      final localeMap = _changelog[version];
      if (localeMap == null) continue;
      final items =
          localeMap[lang] ?? localeMap['en'] ?? const <String>[];
      if (items.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const Divider(height: 24));
      }

      widgets.add(
        _VersionSection(version: version, items: items),
      );
    }

    return widgets;
  }

  /// Returns changelog versions in descending order, current version first.
  List<String> _orderedVersions() {
    final keys = _changelog.keys.toList();
    keys.sort((a, b) => _compareVersions(b, a)); // descending
    // Ensure current version is first if present
    if (keys.contains(versionName)) {
      keys.remove(versionName);
      keys.insert(0, versionName);
    }
    return keys.take(3).toList();
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).toList();
    final bParts = b.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bv = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}

// ---------------------------------------------------------------------------
// Version section widget
// ---------------------------------------------------------------------------

class _VersionSection extends StatelessWidget {
  const _VersionSection({required this.version, required this.items});

  final String version;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'v$version',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: 5,
                    end: 8,
                  ),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(item, style: tt.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
