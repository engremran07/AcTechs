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
  '2.3.0': {
    'en': [
      'Web App Check now active on every live deployment — admin data is properly protected',
      'Screen recording protection expanded to All Jobs, Analytics, Flush Database, and Reports screens',
      'Company phone number field now has country code picker (same as technician phone)',
      'Website loading improved with branded spinner while app initialises',
    ],
    'ur': [
      'ویب App Check اب ہر لائیو ڈیپلوئمنٹ پر فعال — ایڈمن ڈیٹا مناسب طور پر محفوظ',
      'اسکرین ریکارڈنگ پروٹیکشن تمام جابز، اینالیٹکس، فلش ڈیٹابیس اور رپورٹس اسکرینز تک بڑھائی',
      'کمپنی فون نمبر فیلڈ میں اب کنٹری کوڈ پِکر موجود ہے',
    ],
    'ar': [
      'App Check للويب نشط الآن في كل عملية نشر مباشرة — بيانات المسؤول محمية بشكل صحيح',
      'حماية تسجيل الشاشة موسّعة لتشمل كل المهام والتحليلات وتنظيف قاعدة البيانات والتقارير',
      'حقل رقم هاتف الشركة يحتوي الآن على منتقي رمز الدولة',
    ],
  },
  '2.2.9': {
    'en': [
      'Deep audit: 8 new Dart lint rules added (safety-focused: avoid_slow_async_io, cancel_subscriptions, throw_in_finally, and more)',
      'Code fix: file cleanup now uses synchronous File API (avoid_slow_async_io compliance)',
      'Docs: PRD.md and ADR.md added to /docs/ — full product and architecture decision records',
      'Docs: MASTER_BLUEPRINT.md table formatting improved',
    ],
    'ur': [
      'گہرا آڈٹ: 8 نئے Dart لنٹ قوانین شامل کیے گئے (حفاظتی توجہ)',
      'کوڈ درست: فائل صفائی اب sync API استعمال کرتی ہے',
      'دستاویزات: /docs/ میں PRD.md اور ADR.md شامل کیے گئے',
    ],
    'ar': [
      'تدقيق معمّق: إضافة 8 قواعد Dart جديدة مركّزة على الأمان',
      'إصلاح: تنظيف الملفات يستخدم الآن File API المتزامن',
      'توثيق: إضافة PRD.md وADR.md إلى مجلد /docs/',
    ],
  },
  '2.2.8': {
    'en': [
      'Fixed: WhatsApp chooser now correctly detects which apps are installed — tapping Business or Personal opens the right app every time',
      'Fixed: WhatsApp on single-variant devices no longer shows a chooser that silently fails',
      'Updated: Flutter 3.44.0 + latest dependency upgrades',
      'Security: Web App Check CI gate is now a hard failure (not just a warning)',
      'Build: google-services Gradle plugin updated to 4.4.2',
    ],
    'ur': [
      'درست کیا: واٹس ایپ چوزر اب درست طریقے سے انسٹال شدہ ایپس کا پتہ لگاتا ہے — بزنس یا ذاتی ہر بار درست کھلتا ہے',
      'درست کیا: صرف ایک ورژن انسٹال ہونے پر چوزر ظاہر نہیں ہوتا',
      'اپڈیٹ: Flutter 3.44.0 اور تازہ ترین انحصاریات',
      'سیکیورٹی: Web App Check CI گیٹ اب سخت ناکامی ہے',
    ],
    'ar': [
      'إصلاح: منتقي واتساب يكتشف الآن التطبيقات المثبتة بشكل صحيح — الضغط على العمل أو الشخصي يفتح التطبيق الصحيح في كل مرة',
      'إصلاح: لا يظهر منتقي واتساب على أجهزة ذات إصدار واحد',
      'تحديث: Flutter 3.44.0 وأحدث التبعيات',
      'أمان: بوابة CI لـ App Check الويب أصبحت فشلاً صارماً',
    ],
  },
  '2.2.7': {
    'en': [
      'Fixed: admin bulk transfer now shows a confirmation dialog before committing',
      'Fixed: filter changes in the All Jobs screen now clear multi-selection',
      'Fixed: job limit note only shown when 150-record cap is actually hit',
      'Fixed: tech transfer button hidden for jobs in a locked period',
      'Improved: WhatsNew dialog now skips display for governance-only version bumps',
      'Improved: WhatsNew dialog uses theme-adaptive colors (no hardcoded white)',
      'Pre-commit hook: governance-only commits no longer trigger a version bump',
      'CI: added gates for _changelog completeness, Colors.white, and App Check key',
      'Security: transfer approve/reject now use atomic Firestore transactions',
      'Fix: ApprovalConfig.toMap() no longer leaks FieldValue into the model layer',
      'Fix: phone input strips all leading zeros (not just one)',
      'Fix: phone input adds autofill hints for password managers',
      'CI: removed dead "Resolve firebase_options.dart" step from build-debug job',
    ],
    'ur': [
      'درست کیا: بلک ٹرانسفر سے پہلے تصدیقی ڈائیلاگ شامل',
      'درست کیا: فلٹر بدلنے پر ملٹی سیلیکشن صاف ہو جاتی ہے',
      'درست کیا: جاب لمٹ نوٹ صرف اس وقت دکھائی دیتا ہے جب 150 کی حد پہنچے',
      'درست کیا: بند پیریڈ کی جابز پر ٹرانسفر بٹن چھپا دیا گیا',
      'بہتری: "نیا کیا ہے" ڈائیلاگ صرف اصل اپڈیٹ پر دکھائی دیتا ہے',
      'بہتری: ڈائیلاگ کے رنگ تھیم کے مطابق ڈھلتے ہیں',
      'بہتری: گورننس کمٹ پر ورژن نمبر نہیں بڑھتا',
      'سیکیورٹی: ٹرانسفر منظوری/مسترد اب محفوظ Firestore ٹرانزیکشن استعمال کرتے ہیں',
    ],
    'ar': [
      'إصلاح: إضافة حوار تأكيد قبل تنفيذ النقل الجماعي',
      'إصلاح: تغيير الفلتر يمسح التحديد المتعدد تلقائياً',
      'إصلاح: ملاحظة حد المهام تظهر فقط عند بلوغ 150 سجلاً',
      'إصلاح: إخفاء زر النقل للمهام في الفترة المقفلة',
      'تحسين: حوار "ما الجديد" يظهر فقط عند تحديثات حقيقية',
      'تحسين: ألوان الحوار تتكيف مع قالب التطبيق',
      'تحسين: الإيداعات الإدارية لا تسبب زيادة رقم الإصدار',
      'أمان: الموافقة/الرفض على النقل تستخدم معاملات Firestore الآمنة',
    ],
  },
  '2.2.5': {
    'en': [
      'Country code picker on all phone number fields — KSA pre-selected, 95+ countries, E.164 normalisation',
      'Search now covers phone number and job ID in approvals, all-jobs, and history screens',
      'Technician transfer request button added to job detail screen — request, cancel, or direct-transfer',
      'WhatsApp numbers normalised automatically — local KSA numbers (05XX…) now open correctly',
      'WhatsApp chooser labels now translated in Arabic and Urdu',
      'CI now builds an Android App Bundle (AAB) for Play Store submissions',
    ],
    'ur': [
      'تمام فون نمبر خانوں میں ملک کوڈ منتخب کریں — سعودی عرب پہلے سے منتخب، 95+ ممالک',
      'فون نمبر اور جاب ID سے تلاش — اپروولز، تمام جابز اور تاریخ اسکرین میں',
      'جاب ڈیٹیل اسکرین پر تکنیشن ٹرانسفر درخواست بٹن — درخواست دیں، منسوخ کریں یا براہ راست منتقل کریں',
      'واٹس ایپ نمبر خودکار درست — مقامی کے ایس اے نمبر (05XX…) اب درست کھلتے ہیں',
      'واٹس ایپ چوزر لیبل اردو اور عربی میں ترجمہ شدہ',
      'CI اب Play Store کے لیے Android App Bundle (AAB) بناتا ہے',
    ],
    'ar': [
      'منتقي رمز الدولة في جميع حقول الهاتف — المملكة العربية السعودية محددة مسبقاً، 95+ دولة',
      'البحث يشمل الآن رقم الهاتف ومعرّف المهمة في شاشات الموافقات والمهام والسجل',
      'زر طلب نقل المهمة في شاشة تفاصيل المهمة — اطلب أو ألغِ أو انقل مباشرةً',
      'تطبيع أرقام واتساب تلقائياً — الأرقام المحلية السعودية (05XX…) تُفتح بشكل صحيح الآن',
      'تسميات اختيار واتساب مترجمة للعربية والأردية',
      'CI يبني الآن Android App Bundle (AAB) لمتجر Play',
    ],
  },
  '2.2.4': {
    'en': [
      'What\'s New dialog added — shown once per update with feature list in English, Urdu, and Arabic',
      'Governance: CI now enforces that MASTER_BLUEPRINT version matches pubspec.yaml',
      'CI/CD coverage threshold raised from 60% to 80%',
    ],
    'ur': [
      '"نیا کیا ہے" ڈائیلاگ شامل — ہر اپڈیٹ پر ایک بار اردو، انگریزی اور عربی میں',
      'گورننس: CI اب یقینی بناتا ہے کہ MASTER_BLUEPRINT ورژن pubspec.yaml سے مطابقت رکھے',
      'CI کوریج کی حد 60% سے بڑھا کر 80% کر دی گئی',
    ],
    'ar': [
      'إضافة مربع حوار "ما الجديد" — يظهر مرة واحدة عند كل تحديث بالعربية والأردية والإنجليزية',
      'الحوكمة: يتحقق CI الآن من تطابق إصدار MASTER_BLUEPRINT مع pubspec.yaml',
      'رُفع حد التغطية في CI من 60% إلى 80%',
    ],
  },
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

    // WND-002: skip silently if this version has no changelog entry.
    // Governance-only bumps produce phantom versions with no user-facing content.
    if (!_changelog.containsKey(info.version)) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(AppConstants.lastSeenVersionKey) ?? '';

    if (lastSeen == currentVersion) return;

    if (!context.mounted) return;

    // WND-003: persist AFTER the dialog is shown (not before) so a background
    // event cannot mark the dialog as seen without it actually displaying.
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsNewDialog(versionName: info.version),
    );

    // Dialog was shown (or dismissed) — mark this version as seen.
    await prefs.setString(AppConstants.lastSeenVersionKey, currentVersion);
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
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
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
                    color: cs.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.new_releases_rounded,
                    color: cs.onPrimary,
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
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'v$versionName',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.onPrimary),
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
      final items = localeMap[lang] ?? localeMap['en'] ?? const <String>[];
      if (items.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const Divider(height: 24));
      }

      widgets.add(_VersionSection(version: version, items: items));
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
    return keys.take(5).toList();
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
                  padding: const EdgeInsetsDirectional.only(top: 5, end: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                  ),
                ),
                Expanded(child: Text(item, style: tt.bodySmall)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
