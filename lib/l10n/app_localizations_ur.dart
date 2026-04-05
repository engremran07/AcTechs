// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'ایئر کنڈیشنر تکنیکی ماہرین';

  @override
  String get techMgmtSystem => 'ٹیکنیشن مینجمنٹ سسٹم';

  @override
  String get signIn => 'سائن ان';

  @override
  String get signOut => 'سائن آؤٹ';

  @override
  String get signOutConfirm => 'کیا آپ واقعی سائن آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get rememberMe => 'مجھے یاد رکھیں';

  @override
  String get enterEmail => 'براہ کرم ای میل درج کریں';

  @override
  String get enterValidEmail => 'براہ کرم درست ای میل درج کریں';

  @override
  String get enterValidPhone => 'براہ کرم درست فون نمبر درج کریں';

  @override
  String get enterPassword => 'براہ کرم پاس ورڈ درج کریں';

  @override
  String get required => 'ضروری ہے';

  @override
  String get invalidEmail => 'غلط ای میل';

  @override
  String minChars(int count) {
    return 'کم از کم $count حروف';
  }

  @override
  String get technician => 'ٹیکنیشن';

  @override
  String get admin => 'ایڈمن';

  @override
  String get administrator => 'ایڈمنسٹریٹر';

  @override
  String get home => 'ہوم';

  @override
  String get jobs => 'کام';

  @override
  String get expenses => 'اخراجات';

  @override
  String get profile => 'پروفائل';

  @override
  String get approvals => 'منظوریاں';

  @override
  String get sharedInstallApprovalRequired => 'شیئرڈ انسٹال منظوری';

  @override
  String get enforceMinimumBuild => 'کم از کم بلڈ نافذ کریں';

  @override
  String get minimumSupportedBuild => 'کم از کم سپورٹڈ بلڈ';

  @override
  String get lockRecordsBefore => 'اس تاریخ سے پہلے ریکارڈ لاک کریں';

  @override
  String get noPeriodLock => 'ابھی کوئی پیریڈ لاک فعال نہیں ہے۔';

  @override
  String get clearPeriodLock => 'پیریڈ لاک ختم کریں';

  @override
  String get lockedPeriodDescription =>
      'اس سے پرانے ریکارڈ بن نہیں سکیں گے، تبدیل نہیں ہوں گے، منظور یا مسترد نہیں ہوں گے، اور حذف نہیں ہوں گے۔';

  @override
  String get analytics => 'تجزیات';

  @override
  String get team => 'ٹیم';

  @override
  String get export => 'ایکسپورٹ';

  @override
  String get submit => 'جمع کریں';

  @override
  String get submitForApproval => 'منظوری کے لیے جمع کریں';

  @override
  String get submitting => 'جمع ہو رہا ہے...';

  @override
  String get approve => 'منظور کریں';

  @override
  String get reject => 'مسترد کریں';

  @override
  String get today => 'آج';

  @override
  String get thisMonth => 'اس مہینے';

  @override
  String get pending => 'زیر التوا';

  @override
  String get approved => 'منظور شدہ';

  @override
  String get rejected => 'مسترد';

  @override
  String get invoiceNumber => 'انوائس نمبر';

  @override
  String get clientName => 'کلائنٹ کا نام';

  @override
  String get clientNameOptional => 'کلائنٹ کا نام (اختیاری)';

  @override
  String get clientContact => 'کلائنٹ کا رابطہ';

  @override
  String get clientPhone => 'کلائنٹ فون نمبر';

  @override
  String get acUnits => 'اے سی یونٹس';

  @override
  String get addUnit => 'یونٹ شامل کریں';

  @override
  String get unitType => 'قسم';

  @override
  String get quantity => 'تعداد';

  @override
  String get expenseAmount => 'خرچے کی رقم';

  @override
  String get expenseNote => 'خرچے کی تفصیل';

  @override
  String get adminNote => 'ایڈمن نوٹ';

  @override
  String get rejectReason => 'مسترد کرنے کی وجہ';

  @override
  String get noJobsYet => 'ابھی تک کوئی کام جمع نہیں ہوا';

  @override
  String get noJobsToday => 'آج کوئی کام جمع نہیں ہوا';

  @override
  String get noMatchingJobs => 'کوئی مماثل کام نہیں';

  @override
  String get noApprovals => 'کوئی زیر التوا منظوری نہیں';

  @override
  String get noMatchingApprovals => 'کوئی مماثل منظوری نہیں';

  @override
  String get allCaughtUp => 'سب مکمل!';

  @override
  String get todaysJobs => 'آج کے کام';

  @override
  String get totalJobs => 'کل کام';

  @override
  String get pendingApprovals => 'زیر التوا منظوریاں';

  @override
  String get approvedJobs => 'منظور شدہ کام';

  @override
  String get rejectedJobs => 'مسترد شدہ کام';

  @override
  String get totalExpenses => 'کل اخراجات';

  @override
  String get teamMembers => 'ٹیم ممبرز';

  @override
  String get activeMembers => 'فعال ممبرز';

  @override
  String get jobSubmitted =>
      'کام کامیابی سے جمع ہو گیا! ایڈمن کی منظوری کا انتظار ہے۔';

  @override
  String get jobSaved => 'اندراج کامیابی سے شامل ہو گیا۔';

  @override
  String get jobApproved => 'کام منظور ہو گیا!';

  @override
  String get jobRejected => 'کام آپ کے تبصرے کے ساتھ واپس بھیج دیا گیا۔';

  @override
  String get couldNotApprove => 'منظوری نہیں ہو سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get couldNotReject => 'مسترد نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String bulkApproveSuccess(int count) {
    return '$count کام منظور ہو گئے!';
  }

  @override
  String bulkRejectSuccess(int count) {
    return '$count کام مسترد ہو گئے۔';
  }

  @override
  String get bulkApproveFailed => 'بلک منظوری ناکام۔ دوبارہ کوشش کریں۔';

  @override
  String get bulkRejectFailed => 'بلک مسترد ناکام۔ دوبارہ کوشش کریں۔';

  @override
  String get rejectSelectedJobs => 'منتخب کام مسترد کریں';

  @override
  String get rejectAll => 'سب مسترد کریں';

  @override
  String get rejectJob => 'کام مسترد کریں';

  @override
  String exportSuccess(int count) {
    return 'ایکسپورٹ تیار! $count کام ایکسل میں بھیجے گئے۔';
  }

  @override
  String get exportFailed => 'ایکسپورٹ فائل نہیں بن سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get noJobsForPeriod =>
      'اس مدت کے لیے کوئی کام نہیں ملا۔ مختلف تاریخ منتخب کریں۔';

  @override
  String get exportPdf => 'PDF ایکسپورٹ';

  @override
  String get exportExcel => 'ایکسل میں ایکسپورٹ';

  @override
  String get language => 'زبان';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get arabic => 'العربية';

  @override
  String get settings => 'سیٹنگز';

  @override
  String get offline => 'آف لائن';

  @override
  String get syncing => 'سنک ہو رہا ہے...';

  @override
  String get jobHistory => 'کام کی تاریخ';

  @override
  String get submitJob => 'کام جمع کریں';

  @override
  String get submitInvoice => 'انوائس جمع کریں';

  @override
  String get dashboard => 'ڈیش بورڈ';

  @override
  String get adminPanel => 'ایڈمن پینل';

  @override
  String get welcomeBack => 'خوش آمدید،';

  @override
  String get selectDate => 'تاریخ منتخب کریں';

  @override
  String get tapToChange => 'تبدیل کرنے کے لیے ٹیپ کریں';

  @override
  String get invoiceDetails => 'انوائس کی تفصیلات';

  @override
  String get acServices => 'اے سی خدمات';

  @override
  String get serviceType => 'خدمت کی قسم';

  @override
  String get add => 'شامل کریں';

  @override
  String get additionalCharges => 'اضافی چارجز';

  @override
  String get acOutdoorBracket => 'اے سی آؤٹ ڈور بریکٹ';

  @override
  String get bracketSubtitle => 'آؤٹ ڈور یونٹ لگانے کے لیے بریکٹ';

  @override
  String get bracketCharge => 'بریکٹ چارج (ریال)';

  @override
  String get deliveryCharge => 'ڈیلیوری چارج';

  @override
  String get deliverySubtitle => 'کسٹمر کا مقام 50 کلومیٹر سے زیادہ دور';

  @override
  String get deliveryChargeAmount => 'ڈیلیوری چارج (ریال)';

  @override
  String get locationNote => 'مقام / نوٹ (اختیاری)';

  @override
  String get addServiceFirst =>
      'جمع کرنے سے پہلے کم از کم ایک اے سی خدمت شامل کریں۔';

  @override
  String get cancel => 'منسوخ';

  @override
  String get confirm => 'تصدیق';

  @override
  String get confirmImport => 'امپورٹ کی تصدیق';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get delete => 'حذف کریں';

  @override
  String get search => 'تلاش';

  @override
  String get filter => 'فلٹر';

  @override
  String get all => 'سب';

  @override
  String get activate => 'فعال کریں';

  @override
  String get deactivate => 'غیر فعال کریں';

  @override
  String get totalUnits => 'کل یونٹس';

  @override
  String get date => 'تاریخ';

  @override
  String get appearance => 'ظاہری شکل';

  @override
  String get theme => 'تھیم';

  @override
  String get themeAuto => 'آٹو';

  @override
  String get themeAutoDesc => 'سسٹم ڈارک/لائٹ سیٹنگ کے مطابق';

  @override
  String get themeDark => 'ڈارک';

  @override
  String get themeDarkDesc => 'آرکٹک ڈارک — آنکھوں کے لیے آسان';

  @override
  String get themeLight => 'لائٹ';

  @override
  String get themeLightDesc => 'صاف اور روشن — باہری استعمال کے لیے';

  @override
  String get themeHighContrast => 'ہائی کنٹراسٹ';

  @override
  String get themeHighContrastDesc => 'زیادہ سے زیادہ پڑھنے کی صلاحیت';

  @override
  String get about => 'تعارف';

  @override
  String get version => 'ورژن';

  @override
  String get company => 'کمپنی';

  @override
  String get companyBranding => 'کمپنی برانڈنگ';

  @override
  String get region => 'خطہ';

  @override
  String get pakistan => 'پاکستان';

  @override
  String get saudiArabia => 'سعودی عرب';

  @override
  String get call => 'کال';

  @override
  String get whatsApp => 'واٹس ایپ';

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیر فعال';

  @override
  String get total => 'کل';

  @override
  String get noTeamMembers => 'ابھی تک کوئی ٹیم ممبر نہیں';

  @override
  String get noMatchingMembers => 'کوئی مماثل ٹیم ممبر نہیں';

  @override
  String get searchByNameOrEmail => 'نام یا ای میل سے تلاش کریں...';

  @override
  String get addTechnician => 'ٹیکنیشن شامل کریں';

  @override
  String get editTechnician => 'ٹیکنیشن میں ترمیم';

  @override
  String get deleteTechnician => 'ٹیکنیشن حذف کریں';

  @override
  String deleteConfirm(String name) {
    return 'کیا آپ واقعی $name کو حذف کرنا چاہتے ہیں؟';
  }

  @override
  String get deleteWarning => 'یہ عمل واپس نہیں ہو سکتا۔';

  @override
  String get name => 'نام';

  @override
  String get role => 'کردار';

  @override
  String get userCreated => 'صارف کامیابی سے بنایا گیا!';

  @override
  String get userUpdated => 'صارف کامیابی سے اپ ڈیٹ ہو گیا!';

  @override
  String get userDeleted => 'صارف کامیابی سے محفوظ کر کے غیر فعال کر دیا گیا!';

  @override
  String get usersActivated => 'صارفین فعال ہو گئے';

  @override
  String get usersDeactivated => 'صارفین غیر فعال ہو گئے';

  @override
  String get bulkActivate => 'منتخب کو فعال کریں';

  @override
  String get bulkDeactivate => 'منتخب کو غیر فعال کریں';

  @override
  String get bulkDelete => 'منتخب کو حذف کریں';

  @override
  String selectedCount(int count) {
    return '$count منتخب';
  }

  @override
  String get inOut => 'ان / آؤٹ';

  @override
  String get monthlySummary => 'ماہانہ خلاصہ';

  @override
  String get todaysInOut => 'آج کا ان / آؤٹ';

  @override
  String get todaysEntries => 'آج کی اندراجات';

  @override
  String get noEntriesToday => 'آج کوئی اندراج نہیں';

  @override
  String get addFirstEntry => 'اوپر اپنا پہلا ان یا آؤٹ شامل کریں';

  @override
  String get inEarned => 'ان (کمایا)';

  @override
  String get outSpent => 'آؤٹ (خرچ)';

  @override
  String get category => 'زمرہ';

  @override
  String get amountSar => 'رقم (ریال)';

  @override
  String get remarksOptional => 'ریمارکس (اختیاری)';

  @override
  String get saving => 'محفوظ ہو رہا ہے...';

  @override
  String get addEarning => 'کمائی شامل کریں';

  @override
  String get addExpense => 'خرچہ شامل کریں';

  @override
  String get enterAmount => 'رقم درج کریں۔';

  @override
  String get enterValidAmount => 'درست مثبت رقم درج کریں۔';

  @override
  String get earned => 'ان';

  @override
  String get spent => 'آؤٹ';

  @override
  String get profit => 'منافع';

  @override
  String get loss => 'نقصان';

  @override
  String get newestFirst => 'نئے پہلے';

  @override
  String get oldestFirst => 'پرانے پہلے';

  @override
  String get copyInvoice => 'انوائس نمبر کاپی کریں';

  @override
  String get viewInHistory => 'تاریخ میں دیکھیں';

  @override
  String get invoiceCopied => 'انوائس نمبر کاپی ہو گیا!';

  @override
  String get newJob => 'نیا کام';

  @override
  String get submitAJob => 'کام جمع کریں';

  @override
  String get sharedInstall => 'شیئرڈ انسٹال';

  @override
  String get sharedInstallHint =>
      'جب ایک ہی انوائس کئی ٹیکنیشنز میں تقسیم ہو تو اسے فعال کریں۔';

  @override
  String get sharedInstallMixHint =>
      'انوائس کے کل یونٹس قسم کے مطابق درج کریں۔ ہر ٹیکنیشن اپنی مرضی کے مطابق اپنی یونٹ شیئر درج کرے گا۔ صرف ڈیلیوری برابر تقسیم ہوگی۔';

  @override
  String get sharedInvoiceTotalUnits => 'انوائس کے کل یونٹس';

  @override
  String get sharedInstallLimitError =>
      'آپ کے درج کردہ یونٹس انوائس کے کل یونٹس سے زیادہ ہیں۔';

  @override
  String get sharedInvoiceSplitUnits => 'انوائس سپلٹ یونٹس';

  @override
  String get sharedInvoiceWindowUnits => 'انوائس ونڈو یونٹس';

  @override
  String get sharedInvoiceFreestandingUnits => 'انوائس اسٹینڈنگ یونٹس';

  @override
  String get sharedTeamSize => 'مشترکہ ٹیم کی تعداد';

  @override
  String get sharedInvoiceDeliveryAmount => 'کل ڈیلیوری چارج (انوائس)';

  @override
  String get sharedDeliverySplitHint =>
      'یہ ڈیلیوری رقم مشترکہ ٹیم میں برابر تقسیم ہوگی۔';

  @override
  String get sharedDeliverySplitInvalid =>
      'مشترکہ ٹیم کی تعداد درج کریں تاکہ ڈیلیوری برابر تقسیم ہو سکے۔';

  @override
  String get invoiceConflictNeedsReview =>
      'یہ انوائس کسی دوسری کمپنی میں بھی موجود ہے۔ منظوری سے پہلے جائزہ لیں۔';

  @override
  String invoiceConflictCompaniesLabel(String companies) {
    return 'متصادم کمپنیاں: $companies';
  }

  @override
  String get splits => 'اسپلٹ';

  @override
  String get windowAc => 'ونڈو';

  @override
  String get standing => 'اسٹینڈنگ';

  @override
  String get cassette => 'کیسیٹ';

  @override
  String get uninstalls => 'ان انسٹال';

  @override
  String get uninstallSplit => 'ان انسٹال سپلٹ';

  @override
  String get uninstallWindow => 'ان انسٹال ونڈو';

  @override
  String get uninstallStanding => 'ان انسٹال اسٹینڈنگ';

  @override
  String get jobStatus => 'کام کی حالت';

  @override
  String get jobsPerTechnician => 'فی ٹیکنیشن کام';

  @override
  String get technicians => 'ٹیکنیشنز';

  @override
  String get recentPending => 'حالیہ زیر التوا';

  @override
  String get invoice => 'انوائس';

  @override
  String get client => 'کلائنٹ';

  @override
  String get units => 'یونٹس';

  @override
  String get expensesSar => 'اخراجات (ریال)';

  @override
  String get status => 'حالت';

  @override
  String get sort => 'ترتیب';

  @override
  String get installations => 'تنصیبات';

  @override
  String get earningsIn => 'آمدنی (ان)';

  @override
  String get expensesOut => 'اخراجات (آؤٹ)';

  @override
  String get netProfit => 'خالص منافع';

  @override
  String get earningsBreakdown => 'آمدنی کی تفصیل';

  @override
  String get expensesBreakdown => 'اخراجات کی تفصیل';

  @override
  String get installationsByType => 'قسم کے مطابق تنصیبات';

  @override
  String get january => 'جنوری';

  @override
  String get february => 'فروری';

  @override
  String get march => 'مارچ';

  @override
  String get april => 'اپریل';

  @override
  String get may => 'مئی';

  @override
  String get june => 'جون';

  @override
  String get july => 'جولائی';

  @override
  String get august => 'اگست';

  @override
  String get september => 'ستمبر';

  @override
  String get october => 'اکتوبر';

  @override
  String get november => 'نومبر';

  @override
  String get december => 'دسمبر';

  @override
  String get history => 'تاریخ';

  @override
  String get searchByClientOrInvoice => 'کلائنٹ یا انوائس سے تلاش کریں...';

  @override
  String get searchByTechClientInvoice =>
      'ٹیکنیشن، کلائنٹ، یا انوائس سے تلاش کریں...';

  @override
  String get exportAsPdf => 'PDF کے طور پر برآمد';

  @override
  String nUnits(int count) {
    return '$count یونٹس';
  }

  @override
  String activeOfTotal(int active, int total) {
    return '$active / $total فعال';
  }

  @override
  String get exportToPdf => 'PDF میں برآمد';

  @override
  String get exportToExcel => 'ایکسل میں برآمد';

  @override
  String get reportPreset => 'رپورٹ پری سیٹ';

  @override
  String get byTechnician => 'ٹیکنیشن کے مطابق';

  @override
  String get uninstallRateBreakdown => 'ان انسٹال ریٹ بریک ڈاؤن';

  @override
  String exportReady(int count) {
    return 'برآمد تیار! $count جابز ایکسل میں برآمد ہوئیں۔';
  }

  @override
  String get couldNotExport => 'برآمد فائل نہیں بن سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get appSubtitle => 'ٹیکنیشن مینیجمنٹ سسٹم';

  @override
  String get resetPassword => 'پاس ورڈ ری سیٹ';

  @override
  String passwordResetSent(String email) {
    return '$email پر پاس ورڈ ری سیٹ ای میل بھیج دی گئی';
  }

  @override
  String confirmDeleteUser(String name) {
    return '$name کو غیر فعال کیا جائے گا اور وہ سائن ان نہیں کر سکیں گے۔ جاری رکھیں؟';
  }

  @override
  String get addMoreEarning => '+ مزید کمائی شامل کریں';

  @override
  String get addMoreExpense => '+ مزید خرچہ شامل کریں';

  @override
  String get companies => 'کمپنیاں';

  @override
  String get addCompany => 'کمپنی شامل کریں';

  @override
  String get editCompany => 'کمپنی میں ترمیم';

  @override
  String get companyName => 'کمپنی کا نام';

  @override
  String get ambiguousCompanyName => 'امبیگوس';

  @override
  String get companyPhoneNumber => 'کمپنی کا فون نمبر';

  @override
  String get invoicePrefix => 'انوائس پریفکس';

  @override
  String get invoiceSuffix => 'انوائس نمبر';

  @override
  String get selectCompany => 'کمپنی منتخب کریں (اختیاری)';

  @override
  String get noCompany => 'کوئی کمپنی نہیں';

  @override
  String get noCompaniesYet => 'ابھی تک کوئی کمپنی شامل نہیں کی گئی';

  @override
  String get editProfile => 'پروفائل تبدیل کریں';

  @override
  String get changeYourName => 'اپنا نام تبدیل کریں';

  @override
  String get profileUpdated => 'پروفائل کامیابی سے اپ ڈیٹ ہو گیا!';

  @override
  String get companyCreated => 'کمپنی کامیابی سے بن گئی!';

  @override
  String get companyUpdated => 'کمپنی کامیابی سے اپ ڈیٹ ہو گئی!';

  @override
  String get companyActivated => 'کمپنی فعال ہو گئی';

  @override
  String get companyDeactivated => 'کمپنی غیر فعال ہو گئی';

  @override
  String get manageLogoAndBranding => 'لوگو اور برانڈنگ مینیج کریں';

  @override
  String get editOwnCompanyBranding => 'AC Techs برانڈنگ تبدیل کریں';

  @override
  String get manageClientCompanyBranding => 'کلائنٹ کمپنی برانڈنگ مینیج کریں';

  @override
  String get ownCompanyBrandingUpdated =>
      'AC Techs برانڈنگ کامیابی سے اپ ڈیٹ ہو گئی!';

  @override
  String get workExpenses => 'کام کے اخراجات';

  @override
  String get homeExpenses => 'گھر کے اخراجات';

  @override
  String get importHistoryData => 'پرانا ڈیٹا امپورٹ کریں';

  @override
  String get importHistoryDataSubtitle =>
      'ٹیکنیشن آئی ڈی/ای میل/نام کے مطابق پچھلا انسٹالیشن ڈیٹا امپورٹ کرنے کے لیے ایک یا زیادہ ایکسل فائلیں اپ لوڈ کریں۔';

  @override
  String get uploadExcel => 'ایکسل اپ لوڈ کریں';

  @override
  String get deleteSourceAfterImport =>
      'امپورٹ کے بعد سورس فائل حذف کریں (جہاں ممکن ہو)';

  @override
  String get importInProgress => 'امپورٹ ہو رہا ہے...';

  @override
  String get importNoFileSelected => 'کوئی فائل منتخب نہیں کی گئی۔';

  @override
  String get importFailedNoRows => 'امپورٹ کے لیے کوئی درست قطار نہیں ملی۔';

  @override
  String importCompletedCount(int count) {
    return '$count قطاریں امپورٹ ہوئیں';
  }

  @override
  String importSkippedCount(int count) {
    return '$count قطاریں اسکپ ہوئیں';
  }

  @override
  String importUnresolvedTechRows(int count) {
    return '$count قطاریں اسکپ ہوئیں: ٹیکنیشن نہیں ملا';
  }

  @override
  String importRowsWithoutTechName(int count) {
    return '$count قطاروں میں ٹیکنیشن کا نام موجود نہیں';
  }

  @override
  String importUniqueTechNamesCount(int count) {
    return '$count منفرد ٹیکنیشن نام ملے';
  }

  @override
  String get importTopTechNamesLabel => 'زیادہ آنے والے ٹیکنیشن نام';

  @override
  String get importTargetTechnician => 'ٹارگٹ ٹیکنیشن';

  @override
  String get importTargetTechnicianRequired =>
      'وہ ٹیکنیشن منتخب کریں جس کے اکاؤنٹ میں یہ تاریخی ڈیٹا ڈالنا ہے۔';

  @override
  String get importTechnicianKeyword => 'سورس ٹیکنیشن فلٹر';

  @override
  String get importTechnicianKeywordHint => 'مثال: نام، ای میل، یا uid';

  @override
  String get importTechnicianKeywordHelp =>
      'صرف وہ قطاریں امپورٹ ہوں گی جن میں ٹیکنیشن کا نام، ای میل، یا آئی ڈی اس متن سے میچ کرے۔';

  @override
  String get importKeywordRequired =>
      'غلطی سے بڑی درآمد سے بچنے کے لیے برائے کرم ٹیکنیشن کی طرف سے فلٹر کریں۔';

  @override
  String get importBundledTemplates => 'بنڈل شدہ تاریخی ٹیمپلیٹس امپورٹ کریں';

  @override
  String get importBundledTemplatesMissing =>
      'ایپ پیکیج میں کوئی بنڈل شدہ تاریخی ٹیمپلیٹ نہیں ملا۔';

  @override
  String get dangerZone => 'خطرناک علاقہ';

  @override
  String get flushDatabase => 'ڈیٹا بیس فلش کریں';

  @override
  String get flushDatabaseSubtitle =>
      'تمام ڈیٹا صاف کر کے نئے سرے سے شروع کریں';

  @override
  String get flushScope => 'فلش اسکوپ';

  @override
  String get flushAllData => 'تمام ڈیٹا';

  @override
  String get flushOnlySelectedTechnician =>
      'صرف منتخب ٹیکنیشن کا ڈیٹا (کام اور ان/آؤٹ) فلش ہوگا۔';

  @override
  String get flushStep1Title => 'مرحلہ 1 از 2 — ارادے کی تصدیق';

  @override
  String get flushStep2Title => 'مرحلہ 2 از 2 — حتمی تصدیق';

  @override
  String get flushWarningIntro =>
      'آپ درج ذیل ڈیٹا کو مستقل طور پر حذف کرنے والے ہیں:';

  @override
  String get flushItemJobs => 'تمام کام کے ریکارڈ';

  @override
  String get flushItemExpenses => 'تمام اخراجات اور آمدنی کے ریکارڈ';

  @override
  String get flushItemCompanies => 'تمام کمپنی ریکارڈ';

  @override
  String get flushItemUsers => 'تمام غیر ایڈمن صارف اکاؤنٹس';

  @override
  String get flushItemUsersOptional => 'غیر ایڈمن صارف اکاؤنٹس (اختیاری)';

  @override
  String get flushAdminKept => 'ایڈمن اکاؤنٹس محفوظ رہیں گے۔';

  @override
  String flushProceedIn(int seconds) {
    return '$seconds سیکنڈ میں آگے بڑھیں';
  }

  @override
  String get flushProceed => 'مرحلہ 2 کی طرف بڑھیں';

  @override
  String get flushEnterPassword => 'تصدیق کے لیے اپنا ایڈمن پاس ورڈ درج کریں';

  @override
  String flushConfirmIn(int seconds) {
    return '$seconds سیکنڈ میں تصدیق کریں';
  }

  @override
  String get flushConfirm => 'ڈیٹا بیس فلش کریں';

  @override
  String get flushInProgress => 'ڈیٹا بیس فلش ہو رہی ہے…';

  @override
  String get flushDeleteUsersOption => 'ٹیکنیشن/یوزر اکاؤنٹس بھی حذف کریں';

  @override
  String get flushDeleteUsersHelp =>
      'فعال کرنے پر تمام غیر ایڈمن صارف ڈاکیومنٹس مستقل طور پر حذف ہو جائیں گے۔';

  @override
  String get flushDeleteUsersEnabledWarning =>
      'یوزر حذف کرنا فعال ہے۔ اس فلش کے دوران تمام ٹیکنیشن اور دیگر غیر ایڈمن صارف ریکارڈ مستقل طور پر حذف ہو جائیں گے۔';

  @override
  String get flushSuccess => 'ڈیٹا بیس فلش ہو گئی۔ نئے سرے سے شروع ہو رہے ہیں۔';

  @override
  String get flushFailed =>
      'فلش ناکام ہوا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get flushWrongPassword => 'غلط پاس ورڈ۔ دوبارہ کوشش کریں۔';

  @override
  String get currentBuild => 'موجودہ بلڈ';

  @override
  String get updateRequiredTitle => 'اپ ڈیٹ ضروری ہے';

  @override
  String updateRequiredBody(int build) {
    return 'آپ کی ایپ بلڈ ($build) اب سپورٹ نہیں ہے۔ جاری رکھنے کے لیے تازہ APK انسٹال کریں۔';
  }

  @override
  String get updateRequiredLoading => 'ایپ ورژن چیک ہو رہا ہے...';

  @override
  String get iUpdatedRefresh => 'میں نے اپ ڈیٹ کر لیا - ریفریش';

  @override
  String get catSplitAc => 'اسپلٹ اے سی';

  @override
  String get catWindowAc => 'ونڈو اے سی';

  @override
  String get catFreestandingAc => 'فری اسٹینڈنگ اے سی';

  @override
  String get catCassetteAc => 'کیسیٹ اے سی';

  @override
  String get catUninstallOldAc => 'ان انسٹالیشن (پرانا اے سی)';

  @override
  String get catFood => 'کھانا';

  @override
  String get catPetrol => 'پٹرول';

  @override
  String get catPipes => 'پائپس';

  @override
  String get catTools => 'اوزار';

  @override
  String get catTape => 'ٹیپ';

  @override
  String get catInsulation => 'انسولیشن';

  @override
  String get catGas => 'گیس';

  @override
  String get catOtherConsumables => 'دیگر سامان';

  @override
  String get catHouseRent => 'مکان کا کرایہ';

  @override
  String get catOther => 'دیگر';

  @override
  String get catInstalledBracket => 'بریکٹ لگایا';

  @override
  String get catInstalledExtraPipe => 'اضافی پائپ لگایا';

  @override
  String get catOldAcRemoval => 'پرانا اے سی اتارا';

  @override
  String get catOldAcInstallation => 'پرانا اے سی لگایا';

  @override
  String get catSoldOldAc => 'پرانا اے سی بیچا';

  @override
  String get catSoldScrap => 'کباڑ بیچا';

  @override
  String get catBreadRoti => 'روٹی / بریڈ';

  @override
  String get catMeat => 'گوشت';

  @override
  String get catChicken => 'چکن';

  @override
  String get catTea => 'چائے';

  @override
  String get catSugar => 'چینی';

  @override
  String get catRice => 'چاول';

  @override
  String get catVegetables => 'سبزیاں';

  @override
  String get catCookingOil => 'کوکنگ آئل';

  @override
  String get catMilk => 'دودھ';

  @override
  String get catSpices => 'مصالحہ جات';

  @override
  String get catOtherGroceries => 'دیگر کریانہ';

  @override
  String get passwordResetConfirmTitle => 'پاس ورڈ ری سیٹ؟';

  @override
  String passwordResetConfirmBody(String email) {
    return '$email پر ری سیٹ لنک بھیجا جائے گا۔ جاری رکھیں؟';
  }

  @override
  String get passwordResetEmailSentTitle => 'ای میل بھیج دی گئی';

  @override
  String passwordResetEmailSentBody(String email) {
    return '$email پر ری سیٹ لنک بھیج دیا گیا ہے۔\n\nبراہ کرم اپنا ان باکس چیک کریں۔ اگر چند منٹوں میں نظر نہ آئے تو اسپیم یا جنک فولڈر دیکھیں۔\n\nلنک 1 گھنٹے میں ختم ہو جائے گا۔';
  }

  @override
  String get passwordResetNetworkError =>
      'انٹرنیٹ کنکشن نہیں ہے۔ براہ کرم کنکٹ کریں اور دوبارہ کوشش کریں۔';

  @override
  String get passwordResetRateLimit =>
      'بہت زیادہ ری سیٹ درخواستیں۔ براہ کرم چند منٹ انتظار کریں اور دوبارہ کوشش کریں۔';

  @override
  String get send => 'بھیجیں';

  @override
  String get changeEmail => 'ای میل تبدیل کریں';

  @override
  String get changePassword => 'پاس ورڈ تبدیل کریں';

  @override
  String get currentPassword => 'موجودہ پاس ورڈ';

  @override
  String get newPassword => 'نیا پاس ورڈ';

  @override
  String get confirmNewPassword => 'نئے پاس ورڈ کی تصدیق';

  @override
  String get passwordsDoNotMatch => 'پاس ورڈ ایک جیسے نہیں ہیں۔';

  @override
  String get emailUpdated => 'ای میل کامیابی سے اپ ڈیٹ ہو گئی۔';

  @override
  String get emailChangeVerificationSent =>
      'تصدیقی ای میل بھیج دی گئی ہے۔ نئی ای میل کی تصدیق کے لیے ان باکس کھولیں۔';

  @override
  String get passwordUpdated => 'پاس ورڈ کامیابی سے اپ ڈیٹ ہو گیا۔';

  @override
  String get editEntry => 'اندراج میں ترمیم';

  @override
  String get entriesSaved => 'اندراجات کامیابی سے محفوظ ہو گئیں۔';

  @override
  String get entryDeleted => 'اندراج کامیابی سے حذف ہو گیا۔';

  @override
  String get entryUpdated => 'اندراج کامیابی سے اپ ڈیٹ ہو گیا۔';

  @override
  String get selectPdfDateRange => 'PDF کی تاریخ کی حد منتخب کریں';

  @override
  String get pdfDateRangeMonthOnly =>
      'براہ کرم منتخب مہینے کے اندر تاریخ کی حد منتخب کریں۔';

  @override
  String get exportTodayCompanyInvoices => 'آج کی کمپنی انوائسز PDF برآمد کریں';

  @override
  String get noInvoicesToday => 'آج کے لیے کوئی انوائس نہیں ملی۔';

  @override
  String get couldNotOpenSummary =>
      'خلاصہ اسکرین نہیں کھل سکی۔ دوبارہ کوشش کریں۔';

  @override
  String get userDataLoading =>
      'براہ کرم انتظار فرمائیں — آپ کا پروفائل لوڈ ہو رہا ہے...';

  @override
  String get couldNotSubmitJob =>
      'جمع نہیں ہو سکا۔ براہ کرم سائن آؤٹ کریں اور دوبارہ سائن ان کریں۔';

  @override
  String get invoiceSopTitle => 'انوائس SOP فلو';

  @override
  String get excelStyleEntry => 'ایکسل اسٹائل انٹری';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get invoiceSopStep1 => '1) تاریخ اور کمپنی منتخب کریں';

  @override
  String get invoiceSopStep2 => '2) انوائس، کلائنٹ اور رابطہ شامل کریں';

  @override
  String get invoiceSopStep3 => '3) اے سی یونٹس اور اضافی چارجز شامل کریں';

  @override
  String get invoiceSopStep4 => '4) ایڈمن منظوری کے لیے جمع کریں';

  @override
  String get jobsDetailsReport => 'ملازمتوں کی تفصیل رپورٹ';

  @override
  String get earningsReport => 'کمائی کی رپورٹ';

  @override
  String get expensesDetailedReport => 'اخراجات کی رپورٹ (کام اور گھر)';

  @override
  String get exportJobsAsExcel => 'ملازمتیں Excel میں نکالیں';

  @override
  String get exportJobsAsPdf => 'ملازمتیں PDF میں نکالیں';

  @override
  String get exportEarningsAsExcel => 'کمائی Excel میں نکالیں';

  @override
  String get exportEarningsAsPdf => 'کمائی PDF میں نکالیں';

  @override
  String get exportExpensesAsExcel => 'اخراجات Excel میں نکالیں';

  @override
  String get exportExpensesAsPdf => 'اخراجات PDF میں نکالیں';

  @override
  String get selectReportType => 'رپورٹ کی قسم منتخب کریں';

  @override
  String get jobsReportTitle => 'ملازمتوں کی رپورٹ';

  @override
  String get earningsReportTitle => 'کمائی کی رپورٹ';

  @override
  String get expensesReportTitle => 'اخراجات کی رپورٹ';

  @override
  String get todayEarned => 'آج کی کمائی';

  @override
  String get monthEarned => 'ماہ کی کمائی';

  @override
  String get todayWorkExpenses => 'آج کے کام کے اخراجات';

  @override
  String get todayHomeExpenses => 'آج کے گھر کے اخراجات';

  @override
  String get todayTotalExpenses => 'آج کے کل اخراجات';

  @override
  String get monthWorkExpenses => 'ماہ کے کام کے اخراجات';

  @override
  String get monthHomeExpenses => 'ماہ کے گھر کے اخراجات';

  @override
  String get monthTotalExpenses => 'ماہ کے کل اخراجات';

  @override
  String get workExpensesLabel => 'کام کے اخراجات';

  @override
  String get homeExpensesLabel => 'گھر کے اخراجات';

  @override
  String get bracketLabel => 'بریکٹ';

  @override
  String get deliveryLabel => 'ڈیلیوری';

  @override
  String get acUnitsLabel => 'AC یونٹس';

  @override
  String get unitQty => 'تعداد';

  @override
  String get dateLabel => 'تاریخ';

  @override
  String get invoiceLabel => 'انوائس';

  @override
  String get technicianLabel => 'ٹیکنیشن';

  @override
  String get technicianUidLabel => 'ٹیکنیشن UID';

  @override
  String get approverUidLabel => 'منظور کرنے والے کا UID';

  @override
  String get sharedGroup => 'شیئرڈ گروپ';

  @override
  String get approvedSharedInstalls => 'منظور شدہ شیئرڈ انسٹال';

  @override
  String get contactLabel => 'رابطہ';

  @override
  String get statusLabel => 'حالت';

  @override
  String get notesLabel => 'نوٹس';

  @override
  String get amountLabel => 'رقم';

  @override
  String get categoryLabel => 'زمرہ';

  @override
  String get itemLabel => 'سامان';

  @override
  String get totalLabel => 'کل';

  @override
  String get noEarnings => 'کوئی کمائی نہیں';

  @override
  String get noWorkExpenses => 'کوئی کام کے اخراجات نہیں';

  @override
  String get noHomeExpenses => 'کوئی گھر کے اخراجات نہیں';

  @override
  String get generateReports => 'رپورٹیں تیار کریں';

  @override
  String get acInstallations => 'اے سی تنصیب';

  @override
  String get logAcInstallations => 'اے سی تنصیب درج کریں';

  @override
  String get noInstallationsToday => 'آج کوئی تنصیب درج نہیں';

  @override
  String get noManualInstallLogsToday =>
      'آج کوئی دستی اے سی تنصیب لاگ درج نہیں کی گئی۔';

  @override
  String get manualInstallLogDescription =>
      'یہ اسکرین صرف دستی اے سی تنصیب لاگز دکھاتی ہے۔ انوائس اور شیئرڈ انسٹال جابز کی گنتی اوپر الگ دکھائی جاتی ہے۔';

  @override
  String get jobInstallationsToday => 'آج کی انسٹال جابز';

  @override
  String get manualLogsToday => 'آج کے دستی لاگز';

  @override
  String get entryDetails => 'اندراج کی تفصیل';

  @override
  String get totalOnInvoice => 'انوائس پر کل';

  @override
  String get myShare => 'میرا حصہ';

  @override
  String get splitAcLabel => 'اسپلٹ اے سی';

  @override
  String get windowAcLabel => 'ونڈو اے سی';

  @override
  String get freestandingAcLabel => 'فری اسٹینڈنگ اے سی';

  @override
  String get installationsLogged => 'تنصیب کامیابی سے درج ہو گئی۔';

  @override
  String get deleteInstallRecord => 'تنصیب ریکارڈ حذف کریں؟';

  @override
  String get unitsLabel => 'یونٹ';

  @override
  String invoiceUnitsLabel(int total) {
    return 'انوائس: $total یونٹ';
  }

  @override
  String myShareUnitsLabel(int share) {
    return 'میرا حصہ: $share یونٹ';
  }

  @override
  String get shareMustNotExceedTotal =>
      'میرا حصہ انوائس کے کل سے زیادہ نہیں ہو سکتا۔';

  @override
  String get enterAtLeastOneUnit =>
      'کم از کم ایک اے سی یونٹ کی تعداد درج کریں۔';

  @override
  String get acInstallNote => 'نوٹ (اختیاری)';

  @override
  String get companyLogo => 'کمپنی لوگو';

  @override
  String get adminAboutBuiltBy =>
      'یہ ایپ اے سی ٹیکس کے لیے بنائی اور سپورٹ کی گئی ہے۔';

  @override
  String get developedByMuhammadImran => 'محمد عمران نے تیار کیا';

  @override
  String get tapToUploadLogo => 'لوگو اپ لوڈ کرنے کے لیے ٹیپ کریں';

  @override
  String get uploadLogo => 'لوگو اپ لوڈ کریں';

  @override
  String get replaceLogo => 'لوگو تبدیل کریں';

  @override
  String get logoTooLarge =>
      'لوگو بہت بڑا ہے۔ Firestore اسٹوریج صاف رکھنے کے لیے چھوٹی تصویر استعمال کریں۔';

  @override
  String get removeLogo => 'لوگو ہٹائیں';

  @override
  String get enterValidQuantity => 'درست تعداد درج کریں۔';
}
