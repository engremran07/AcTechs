sealed class AppException implements Exception {
  const AppException(this.code, this.messageEn, this.messageUr, this.messageAr);

  final String code;
  final String messageEn;
  final String messageUr;
  final String messageAr;

  String message(String locale) {
    return switch (locale) {
      'ur' => messageUr,
      'ar' => messageAr,
      _ => messageEn,
    };
  }

  @override
  String toString() => '$runtimeType($code): $messageEn';
}

class AuthException extends AppException {
  const AuthException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory AuthException.wrongCredentials() => const AuthException(
    'auth_wrong_credentials',
    'Wrong username or password. Please check and try again.',
    'غلط نام یا پاس ورڈ۔ براہ کرم دوبارہ چیک کریں۔',
    'اسم مستخدم أو كلمة مرور خاطئة. يرجى المحاولة مرة أخرى.',
  );

  factory AuthException.accountDisabled() => const AuthException(
    'auth_account_disabled',
    'Your account has been deactivated. Contact your admin.',
    'آپ کا اکاؤنٹ غیر فعال ہے۔ ایڈمن سے رابطہ کریں۔',
    'تم تعطيل حسابك. تواصل مع المسؤول.',
  );

  factory AuthException.tooManyAttempts() => const AuthException(
    'auth_too_many_attempts',
    'Too many failed attempts. Please wait a few minutes.',
    'بہت زیادہ ناکام کوششیں۔ چند منٹ انتظار کریں۔',
    'محاولات فاشلة كثيرة. انتظر بضع دقائق.',
  );

  factory AuthException.sessionExpired() => const AuthException(
    'auth_session_expired',
    'Your session has expired. Please sign in again.',
    'آپ کا سیشن ختم ہو گیا۔ دوبارہ سائن ان کریں۔',
    'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.',
  );

  factory AuthException.updateFailed() => const AuthException(
    'auth_update_failed',
    'Could not update your profile. Please try again.',
    'پروفائل اپ ڈیٹ نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر تحديث ملفك الشخصي. حاول مرة أخرى.',
  );

  factory AuthException.fromFirebase(String firebaseCode) {
    return switch (firebaseCode) {
      'wrong-password' ||
      'user-not-found' ||
      'invalid-credential' => AuthException.wrongCredentials(),
      'user-disabled' => AuthException.accountDisabled(),
      'too-many-requests' => AuthException.tooManyAttempts(),
      _ => AuthException(
        'auth_unknown',
        'Something went wrong. Please try again.',
        'کچھ غلط ہو گیا۔ دوبارہ کوشش کریں۔',
        'حدث خطأ ما. حاول مرة أخرى.',
      ),
    };
  }
}

class NetworkException extends AppException {
  const NetworkException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory NetworkException.offline() => const NetworkException(
    'network_offline',
    "You're offline. Your work is saved and will sync automatically when connected.",
    'آپ آف لائن ہیں۔ آپ کا کام محفوظ ہے اور کنکشن ملنے پر خود بخود سنک ہوگا۔',
    'أنت غير متصل. عملك محفوظ وسيتم المزامنة تلقائياً عند الاتصال.',
  );

  factory NetworkException.syncFailed() => const NetworkException(
    'network_sync_failed',
    "Couldn't sync your data. We'll retry automatically.",
    'ڈیٹا سنک نہیں ہو سکا۔ خود بخود دوبارہ کوشش ہوگی۔',
    'تعذرت مزامنة بياناتك. سنعيد المحاولة تلقائياً.',
  );
}

class JobException extends AppException {
  const JobException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory JobException.noInvoice() => const JobException(
    'job_no_invoice',
    'Please enter an invoice number.',
    'براہ کرم انوائس نمبر درج کریں۔',
    'يرجى إدخال رقم الفاتورة.',
  );

  factory JobException.noUnits() => const JobException(
    'job_no_units',
    'Add at least one AC unit before submitting.',
    'جمع کرانے سے پہلے کم از کم ایک اے سی یونٹ شامل کریں۔',
    'أضف وحدة تكييف واحدة على الأقل قبل الإرسال.',
  );

  factory JobException.saveFailed() => const JobException(
    'job_save_failed',
    "Couldn't save your job. We'll retry in a moment.",
    'آپ کا کام محفوظ نہیں ہو سکا۔ تھوڑی دیر میں دوبارہ کوشش ہوگی۔',
    'تعذر حفظ عملك. سنعيد المحاولة بعد لحظات.',
  );

  factory JobException.duplicateInvoice() => const JobException(
    'job_duplicate_invoice',
    'A job with this invoice number already exists.',
    'اس انوائس نمبر سے پہلے سے ایک کام موجود ہے۔',
    'يوجد عمل بهذا الرقم بالفعل.',
  );
}

class AdminException extends AppException {
  const AdminException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory AdminException.rejectNoReason() => const AdminException(
    'admin_reject_no_reason',
    'Please add a reason so the technician knows what to fix.',
    'براہ کرم وجہ بتائیں تاکہ ٹیکنیشن کو پتا چلے کیا ٹھیک کرنا ہے۔',
    'يرجى إضافة سبب ليعرف الفني ما يجب إصلاحه.',
  );

  factory AdminException.noPermission() => const AdminException(
    'admin_no_permission',
    "You don't have admin access for this action.",
    'آپ کو اس عمل کے لیے ایڈمن رسائی نہیں ہے۔',
    'ليس لديك صلاحية المسؤول لهذا الإجراء.',
  );

  factory AdminException.flushFailed() => const AdminException(
    'admin_flush_failed',
    "Database flush failed. Please check your connection and try again.",
    'ڈیٹا بیس فلش ناکام ہوا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'فشل مسح قاعدة البيانات. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory AdminException.wrongPassword() => const AdminException(
    'admin_wrong_password',
    'Incorrect password. Please try again.',
    'غلط پاس ورڈ۔ دوبارہ کوشش کریں۔',
    'كلمة المرور غير صحيحة. حاول مرة أخرى.',
  );
}

class ExpenseException extends AppException {
  const ExpenseException(
    super.code,
    super.messageEn,
    super.messageUr,
    super.messageAr,
  );

  factory ExpenseException.saveFailed() => const ExpenseException(
    'expense_save_failed',
    "Couldn't save your entry. Please check your connection and try again.",
    'آپ کا اندراج محفوظ نہیں ہو سکا۔ کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
    'تعذر حفظ الإدخال. تحقق من اتصالك وحاول مرة أخرى.',
  );

  factory ExpenseException.deleteFailed() => const ExpenseException(
    'expense_delete_failed',
    "Couldn't delete the entry. Please try again.",
    'اندراج حذف نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
    'تعذر حذف الإدخال. حاول مرة أخرى.',
  );

  factory ExpenseException.userSaveFailed() => const ExpenseException(
    'user_save_failed',
    "Couldn't save changes. Please try again.",
    'تبدیلیاں محفوظ نہیں ہو سکیں۔ دوبارہ کوشش کریں۔',
    'تعذر حفظ التغييرات. حاول مرة أخرى.',
  );
}
