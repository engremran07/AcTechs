# AC Techs — Custom Error & Success Messages

All messages are tri-lingual. No raw Firebase/Flutter errors are ever shown to users.

## Error Categories

### Authentication Errors

| Code | English | اردو (Urdu) | العربية (Arabic) |
|------|---------|-------------|-----------------|
| auth_wrong_credentials | Wrong username or password. Please check and try again. | غلط نام یا پاس ورڈ۔ براہ کرم دوبارہ چیک کریں۔ | اسم مستخدم أو كلمة مرور خاطئة. يرجى المحاولة مرة أخرى. |
| auth_account_disabled | Your account has been deactivated. Contact your admin. | آپ کا اکاؤنٹ غیر فعال ہے۔ ایڈمن سے رابطہ کریں۔ | تم تعطيل حسابك. تواصل مع المسؤول. |
| auth_too_many_attempts | Too many failed attempts. Please wait a few minutes. | بہت زیادہ ناکام کوششیں۔ چند منٹ انتظار کریں۔ | محاولات فاشلة كثيرة. انتظر بضع دقائق. |
| auth_session_expired | Your session has expired. Please sign in again. | آپ کا سیشن ختم ہو گیا۔ دوبارہ سائن ان کریں۔ | انتهت جلستك. يرجى تسجيل الدخول مرة أخرى. |

### Network Errors

| Code | English | اردو | العربية |
|------|---------|------|---------|
| network_offline | You're offline. Your work is saved and will sync automatically when connected. | آپ آف لائن ہیں۔ آپ کا کام محفوظ ہے اور کنکشن ملنے پر خود بخود سنک ہوگا۔ | أنت غير متصل. عملك محفوظ وسيتم المزامنة تلقائياً عند الاتصال. |
| network_slow | Connection is slow. This might take a moment. | کنکشن سست ہے۔ تھوڑا وقت لگ سکتا ہے۔ | الاتصال بطيء. قد يستغرق لحظة. |
| network_sync_failed | Couldn't sync your data. We'll retry automatically. | ڈیٹا سنک نہیں ہو سکا۔ خود بخود دوبارہ کوشش ہوگی۔ | تعذرت مزامنة بياناتك. سنعيد المحاولة تلقائياً. |

### Job Submission Errors

| Code | English | اردو | العربية |
|------|---------|------|---------|
| job_no_invoice | Please enter an invoice number. | براہ کرم انوائس نمبر درج کریں۔ | يرجى إدخال رقم الفاتورة. |
| job_no_units | Add at least one AC unit before submitting. | جمع کرانے سے پہلے کم از کم ایک اے سی یونٹ شامل کریں۔ | أضف وحدة تكييف واحدة على الأقل قبل الإرسال. |
| job_invalid_contact | Please enter a valid contact number. | براہ کرم درست رابطہ نمبر درج کریں۔ | يرجى إدخال رقم اتصال صحيح. |
| job_negative_expense | Expense amount cannot be negative. | خرچے کی رقم منفی نہیں ہو سکتی۔ | لا يمكن أن يكون مبلغ المصروف سالباً. |
| job_save_failed | Couldn't save your job. We'll retry in a moment. | آپ کا کام محفوظ نہیں ہو سکا۔ تھوڑی دیر میں دوبارہ کوشش ہوگی۔ | تعذر حفظ عملك. سنعيد المحاولة بعد لحظات. |
| job_duplicate_invoice | A job with this invoice number already exists. | اس انوائس نمبر سے پہلے سے ایک کام موجود ہے۔ | يوجد عمل بهذا الرقم بالفعل. |

### Admin Errors

| Code | English | اردو | العربية |
|------|---------|------|---------|
| admin_reject_no_reason | Please add a reason so the technician knows what to fix. | براہ کرم وجہ بتائیں تاکہ ٹیکنیشن کو پتا چلے کیا ٹھیک کرنا ہے۔ | يرجى إضافة سبب ليعرف الفني ما يجب إصلاحه. |
| admin_action_failed | Couldn't process this action. Please try again. | یہ عمل مکمل نہیں ہو سکا۔ دوبارہ کوشش کریں۔ | تعذر تنفيذ هذا الإجراء. حاول مرة أخرى. |
| admin_no_permission | You don't have admin access for this action. | آپ کو اس عمل کے لیے ایڈمن رسائی نہیں ہے۔ | ليس لديك صلاحية المسؤول لهذا الإجراء. |

### Export Errors

| Code | English | اردو | العربية |
|------|---------|------|---------|
| export_no_data | No jobs found for this period. Try a different date range. | اس مدت کے لیے کوئی کام نہیں ملا۔ مختلف تاریخ آزمائیں۔ | لم يتم العثور على أعمال لهذه الفترة. جرب نطاقاً مختلفاً. |
| export_failed | Couldn't create the export file. Please try again. | ایکسپورٹ فائل نہیں بن سکی۔ دوبارہ کوشش کریں۔ | تعذر إنشاء ملف التصدير. حاول مرة أخرى. |

---

## Success Messages

| Code | English | اردو | العربية |
|------|---------|------|---------|
| job_submitted | Job submitted successfully! Waiting for admin approval. | کام کامیابی سے جمع ہو گیا! ایڈمن کی منظوری کا انتظار ہے۔ | تم إرسال العمل بنجاح! في انتظار موافقة المسؤول. |
| job_approved | Job approved! {techName} will see this update instantly. | کام منظور ہو گیا! {techName} کو فوری طور پر نظر آئے گا۔ | تمت الموافقة! سيرى {techName} التحديث فوراً. |
| job_rejected | Job returned to {techName} with your feedback. | کام {techName} کو آپ کے تبصرے کے ساتھ واپس بھیج دیا گیا۔ | تم إرجاع العمل إلى {techName} مع ملاحظاتك. |
| export_success | Export ready! {count} jobs exported to Excel. | ایکسپورٹ تیار! {count} کام ایکسل میں بھیجے گئے۔ | التصدير جاهز! تم تصدير {count} عمل إلى Excel. |
| user_activated | {name} has been activated and can now submit jobs. | {name} فعال ہو گیا اور اب کام جمع کرا سکتا ہے۔ | تم تفعيل {name} ويمكنه الآن إرسال الأعمال. |
| user_deactivated | {name} has been deactivated and can no longer submit jobs. | {name} غیر فعال ہو گیا اور اب کام جمع نہیں کرا سکتا۔ | تم تعطيل {name} ولم يعد بإمكانه إرسال الأعمال. |
| language_changed | Language changed to {language}. | زبان {language} میں تبدیل ہو گئی۔ | تم تغيير اللغة إلى {language}. |
| data_synced | All your data has been synced successfully. | آپ کا تمام ڈیٹا کامیابی سے سنک ہو گیا۔ | تمت مزامنة جميع بياناتك بنجاح. |

---

## Status Labels

| Status | English | اردو | العربية |
|--------|---------|------|---------|
| pending | Pending | زیر التوا | قيد الانتظار |
| approved | Approved | منظور شدہ | موافق عليه |
| rejected | Rejected | مسترد | مرفوض |
| draft | Draft | مسودہ | مسودة |
| offline | Offline | آف لائن | غير متصل |
| syncing | Syncing... | سنک ہو رہا ہے... | جارٍ المزامنة... |

---

## UI Labels (Key ones)

| Key | English | اردو | العربية |
|-----|---------|------|---------|
| app_name | AC Techs | اے سی ٹیکس | إيه سي تكس |
| sign_in | Sign In | سائن ان | تسجيل الدخول |
| sign_out | Sign Out | سائن آؤٹ | تسجيل الخروج |
| technician | Technician | ٹیکنیشن | فني |
| admin | Admin | ایڈمن | مسؤول |
| home | Home | ہوم | الرئيسية |
| jobs | Jobs | کام | الأعمال |
| expenses | Expenses | اخراجات | المصروفات |
| profile | Profile | پروفائل | الملف الشخصي |
| approvals | Approvals | منظوریاں | الموافقات |
| analytics | Analytics | تجزیات | التحليلات |
| team | Team | ٹیم | الفريق |
| export | Export | ایکسپورٹ | تصدير |
| submit | Submit for Approval | منظوری کے لیے جمع کریں | إرسال للموافقة |
| approve | Approve | منظور کریں | موافقة |
| reject | Reject | مسترد کریں | رفض |
| today | Today | آج | اليوم |
| this_month | This Month | اس مہینے | هذا الشهر |
