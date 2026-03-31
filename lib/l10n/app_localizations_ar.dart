// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'فنيين تكييف';

  @override
  String get techMgmtSystem => 'نظام إدارة الفنيين';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get enterEmail => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get enterValidEmail => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get enterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get required => 'مطلوب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String minChars(int count) {
    return 'الحد الأدنى $count أحرف';
  }

  @override
  String get technician => 'فني';

  @override
  String get admin => 'مسؤول';

  @override
  String get administrator => 'مسؤول إداري';

  @override
  String get home => 'الرئيسية';

  @override
  String get jobs => 'الأعمال';

  @override
  String get expenses => 'المصروفات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get approvals => 'الموافقات';

  @override
  String get analytics => 'التحليلات';

  @override
  String get team => 'الفريق';

  @override
  String get export => 'تصدير';

  @override
  String get submit => 'إرسال';

  @override
  String get submitForApproval => 'إرسال للموافقة';

  @override
  String get submitting => 'جارٍ الإرسال...';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get today => 'اليوم';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get approved => 'موافق عليه';

  @override
  String get rejected => 'مرفوض';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get clientName => 'اسم العميل';

  @override
  String get clientNameOptional => 'اسم العميل (اختياري)';

  @override
  String get clientContact => 'اتصال العميل';

  @override
  String get clientPhone => 'رقم هاتف العميل';

  @override
  String get acUnits => 'وحدات التكييف';

  @override
  String get addUnit => 'إضافة وحدة';

  @override
  String get unitType => 'نوع الوحدة';

  @override
  String get quantity => 'الكمية';

  @override
  String get expenseAmount => 'مبلغ المصروف';

  @override
  String get expenseNote => 'ملاحظة المصروف';

  @override
  String get adminNote => 'ملاحظة المسؤول';

  @override
  String get rejectReason => 'سبب الرفض';

  @override
  String get noJobsYet => 'لم يتم إرسال أعمال بعد';

  @override
  String get noJobsToday => 'لا توجد أعمال اليوم';

  @override
  String get noMatchingJobs => 'لا توجد أعمال مطابقة';

  @override
  String get noApprovals => 'لا توجد موافقات معلقة';

  @override
  String get noMatchingApprovals => 'لا توجد موافقات مطابقة';

  @override
  String get allCaughtUp => 'لا شيء معلق!';

  @override
  String get todaysJobs => 'أعمال اليوم';

  @override
  String get totalJobs => 'إجمالي الأعمال';

  @override
  String get pendingApprovals => 'الموافقات المعلقة';

  @override
  String get approvedJobs => 'الأعمال الموافق عليها';

  @override
  String get rejectedJobs => 'الأعمال المرفوضة';

  @override
  String get totalExpenses => 'إجمالي المصروفات';

  @override
  String get teamMembers => 'أعضاء الفريق';

  @override
  String get activeMembers => 'الأعضاء النشطون';

  @override
  String get jobSubmitted => 'تم إرسال العمل بنجاح! في انتظار موافقة المسؤول.';

  @override
  String get jobApproved => 'تمت الموافقة على العمل!';

  @override
  String get jobRejected => 'تم إرجاع العمل مع ملاحظاتك.';

  @override
  String get couldNotApprove => 'تعذرت الموافقة. حاول مرة أخرى.';

  @override
  String get couldNotReject => 'تعذر الرفض. حاول مرة أخرى.';

  @override
  String bulkApproveSuccess(int count) {
    return 'تمت الموافقة على $count عمل!';
  }

  @override
  String bulkRejectSuccess(int count) {
    return 'تم رفض $count عمل.';
  }

  @override
  String get bulkApproveFailed => 'فشلت الموافقة الجماعية. حاول مرة أخرى.';

  @override
  String get bulkRejectFailed => 'فشل الرفض الجماعي. حاول مرة أخرى.';

  @override
  String get rejectSelectedJobs => 'رفض الأعمال المحددة';

  @override
  String get rejectAll => 'رفض الكل';

  @override
  String get rejectJob => 'رفض العمل';

  @override
  String exportSuccess(int count) {
    return 'التصدير جاهز! تم تصدير $count عمل إلى Excel.';
  }

  @override
  String get exportFailed => 'تعذر إنشاء ملف التصدير. حاول مرة أخرى.';

  @override
  String get noJobsForPeriod =>
      'لا توجد أعمال لهذه الفترة. جرب نطاق تاريخ مختلف.';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير إلى Excel';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get urdu => 'اردو';

  @override
  String get arabic => 'العربية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get offline => 'غير متصل';

  @override
  String get syncing => 'جارٍ المزامنة...';

  @override
  String get jobHistory => 'سجل الأعمال';

  @override
  String get submitJob => 'إرسال عمل';

  @override
  String get submitInvoice => 'إرسال فاتورة';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get adminPanel => 'لوحة المسؤول';

  @override
  String get welcomeBack => 'مرحباً بعودتك،';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get tapToChange => 'اضغط للتغيير';

  @override
  String get invoiceDetails => 'تفاصيل الفاتورة';

  @override
  String get acServices => 'خدمات التكييف';

  @override
  String get serviceType => 'نوع الخدمة';

  @override
  String get add => 'إضافة';

  @override
  String get additionalCharges => 'رسوم إضافية';

  @override
  String get acOutdoorBracket => 'حامل الوحدة الخارجية';

  @override
  String get bracketSubtitle => 'حامل لتركيب الوحدة الخارجية';

  @override
  String get bracketCharge => 'رسوم الحامل (ريال)';

  @override
  String get deliveryCharge => 'رسوم التوصيل';

  @override
  String get deliverySubtitle => 'موقع العميل أبعد من 50 كم';

  @override
  String get deliveryChargeAmount => 'رسوم التوصيل (ريال)';

  @override
  String get locationNote => 'الموقع / ملاحظة (اختياري)';

  @override
  String get addServiceFirst => 'أضف خدمة تكييف واحدة على الأقل قبل الإرسال.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get all => 'الكل';

  @override
  String get activate => 'تفعيل';

  @override
  String get deactivate => 'تعطيل';

  @override
  String get totalUnits => 'إجمالي الوحدات';

  @override
  String get date => 'التاريخ';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeAuto => 'تلقائي';

  @override
  String get themeAutoDesc => 'اتباع إعداد النظام الداكن/الفاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeDarkDesc => 'أزرق قطبي — مريح للعين';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeLightDesc => 'نظيف ومشرق — للاستخدام الخارجي';

  @override
  String get themeHighContrast => 'تباين عالي';

  @override
  String get themeHighContrastDesc => 'أقصى درجة قراءة وحدود عريضة';

  @override
  String get about => 'حول';

  @override
  String get version => 'الإصدار';

  @override
  String get company => 'الشركة';

  @override
  String get region => 'المنطقة';

  @override
  String get saudiArabia => 'المملكة العربية السعودية';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get total => 'الإجمالي';

  @override
  String get noTeamMembers => 'لا يوجد أعضاء في الفريق بعد';

  @override
  String get noMatchingMembers => 'لا يوجد أعضاء مطابقون';

  @override
  String get searchByNameOrEmail => 'البحث بالاسم أو البريد الإلكتروني...';

  @override
  String get addTechnician => 'إضافة فني';

  @override
  String get editTechnician => 'تعديل فني';

  @override
  String get deleteTechnician => 'حذف فني';

  @override
  String deleteConfirm(String name) {
    return 'هل أنت متأكد أنك تريد حذف $name؟';
  }

  @override
  String get deleteWarning => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get name => 'الاسم';

  @override
  String get role => 'الدور';

  @override
  String get userCreated => 'تم إنشاء المستخدم بنجاح!';

  @override
  String get userUpdated => 'تم تحديث المستخدم بنجاح!';

  @override
  String get userDeleted => 'تم حذف المستخدم بنجاح!';

  @override
  String get usersActivated => 'تم تفعيل المستخدمين';

  @override
  String get usersDeactivated => 'تم تعطيل المستخدمين';

  @override
  String get bulkActivate => 'تفعيل المحددين';

  @override
  String get bulkDeactivate => 'تعطيل المحددين';

  @override
  String get bulkDelete => 'حذف المحددين';

  @override
  String selectedCount(int count) {
    return '$count محدد';
  }

  @override
  String get inOut => 'دخول / خروج';

  @override
  String get monthlySummary => 'الملخص الشهري';

  @override
  String get todaysInOut => 'دخول / خروج اليوم';

  @override
  String get todaysEntries => 'إدخالات اليوم';

  @override
  String get noEntriesToday => 'لا توجد إدخالات اليوم';

  @override
  String get addFirstEntry => 'أضف أول دخول أو خروج أعلاه';

  @override
  String get inEarned => 'دخول (مكتسب)';

  @override
  String get outSpent => 'خروج (مصروف)';

  @override
  String get category => 'الفئة';

  @override
  String get amountSar => 'المبلغ (ريال)';

  @override
  String get remarksOptional => 'ملاحظات (اختياري)';

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get addEarning => 'إضافة دخل';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get enterAmount => 'أدخل مبلغاً.';

  @override
  String get enterValidAmount => 'أدخل مبلغاً موجباً صالحاً.';

  @override
  String get earned => 'دخول';

  @override
  String get spent => 'خروج';

  @override
  String get profit => 'ربح';

  @override
  String get loss => 'خسارة';

  @override
  String get newestFirst => 'الأحدث أولاً';

  @override
  String get oldestFirst => 'الأقدم أولاً';

  @override
  String get copyInvoice => 'نسخ رقم الفاتورة';

  @override
  String get viewInHistory => 'عرض في السجل';

  @override
  String get invoiceCopied => 'تم نسخ رقم الفاتورة!';

  @override
  String get newJob => 'عمل جديد';

  @override
  String get submitAJob => 'إرسال عمل';

  @override
  String get splits => 'سبليت';

  @override
  String get windowAc => 'نافذة';

  @override
  String get standing => 'قائم';

  @override
  String get cassette => 'كاسيت';

  @override
  String get uninstalls => 'إزالة';

  @override
  String get jobStatus => 'حالة العمل';

  @override
  String get jobsPerTechnician => 'أعمال لكل فني';

  @override
  String get technicians => 'الفنيون';

  @override
  String get recentPending => 'المعلقة مؤخراً';

  @override
  String get invoice => 'فاتورة';

  @override
  String get client => 'عميل';

  @override
  String get units => 'وحدات';

  @override
  String get expensesSar => 'مصروفات (ريال)';

  @override
  String get status => 'الحالة';

  @override
  String get sort => 'ترتيب';

  @override
  String get installations => 'تركيبات';

  @override
  String get earningsIn => 'الإيرادات (دخول)';

  @override
  String get expensesOut => 'المصروفات (خروج)';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get earningsBreakdown => 'تفصيل الإيرادات';

  @override
  String get expensesBreakdown => 'تفصيل المصروفات';

  @override
  String get installationsByType => 'التركيبات حسب النوع';

  @override
  String get january => 'يناير';

  @override
  String get february => 'فبراير';

  @override
  String get march => 'مارس';

  @override
  String get april => 'أبريل';

  @override
  String get may => 'مايو';

  @override
  String get june => 'يونيو';

  @override
  String get july => 'يوليو';

  @override
  String get august => 'أغسطس';

  @override
  String get september => 'سبتمبر';

  @override
  String get october => 'أكتوبر';

  @override
  String get november => 'نوفمبر';

  @override
  String get december => 'ديسمبر';

  @override
  String get history => 'السجل';

  @override
  String get searchByClientOrInvoice => 'البحث بالعميل أو الفاتورة...';

  @override
  String get searchByTechClientInvoice =>
      'البحث بالفني أو العميل أو الفاتورة...';

  @override
  String get exportAsPdf => 'تصدير كـ PDF';

  @override
  String nUnits(int count) {
    return '$count وحدات';
  }

  @override
  String activeOfTotal(int active, int total) {
    return '$active / $total نشط';
  }

  @override
  String get exportToPdf => 'تصدير إلى PDF';

  @override
  String get exportToExcel => 'تصدير إلى Excel';

  @override
  String exportReady(int count) {
    return 'التصدير جاهز! تم تصدير $count وظائف إلى Excel.';
  }

  @override
  String get couldNotExport =>
      'تعذر إنشاء ملف التصدير. يرجى المحاولة مرة أخرى.';

  @override
  String get appSubtitle => 'نظام إدارة الفنيين';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String passwordResetSent(String email) {
    return 'تم إرسال بريد إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get passwordResetConfirmTitle => 'إعادة تعيين كلمة المرور؟';

  @override
  String passwordResetConfirmBody(String email) {
    return 'سيتم إرسال رابط إعادة التعيين إلى $email. متابعة؟';
  }

  @override
  String get passwordResetEmailSentTitle => 'تم إرسال البريد الإلكتروني';

  @override
  String passwordResetEmailSentBody(String email) {
    return 'تم إرسال رابط إعادة التعيين إلى $email.\n\nيرجى التحقق من صندوق الوارد. إذا لم تجده خلال بضع دقائق، تحقق من مجلد البريد العشوائي.\n\nينتهي صلاحية الرابط خلال ساعة واحدة.';
  }

  @override
  String get passwordResetNetworkError =>
      'لا يوجد اتصال بالإنترنت. يرجى الاتصال والمحاولة مرة أخرى.';

  @override
  String get passwordResetRateLimit =>
      'طلبات إعادة تعيين كثيرة جداً. يرجى الانتظار بضع دقائق والمحاولة مرة أخرى.';

  @override
  String get send => 'إرسال';

  @override
  String confirmDeleteUser(String name) {
    return 'سيتم تعطيل $name ولن يتمكن من تسجيل الدخول. متابعة؟';
  }

  @override
  String get addMoreEarning => '+ إضافة دخل آخر';

  @override
  String get addMoreExpense => '+ إضافة مصروف آخر';

  @override
  String get companies => 'الشركات';

  @override
  String get addCompany => 'إضافة شركة';

  @override
  String get editCompany => 'تعديل شركة';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get invoicePrefix => 'بادئة الفاتورة';

  @override
  String get invoiceSuffix => 'رقم الفاتورة';

  @override
  String get selectCompany => 'اختر الشركة (اختياري)';

  @override
  String get noCompany => 'بدون شركة';

  @override
  String get noCompaniesYet => 'لم تتم إضافة شركات بعد';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get changeYourName => 'تغيير اسمك';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get companyCreated => 'تم إنشاء الشركة بنجاح!';

  @override
  String get companyUpdated => 'تم تحديث الشركة بنجاح!';

  @override
  String get companyActivated => 'تم تفعيل الشركة';

  @override
  String get companyDeactivated => 'تم تعطيل الشركة';

  @override
  String get workExpenses => 'مصروفات العمل';

  @override
  String get homeExpenses => 'مصروفات المنزل';

  @override
  String get catSplitAc => 'مكيف سبليت';

  @override
  String get catWindowAc => 'مكيف نافذة';

  @override
  String get catFreestandingAc => 'مكيف قائم';

  @override
  String get catCassetteAc => 'مكيف كاسيت';

  @override
  String get catUninstallOldAc => 'إزالة (مكيف قديم)';

  @override
  String get catFood => 'طعام';

  @override
  String get catPetrol => 'بنزين';

  @override
  String get catPipes => 'أنابيب';

  @override
  String get catTools => 'أدوات';

  @override
  String get catTape => 'شريط لاصق';

  @override
  String get catInsulation => 'عزل';

  @override
  String get catGas => 'غاز';

  @override
  String get catOtherConsumables => 'مستهلكات أخرى';

  @override
  String get catHouseRent => 'إيجار المنزل';

  @override
  String get catOther => 'أخرى';

  @override
  String get catInstalledBracket => 'تركيب حامل';

  @override
  String get catInstalledExtraPipe => 'تركيب أنبوب إضافي';

  @override
  String get catOldAcRemoval => 'إزالة مكيف قديم';

  @override
  String get catOldAcInstallation => 'تركيب مكيف قديم';

  @override
  String get catSoldOldAc => 'بيع مكيف قديم';

  @override
  String get catSoldScrap => 'بيع خردة';

  @override
  String get catBreadRoti => 'خبز';

  @override
  String get catMeat => 'لحم';

  @override
  String get catChicken => 'دجاج';

  @override
  String get catTea => 'شاي';

  @override
  String get catSugar => 'سكر';

  @override
  String get catRice => 'أرز';

  @override
  String get catVegetables => 'خضروات';

  @override
  String get catCookingOil => 'زيت طبخ';

  @override
  String get catMilk => 'حليب';

  @override
  String get catSpices => 'بهارات';

  @override
  String get catOtherGroceries => 'مشتريات أخرى';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get flushDatabase => 'مسح قاعدة البيانات';

  @override
  String get flushDatabaseSubtitle =>
      'إعادة تعيين جميع البيانات إلى حالة نظيفة';

  @override
  String get flushStep1Title => 'الخطوة 1 من 2 — تأكيد النية';

  @override
  String get flushStep2Title => 'الخطوة 2 من 2 — التأكيد النهائي';

  @override
  String get flushWarningIntro =>
      'أنت على وشك حذف البيانات التالية نهائياً:';

  @override
  String get flushItemJobs => 'جميع سجلات الأعمال';

  @override
  String get flushItemExpenses => 'جميع سجلات المصروفات والإيرادات';

  @override
  String get flushItemCompanies => 'جميع سجلات الشركات';

  @override
  String get flushItemUsers => 'جميع حسابات المستخدمين غير المسؤولين';

  @override
  String get flushAdminKept => 'سيتم الحفاظ على حسابات المسؤولين.';

  @override
  String flushProceedIn(int seconds) => 'المتابعة خلال ${seconds}ث';

  @override
  String get flushProceed => 'المتابعة إلى الخطوة 2';

  @override
  String get flushEnterPassword => 'أدخل كلمة مرور المسؤول للتأكيد';

  @override
  String flushConfirmIn(int seconds) => 'التأكيد خلال ${seconds}ث';

  @override
  String get flushConfirm => 'مسح قاعدة البيانات';

  @override
  String get flushInProgress => 'جارٍ مسح قاعدة البيانات\u2026';

  @override
  String get flushSuccess => 'تم مسح قاعدة البيانات. جاهز للبدء من جديد.';

  @override
  String get flushFailed =>
      'فشل المسح. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get flushWrongPassword => 'كلمة المرور غير صحيحة. حاول مرة أخرى.';
}
