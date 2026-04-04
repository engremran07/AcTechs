import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart' as reshaper;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/base64_image_codec.dart';
import 'package:ac_techs/core/theme/app_fonts.dart';

// ─── Brand colours (mirrors arctic_theme.dart) ───────────────────────────────
const _kBrandBlue = PdfColor.fromInt(0xFF00D4FF); // arctic blue
const _kBrandDark = PdfColor.fromInt(0xFF0D1117); // near-black
const _kGreen = PdfColor.fromInt(0xFF00C853);
const _kRed = PdfColor.fromInt(0xFFD50000);
const _kAmber = PdfColor.fromInt(0xFFFFB300);

// ─── Isolate PDF generation (to avoid UI freeze on large reports) ───────────
/// Parameters passed to isolate PDF generation function.
class _PdfGenerationParams {
  final List<JobModel> jobs;
  final String title;
  final String locale;
  final String? technicianName;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool useDetails;
  final int maxPages;
  final String serviceCompanyName;
  final String serviceCompanyLogoBase64;
  final String serviceCompanyPhoneNumber;
  final String clientCompanyName;
  final String clientCompanyLogoBase64;

  _PdfGenerationParams({
    required this.jobs,
    required this.title,
    required this.locale,
    this.technicianName, // ignore: unused_element_parameter — reserved for future filter by technician feature
    this.fromDate, // ignore: unused_element_parameter — reserved for future date range feature
    this.toDate, // ignore: unused_element_parameter — reserved for future date range feature
    this.useDetails = false,
    this.maxPages = 2000,
    this.serviceCompanyName = '',
    this.serviceCompanyLogoBase64 = '',
    this.serviceCompanyPhoneNumber = '',
    this.clientCompanyName = '',
    this.clientCompanyLogoBase64 = '',
  });
}

/// Top-level function for isolate PDF generation (called via compute()).
Future<Uint8List> _isolatePdfGeneration(_PdfGenerationParams params) async {
  final reportBranding = ReportBrandingContext(
    serviceCompany: ReportBrandIdentity(
      name: params.serviceCompanyName,
      logoBase64: params.serviceCompanyLogoBase64,
      phoneNumber: params.serviceCompanyPhoneNumber,
    ),
    clientCompany: params.clientCompanyName.trim().isEmpty
        ? null
        : ReportBrandIdentity(
            name: params.clientCompanyName,
            logoBase64: params.clientCompanyLogoBase64,
          ),
  );

  if (params.useDetails) {
    return PdfGenerator.generateJobsDetailsReport(
      jobs: params.jobs,
      title: params.title,
      locale: params.locale,
      technicianName: params.technicianName,
      fromDate: params.fromDate,
      toDate: params.toDate,
      maxPages: params.maxPages,
      reportBranding: reportBranding,
    );
  } else {
    return PdfGenerator.generateJobsReport(
      jobs: params.jobs,
      title: params.title,
      locale: params.locale,
      technicianName: params.technicianName,
      fromDate: params.fromDate,
      toDate: params.toDate,
      reportBranding: reportBranding,
    );
  }
}

/// Unified PDF report generator with RTL font support for all 3 locales.
///
/// All public methods are `static` so callers do not need an instance.
/// Fonts are loaded lazily and cached for the lifetime of the process.
class PdfGenerator {
  PdfGenerator._();
  static final reshaper.ArabicReshaper _reshaper = reshaper.ArabicReshaper();
  static final RegExp _arabicScriptRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    unicode: true,
  );

  static String _shapeRtlForPdf(String locale, String text) {
    if (locale != 'ur' && locale != 'ar') return text;
    if (text.isEmpty || !_arabicScriptRegex.hasMatch(text)) return text;
    return _reshaper.reshape(text);
  }

  static List<String> _shapeRowForPdf(String locale, List<String> row) {
    if (locale != 'ur' && locale != 'ar') return row;
    return row.map((value) => _shapeRtlForPdf(locale, value)).toList();
  }

  static List<List<String>> _shapeTableForPdf(
    String locale,
    List<List<String>> rows,
  ) {
    if (locale != 'ur' && locale != 'ar') return rows;
    return rows.map((row) => _shapeRowForPdf(locale, row)).toList();
  }

  static String _translateCategoryForPdf(String locale, String key) {
    if (locale == 'ar') {
      return switch (key) {
        'Installed Bracket' => 'تركيب حامل',
        'Installed Extra Pipe' => 'تركيب أنبوب إضافي',
        'Old AC Removal' => 'إزالة مكيف قديم',
        'Old AC Installation' => 'تركيب مكيف قديم',
        'Sold Old AC' => 'بيع مكيف قديم',
        'Sold Scrap' => 'بيع خردة',
        'Food' => 'طعام',
        'Petrol' => 'وقود',
        'Pipes' => 'أنابيب',
        'Tools' => 'أدوات',
        'Tape' => 'شريط',
        'Insulation' => 'عزل',
        'Gas' => 'غاز',
        'Other Consumables' => 'مستهلكات أخرى',
        'House Rent' => 'إيجار المنزل',
        'Other' => 'أخرى',
        'Bread/Roti' => 'خبز/روتي',
        'Meat' => 'لحم',
        'Chicken' => 'دجاج',
        'Tea' => 'شاي',
        'Sugar' => 'سكر',
        'Rice' => 'أرز',
        'Vegetables' => 'خضروات',
        'Cooking Oil' => 'زيت طبخ',
        'Milk' => 'حليب',
        'Spices' => 'بهارات',
        'Other Groceries' => 'بقالة أخرى',
        _ => key,
      };
    }
    if (locale == 'ur') {
      return switch (key) {
        'Installed Bracket' => 'بریکٹ انسٹال',
        'Installed Extra Pipe' => 'اضافی پائپ انسٹال',
        'Old AC Removal' => 'پرانا اے سی ہٹایا',
        'Old AC Installation' => 'پرانا اے سی انسٹال',
        'Sold Old AC' => 'پرانا اے سی فروخت',
        'Sold Scrap' => 'سکریپ فروخت',
        'Food' => 'کھانا',
        'Petrol' => 'پیٹرول',
        'Pipes' => 'پائپس',
        'Tools' => 'اوزار',
        'Tape' => 'ٹیپ',
        'Insulation' => 'انسولیشن',
        'Gas' => 'گیس',
        'Other Consumables' => 'دیگر کنزیوم ایبلز',
        'House Rent' => 'گھر کا کرایہ',
        'Other' => 'دیگر',
        'Bread/Roti' => 'روٹی',
        'Meat' => 'گوشت',
        'Chicken' => 'چکن',
        'Tea' => 'چائے',
        'Sugar' => 'چینی',
        'Rice' => 'چاول',
        'Vegetables' => 'سبزیاں',
        'Cooking Oil' => 'کوکنگ آئل',
        'Milk' => 'دودھ',
        'Spices' => 'مصالحہ',
        'Other Groceries' => 'دیگر کریانہ',
        _ => key,
      };
    }
    return key;
  }

  static String _safeTableCellText(String? value, {int maxLength = 120}) {
    final cleaned = AppFormatters.safeText(value);
    if (cleaned.trim().isEmpty || cleaned == '-') return '';
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength - 3)}...';
  }

  static String _plainAmount(double value) {
    if (value <= 0) return '';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  // ── Font cache ──────────────────────────────────────────────────────────────
  // Shared between ur and ar since both now use NotoNaskhArabic for PDFs.
  static pw.Font? _cachedRtlFont;

  static Future<pw.Font?> _getLocaleFont(String locale) async {
    if (locale == 'ur' || locale == 'ar') {
      final asset = AppFonts.pdfFontAsset(locale);
      if (asset == null) return null;
      _cachedRtlFont ??= pw.Font.ttf(await rootBundle.load(asset));
      return _cachedRtlFont;
    }
    return null; // pdf package's built-in Latin font
  }

  static pw.TextDirection _dir(String locale) =>
      (locale == 'ur' || locale == 'ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;

  static ({pw.MemoryImage? image, String? svg}) _decodePdfLogo(
    String? logoBase64,
  ) {
    if (logoBase64 == null || logoBase64.trim().isEmpty) {
      return (image: null, svg: null);
    }

    final bytes = Base64ImageCodec.tryDecodeBytes(logoBase64);
    if (bytes == null) return (image: null, svg: null);

    final svg = Base64ImageCodec.tryDecodeSvgBytes(bytes);
    if (svg != null) return (image: null, svg: svg);

    return (image: pw.MemoryImage(bytes), svg: null);
  }

  static pw.Widget _brandIdentityPanel({
    required ReportBrandIdentity identity,
    required pw.Font? font,
    required pw.TextDirection dir,
    required bool alignEnd,
  }) {
    final decodedLogo = _decodePdfLogo(identity.logoBase64);
    final hasLogo = decodedLogo.svg != null || decodedLogo.image != null;
    final crossAxisAlignment = alignEnd
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;
    final textAlign = alignEnd ? pw.TextAlign.right : pw.TextAlign.left;

    final logoWidget = hasLogo
        ? pw.Container(
            width: 34,
            height: 34,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: decodedLogo.svg != null
                ? pw.SvgImage(svg: decodedLogo.svg!, fit: pw.BoxFit.contain)
                : pw.Image(decodedLogo.image!, fit: pw.BoxFit.contain),
          )
        : null;

    return pw.Row(
      mainAxisAlignment: alignEnd
          ? pw.MainAxisAlignment.end
          : pw.MainAxisAlignment.start,
      children: [
        if (!alignEnd && logoWidget != null) logoWidget,
        if (!alignEnd && logoWidget != null) pw.SizedBox(width: 8),
        pw.Flexible(
          child: pw.Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              pw.Text(
                identity.name.trim().isEmpty
                    ? AppConstants.appName
                    : identity.name,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _kBrandDark,
                ),
                textDirection: dir,
                textAlign: textAlign,
              ),
              if (identity.phoneNumber.trim().isNotEmpty)
                pw.Text(
                  identity.phoneNumber,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                  textDirection: dir,
                  textAlign: textAlign,
                ),
            ],
          ),
        ),
        if (alignEnd && logoWidget != null) pw.SizedBox(width: 8),
        if (alignEnd && logoWidget != null) logoWidget,
      ],
    );
  }

  // ── Shared page decorators ──────────────────────────────────────────────────

  /// Top brand banner shown on every page of every report.
  static pw.Widget _pageHeader(
    pw.Context ctx, {
    required String reportTitle,
    required pw.Font? font,
    required pw.TextDirection dir,
    String? dateRange,
    ReportBrandingContext? reportBranding,
    String? brandName,
    String? logoBase64,
  }) {
    final serviceCompany =
        reportBranding?.serviceCompany ??
        ReportBrandIdentity(
          name: (brandName?.trim().isNotEmpty ?? false)
              ? brandName!.trim()
              : AppConstants.appName,
          logoBase64: logoBase64 ?? '',
        );
    final clientCompany = reportBranding?.clientCompany;

    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                flex: 4,
                child: _brandIdentityPanel(
                  identity: serviceCompany,
                  font: font,
                  dir: dir,
                  alignEnd: false,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _kBrandDark,
                      ),
                      textDirection: dir,
                      textAlign: pw.TextAlign.center,
                    ),
                    if (dateRange != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        dateRange,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                        textDirection: dir,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                flex: 4,
                child: clientCompany == null
                    ? pw.SizedBox()
                    : _brandIdentityPanel(
                        identity: clientCompany,
                        font: font,
                        dir: dir,
                        alignEnd: true,
                      ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Bottom strip shown on every page: confidentiality note + page numbers.
  static pw.Widget _pageFooter(
    pw.Context ctx, {
    required pw.Font? font,
    required pw.TextDirection dir,
    ReportBrandingContext? reportBranding,
  }) {
    final serviceCompany = reportBranding?.serviceCompany;
    final clientCompany = reportBranding?.clientCompany;
    final leadText = serviceCompany == null
        ? '${AppConstants.appName} — Confidential'
        : '${serviceCompany.name.trim().isEmpty ? AppConstants.appName : serviceCompany.name}${serviceCompany.phoneNumber.trim().isEmpty ? '' : ' • ${serviceCompany.phoneNumber}'}';

    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              leadText,
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
              textDirection: dir,
            ),
            if (clientCompany != null)
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    clientCompany.name,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 7,
                      color: PdfColors.grey600,
                    ),
                    textDirection: dir,
                  ),
                ),
              )
            else
              pw.SizedBox(),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}'
              '  |  ${AppFormatters.dateTime(DateTime.now())}',
              style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey600,
              ),
              textDirection: dir,
            ),
          ],
        ),
      ],
    );
  }

  /// Coloured KPI summary box (earnings / expenses / net).
  static pw.Widget _kpiBox({
    required String earningsLabel,
    required String expensesLabel,
    required String netLabel,
    required double totalEarnings,
    required double totalExpenses,
    required pw.Font? font,
    required pw.TextDirection dir,
  }) {
    final net = totalEarnings - totalExpenses;
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColors.grey700,
    );
    final valStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(earningsLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(totalEarnings),
                style: valStyle.copyWith(color: _kGreen),
                textDirection: dir,
              ),
            ],
          ),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(
            children: [
              pw.Text(expensesLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(totalExpenses),
                style: valStyle.copyWith(color: _kRed),
                textDirection: dir,
              ),
            ],
          ),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(
            children: [
              pw.Text(netLabel, style: subStyle, textDirection: dir),
              pw.Text(
                AppFormatters.currency(net.abs()),
                style: valStyle.copyWith(color: net >= 0 ? _kGreen : _kRed),
                textDirection: dir,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Non-financial KPI box for count-based summaries.
  static pw.Widget _statsBox({
    required String firstLabel,
    required String secondLabel,
    required String thirdLabel,
    required String firstValue,
    required String secondValue,
    required String thirdValue,
    required pw.Font? font,
    required pw.TextDirection dir,
  }) {
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      color: PdfColors.grey700,
    );
    final valStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: _kBrandBlue,
    );

    pw.Widget statCell(String label, String value) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Text(label, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 2),
            pw.Text(value, style: valStyle, textDirection: dir),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        children: [
          statCell(firstLabel, firstValue),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          statCell(secondLabel, secondValue),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          statCell(thirdLabel, thirdValue),
        ],
      ),
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  static Map<String, String> _statusLabels(String locale) => {
    'pending': locale == 'ur'
        ? 'زیر غور'
        : locale == 'ar'
        ? 'قيد الانتظار'
        : 'Pending',
    'approved': locale == 'ur'
        ? 'منظور'
        : locale == 'ar'
        ? 'موافق عليه'
        : 'Approved',
    'rejected': locale == 'ur'
        ? 'مسترد'
        : locale == 'ar'
        ? 'مرفوض'
        : 'Rejected',
  };

  static PdfColor _statusColour(String status) => switch (status) {
    'approved' => _kGreen,
    'rejected' => _kRed,
    _ => _kAmber,
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Generate a paginated jobs report PDF with branded header + footer.
  static Future<Uint8List> generateJobsReport({
    required List<JobModel> jobs,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final tableHeaders = locale == 'ur'
        ? ['انوائس', 'ٹیکنیشن', 'کلائنٹ', 'تاریخ', 'یونٹس', 'اخراجات', 'حالت']
        : locale == 'ar'
        ? ['فاتورة', 'فني', 'عميل', 'تاريخ', 'وحدات', 'مصاريف', 'حالة']
        : [
            'Invoice',
            'Technician',
            'Client',
            'Date',
            'Units',
            'Expenses',
            'Status',
          ];

    final statusMap = _statusLabels(locale);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;

    final totalExpenses = jobs.fold<double>(0, (s, j) => s + j.expenses);
    final totalExpensesLabel = locale == 'ur'
        ? 'کل اخراجات'
        : locale == 'ar'
        ? 'إجمالي المصروفات'
        : 'Total Expenses';
    final totalJobsLabel = locale == 'ur'
        ? 'کل ملازمتیں: ${jobs.length}'
        : locale == 'ar'
        ? 'إجمالي الوظائف: ${jobs.length}'
        : 'Total Jobs: ${jobs.length}';
    final totalUnits = jobs.fold<int>(0, (sum, job) => sum + job.totalUnits);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          // Technician / date meta
          if (technicianName != null)
            pw.Text(technicianName, style: subStyle, textDirection: dir),
          pw.SizedBox(height: 10),

          // KPI summary box
          _statsBox(
            firstLabel: locale == 'ur'
                ? 'کل جابز'
                : locale == 'ar'
                ? 'إجمالي الوظائف'
                : 'Total Jobs',
            secondLabel: locale == 'ur'
                ? 'کل یونٹس'
                : locale == 'ar'
                ? 'إجمالي الوحدات'
                : 'Total Units',
            thirdLabel: totalExpensesLabel,
            firstValue: '${jobs.length}',
            secondValue: '$totalUnits',
            thirdValue: AppFormatters.currency(totalExpenses),
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 12),

          // Jobs table
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, tableHeaders),
            data: _shapeTableForPdf(
              locale,
              jobs.map((j) {
                final statusText = statusMap[j.status.name] ?? j.status.name;
                return [
                  _safeTableCellText(j.invoiceNumber, maxLength: 40),
                  _safeTableCellText(j.techName, maxLength: 35),
                  _safeTableCellText(j.clientName, maxLength: 40),
                  AppFormatters.date(j.date),
                  '${j.totalUnits}',
                  AppFormatters.currency(j.expenses),
                  _shapeRtlForPdf(locale, statusText),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            cellAlignments: {
              for (var i = 0; i < 7; i++) i: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 3,
            ),
          ),
          pw.SizedBox(height: 10),

          // Footer summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                totalJobsLabel,
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                locale == 'ur'
                    ? 'کل اخراجات: ${AppFormatters.currency(totalExpenses)}'
                    : locale == 'ar'
                    ? 'إجمالي المصاريف: ${AppFormatters.currency(totalExpenses)}'
                    : 'Total Expenses: ${AppFormatters.currency(totalExpenses)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a monthly earnings + expenses report PDF with KPI summary.
  static Future<Uint8List> generateExpensesReport({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // i18n labels
    final earningsLabel = locale == 'ur'
        ? 'آمدنی (IN)'
        : locale == 'ar'
        ? 'الإيرادات (الدخل)'
        : 'Earnings (IN)';
    final expensesLabel = locale == 'ur'
        ? 'اخراجات (OUT)'
        : locale == 'ar'
        ? 'المصروفات (الخروج)'
        : 'Expenses (OUT)';
    final totalEarningsLabel = locale == 'ur'
        ? 'کل آمدنی'
        : locale == 'ar'
        ? 'إجمالي الإيرادات'
        : 'Total Earnings';
    final totalExpensesLabel = locale == 'ur'
        ? 'کل اخراجات'
        : locale == 'ar'
        ? 'إجمالي المصروفات'
        : 'Total Expenses';
    final netLabel = locale == 'ur'
        ? 'خالص منافع'
        : locale == 'ar'
        ? 'صافي الربح'
        : 'Net Profit';
    final earningsHeaders = locale == 'ur'
        ? ['زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];
    final expensesHeaders = locale == 'ur'
        ? ['نوع', 'زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['النوع', 'الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Type', 'Category', 'Amount (SAR)', 'Date', 'Note'];

    final totalEarningsAmt = earnings.fold<double>(0, (s, e) => s + e.amount);
    final totalExpensesAmt = expenses.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          // Technician / date meta
          if (technicianName != null) ...[
            pw.Text(technicianName, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],

          // KPI summary
          _kpiBox(
            earningsLabel: totalEarningsLabel,
            expensesLabel: totalExpensesLabel,
            netLabel: netLabel,
            totalEarnings: totalEarningsAmt,
            totalExpenses: totalExpensesAmt,
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 16),

          // ── Earnings section ───────────────────────────────────────────────
          if (earnings.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: _kGreen, width: 3),
                ),
              ),
              child: pw.Text(
                earningsLabel,
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, earningsHeaders),
              data: _shapeTableForPdf(
                locale,
                earnings
                    .map(
                      (e) => [
                        _shapeRtlForPdf(
                          locale,
                          _translateCategoryForPdf(locale, e.category),
                        ),
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kGreen),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Expenses section ───────────────────────────────────────────────
          if (expenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kRed, width: 3)),
              ),
              child: pw.Text(
                expensesLabel,
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, expensesHeaders),
              data: _shapeTableForPdf(
                locale,
                expenses
                    .map(
                      (e) => [
                        _shapeRtlForPdf(locale, e.expenseType),
                        _shapeRtlForPdf(
                          locale,
                          _translateCategoryForPdf(locale, e.category),
                        ),
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kRed),
              cellAlignments: {
                for (var i = 0; i < 5; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a professional single-job invoice PDF.
  ///
  /// Produces an A4 document with job details, unit breakdown, charges and
  /// a signature strip — suitable for handing to the client.
  static Future<Uint8List> generateJobInvoice({
    required JobModel job,
    String locale = 'en',
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';
    final align = isRtl
        ? pw.CrossAxisAlignment.end
        : pw.CrossAxisAlignment.start;

    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final labelStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );
    final valueStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // i18n field labels
    final invoiceLabel = locale == 'ur'
        ? 'انوائس نمبر'
        : locale == 'ar'
        ? 'رقم الفاتورة'
        : 'Invoice No.';
    final dateLabel = locale == 'ur'
        ? 'تاریخ'
        : locale == 'ar'
        ? 'التاريخ'
        : 'Date';
    final clientLabel = locale == 'ur'
        ? 'کلائنٹ'
        : locale == 'ar'
        ? 'العميل'
        : 'Client';
    final contactLabel = locale == 'ur'
        ? 'رابطہ'
        : locale == 'ar'
        ? 'التواصل'
        : 'Contact';
    final techLabel = locale == 'ur'
        ? 'ٹیکنیشن'
        : locale == 'ar'
        ? 'الفني'
        : 'Technician';
    final statusLabel = locale == 'ur'
        ? 'حالت'
        : locale == 'ar'
        ? 'الحالة'
        : 'Status';
    final companyLabel = locale == 'ur'
        ? 'کمپنی'
        : locale == 'ar'
        ? 'الشركة'
        : 'Company';
    final unitsLabel = locale == 'ur'
        ? 'اے سی یونٹس'
        : locale == 'ar'
        ? 'وحدات التكييف'
        : 'AC Units';
    final chargesLabel = locale == 'ur'
        ? 'اضافی چارجز'
        : locale == 'ar'
        ? 'رسوم إضافية'
        : 'Additional Charges';
    final expensesLabel = locale == 'ur'
        ? 'اخراجات'
        : locale == 'ar'
        ? 'المصاريف'
        : 'Job Expenses';
    final totalLabel = locale == 'ur'
        ? 'کل'
        : locale == 'ar'
        ? 'الإجمالي'
        : 'Total';
    final sigLabel = locale == 'ur'
        ? 'دستخط'
        : locale == 'ar'
        ? 'التوقيع'
        : 'Signature';
    final stampLabel = locale == 'ur'
        ? 'مہر'
        : locale == 'ar'
        ? 'الختم'
        : 'Stamp';
    final unitTypeLabel = locale == 'ur'
        ? 'قسم'
        : locale == 'ar'
        ? 'النوع'
        : 'Type';
    final qtyLabel = locale == 'ur'
        ? 'تعداد'
        : locale == 'ar'
        ? 'الكمية'
        : 'Qty';
    final bracketLabel = locale == 'ur'
        ? 'بریکٹ'
        : locale == 'ar'
        ? 'الحامل'
        : 'Bracket';
    final deliveryLabel = locale == 'ur'
        ? 'ڈیلیوری'
        : locale == 'ar'
        ? 'التوصيل'
        : 'Delivery';
    final yesLabel = locale == 'ur'
        ? 'ہاں'
        : locale == 'ar'
        ? 'نعم'
        : 'Yes';
    final noLabel = locale == 'ur'
        ? 'نہیں'
        : locale == 'ar'
        ? 'لا'
        : 'No';
    final invoiceTitle = locale == 'ur'
        ? 'سروس انوائس'
        : locale == 'ar'
        ? 'فاتورة الخدمة'
        : 'Service Invoice';

    final statusText =
        _statusLabels(locale)[job.status.name] ?? job.status.name;
    final statusColor = _statusColour(job.status.name);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: align,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: invoiceTitle,
          font: font,
          dir: dir,
          dateRange: AppFormatters.date(job.date),
        ),
        footer: (ctx) => _pageFooter(ctx, font: font, dir: dir),
        build: (context) => [
          // ── Invoice title + status badge ──────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(invoiceTitle, style: titleStyle, textDirection: dir),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  statusText,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textDirection: dir,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // ── Invoice meta grid ─────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metaField(
                        invoiceLabel,
                        job.invoiceNumber,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        dateLabel,
                        AppFormatters.date(job.date),
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        statusLabel,
                        statusText,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _metaField(
                        clientLabel,
                        job.clientName,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        contactLabel,
                        job.clientContact.isEmpty ? '—' : job.clientContact,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                    pw.Expanded(
                      child: _metaField(
                        techLabel,
                        job.techName,
                        labelStyle,
                        valueStyle,
                        dir,
                      ),
                    ),
                  ],
                ),
                if (job.companyName.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _metaField(
                    companyLabel,
                    job.companyName,
                    labelStyle,
                    valueStyle,
                    dir,
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ── AC Units section ──────────────────────────────────────────────
          _sectionBanner(unitsLabel, font, sectionStyle, _kBrandBlue),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: _shapeRowForPdf(locale, [unitTypeLabel, qtyLabel]),
            data: _shapeTableForPdf(
              locale,
              job.acUnits.map((u) => [u.type, '${u.quantity}']).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: isRtl
                ? pw.Alignment.centerLeft
                : pw.Alignment.centerRight,
            child: pw.Text(
              '$totalLabel: ${job.totalUnits}',
              style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
              textDirection: dir,
            ),
          ),
          pw.SizedBox(height: 14),

          // ── Additional charges section ─────────────────────────────────────
          if (job.charges != null) ...[
            _sectionBanner(
              chargesLabel,
              font,
              sectionStyle,
              PdfColors.blueGrey700,
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: _shapeRowForPdf(locale, [
                locale == 'ur'
                    ? 'آئٹم'
                    : locale == 'ar'
                    ? 'البند'
                    : 'Item',
                locale == 'ur'
                    ? 'شامل'
                    : locale == 'ar'
                    ? 'مضمن'
                    : 'Included',
                locale == 'ur'
                    ? 'رقم'
                    : locale == 'ar'
                    ? 'المبلغ'
                    : 'Amount (SAR)',
              ]),
              data: [
                [
                  bracketLabel,
                  ((job.charges!.bracketCount > 0) ||
                          job.charges!.acBracket ||
                          job.charges!.bracketAmount > 0)
                      ? yesLabel
                      : noLabel,
                  job.charges!.bracketCount > 0
                      ? '${job.charges!.bracketCount}'
                      : (job.charges!.acBracket &&
                                job.charges!.bracketAmount > 0
                            ? AppFormatters.currency(job.charges!.bracketAmount)
                            : '—'),
                ],
                [
                  '$deliveryLabel${job.charges!.deliveryNote.isNotEmpty ? " (${job.charges!.deliveryNote})" : ""}',
                  job.charges!.deliveryAmount > 0 ? yesLabel : noLabel,
                  job.charges!.deliveryAmount > 0
                      ? AppFormatters.currency(job.charges!.deliveryAmount)
                      : '—',
                ],
              ],
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: isRtl
                  ? pw.Alignment.centerLeft
                  : pw.Alignment.centerRight,
              child: pw.Text(
                '$totalLabel: ${AppFormatters.currency(job.totalCharges)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── Job expenses section ───────────────────────────────────────────
          if (job.expenses > 0) ...[
            _sectionBanner(expensesLabel, font, sectionStyle, _kRed),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  job.expenseNote.isNotEmpty ? job.expenseNote : '—',
                  style: cellStyle,
                  textDirection: dir,
                ),
                pw.Text(
                  AppFormatters.currency(job.expenses),
                  style: cellStyle.copyWith(
                    fontWeight: pw.FontWeight.bold,
                    color: _kRed,
                  ),
                  textDirection: dir,
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // ── Admin note ────────────────────────────────────────────────────
          if (job.adminNote.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: _kAmber, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                '${locale == "ur"
                    ? "ایڈمن نوٹ"
                    : locale == "ar"
                    ? "ملاحظة الإدارة"
                    : "Admin Note"}: ${job.adminNote}',
                style: cellStyle.copyWith(color: PdfColors.orange900),
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 14),
          ],

          // ── Signature strip ───────────────────────────────────────────────
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBox(sigLabel, font, dir, width: 160),
              _signatureBox(stampLabel, font, dir, width: 100),
              _signatureBox(
                '${locale == "ur"
                    ? "کلائنٹ"
                    : locale == "ar"
                    ? "العميل"
                    : "Client"}  $sigLabel',
                font,
                dir,
                width: 160,
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate today's invoices report grouped by company with totals.
  static Future<Uint8List> generateTodayCompanyInvoicesReport({
    required List<JobModel> jobs,
    String locale = 'en',
    String? reportTitle,
    String? periodLabel,
    String companyLogoBase64 = '',
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );

    final today = DateTime.now();
    final companyMap = <String, List<JobModel>>{};
    for (final job in jobs) {
      final key = job.companyName.trim().isEmpty
          ? (locale == 'ur'
                ? 'بغیر کمپنی'
                : locale == 'ar'
                ? 'بدون شركة'
                : 'No Company')
          : job.companyName.trim();
      companyMap.putIfAbsent(key, () => <JobModel>[]).add(job);
    }

    final sortedCompanies = companyMap.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final headers = locale == 'ur'
        ? ['کمپنی', 'انوائسز', 'کل یونٹس', 'ٹیکنیشنز']
        : locale == 'ar'
        ? ['الشركة', 'عدد الفواتير', 'إجمالي الوحدات', 'الفنيون']
        : ['Company', 'Invoices', 'Total Units', 'Technicians'];

    final title =
        reportTitle ??
        (locale == 'ur'
            ? 'آج کی کمپنی وائز انوائس رپورٹ'
            : locale == 'ar'
            ? 'تقرير فواتير اليوم حسب الشركة'
            : 'Today Company-wise Invoices');

    final totalInvoices = jobs.length;
    final totalUnits = jobs.fold<int>(0, (s, j) => s + j.totalUnits);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: periodLabel ?? AppFormatters.date(today),
          reportBranding: reportBranding,
          logoBase64: companyLogoBase64.isNotEmpty ? companyLogoBase64 : null,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          _statsBox(
            firstLabel: locale == 'ur'
                ? 'کل انوائسز'
                : locale == 'ar'
                ? 'إجمالي الفواتير'
                : 'Total Invoices',
            secondLabel: locale == 'ur'
                ? 'کل یونٹس'
                : locale == 'ar'
                ? 'إجمالي الوحدات'
                : 'Total Units',
            thirdLabel: locale == 'ur'
                ? 'کمپنیاں'
                : locale == 'ar'
                ? 'الشركات'
                : 'Companies',
            firstValue: '$totalInvoices',
            secondValue: '$totalUnits',
            thirdValue: '${sortedCompanies.length}',
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, headers),
            data: _shapeTableForPdf(
              locale,
              sortedCompanies.map((company) {
                final companyJobs = companyMap[company] ?? const <JobModel>[];
                final units = companyJobs.fold<int>(
                  0,
                  (s, j) => s + j.totalUnits,
                );
                final techs = companyJobs
                    .map((j) => j.techName.trim())
                    .where((n) => n.isNotEmpty)
                    .toSet()
                    .join(', ');
                return [
                  _safeTableCellText(company, maxLength: 42),
                  '${companyJobs.length}',
                  '$units',
                  _safeTableCellText(techs, maxLength: 120),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.centerLeft,
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            locale == 'ur'
                ? 'کل انوائسز: $totalInvoices  |  کل یونٹس: $totalUnits'
                : locale == 'ar'
                ? 'إجمالي الفواتير: $totalInvoices  |  إجمالي الوحدات: $totalUnits'
                : 'Total Invoices: $totalInvoices  |  Total Units: $totalUnits',
            style: subStyle.copyWith(fontWeight: pw.FontWeight.bold),
            textDirection: dir,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate detailed jobs report with bracket/delivery breakdown.
  /// Bracket logic: Include company-provided AND self-provided (both tracked).
  /// Delivery logic: Include if paid to company; exclude if customer paid cash.
  static Future<Uint8List> generateJobsDetailsReport({
    required List<JobModel> jobs,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    int maxPages = 2000,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final cellStyle = pw.TextStyle(font: font, fontSize: 6.6);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 7,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final tableHeaders = locale == 'ur'
        ? [
            'تاریخ',
            'انوائس نمبر',
            'رابطہ',
            'سپلٹ',
            'ونڈو',
            'اَن انسٹال',
            'دولاب',
            'بریکٹ',
            'ڈیلیوری',
            'ٹیکنیشن',
            'تفصیل',
          ]
        : locale == 'ar'
        ? [
            'التاريخ',
            'رقم الفاتورة',
            'الاتصال',
            'سبليت',
            'شباك',
            'فك تركيب',
            'دولاب',
            'الحامل',
            'التوصيل',
            'الفني',
            'الوصف',
          ]
        : [
            'Date',
            'Invoice Number',
            'Contact',
            'Split',
            'Window',
            'Uninstallation Total',
            'Free Standing',
            'Bracket',
            'Delivery',
            'Tech Name',
            'Description',
          ];

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;
    final totalUnits = jobs.fold<int>(0, (s, j) => s + j.totalUnits);
    final totalSplitUnits = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          j.acUnits
              .where((u) => u.type == 'Split AC')
              .fold<int>(0, (x, u) => x + u.quantity),
    );
    final totalWindowUnits = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          j.acUnits
              .where((u) => u.type == 'Window AC')
              .fold<int>(0, (x, u) => x + u.quantity),
    );
    final totalFreestandingUnits = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          j.acUnits
              .where((u) => u.type == 'Freestanding AC')
              .fold<int>(0, (x, u) => x + u.quantity),
    );
    final totalUninstallations = jobs.fold<int>(
      0,
      (s, j) =>
          s +
          j.acUnits
              .where(
                (u) =>
                    u.type == AppConstants.unitTypeUninstallOld ||
                    u.type == AppConstants.unitTypeUninstallSplit ||
                    u.type == AppConstants.unitTypeUninstallWindow ||
                    u.type == AppConstants.unitTypeUninstallFreestanding,
              )
              .fold<int>(0, (x, u) => x + u.quantity),
    );
    final totalInstalledBrackets = jobs.fold<int>(
      0,
      (s, j) => s + (j.charges?.bracketCount ?? 0),
    );
    final totalDeliveryCharges = jobs.fold<double>(
      0,
      (s, j) =>
          s +
          ((j.charges != null &&
                  !AppFormatters.isCustomerCashPaid(j.charges!.deliveryNote))
              ? j.charges!.deliveryAmount
              : 0),
    );
    final sharedJobs = jobs.where((j) => j.isSharedInstall).toList();
    final soloJobs = jobs.where((j) => !j.isSharedInstall).toList();
    final sharedJobsCount = sharedJobs.length;
    final soloJobsCount = soloJobs.length;
    final sharedUnitsTotal = sharedJobs.fold<int>(
      0,
      (sum, j) => sum + j.sharedInstallUnitsTotal,
    );
    final soloUnitsTotal = soloJobs.fold<int>(
      0,
      (sum, j) => sum + j.totalUnits,
    );

    final sharedByTechnician = <String, ({int jobs, int units})>{};
    for (final job in sharedJobs) {
      final key = job.techName.trim().isEmpty ? '-' : job.techName.trim();
      final current = sharedByTechnician[key] ?? (jobs: 0, units: 0);
      sharedByTechnician[key] = (
        jobs: current.jobs + 1,
        units: current.units + job.sharedInstallUnitsTotal,
      );
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        maxPages: maxPages,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: cellStyle, textDirection: dir),
            pw.SizedBox(height: 4),
          ],
          pw.TableHelper.fromTextArray(
            context: context,
            headers: _shapeRowForPdf(locale, tableHeaders),
            data: _shapeTableForPdf(
              locale,
              jobs.map((j) {
                final splitQty = j.acUnits
                    .where((u) => u.type == 'Split AC')
                    .fold<int>(0, (s, u) => s + u.quantity);
                final windowQty = j.acUnits
                    .where((u) => u.type == 'Window AC')
                    .fold<int>(0, (s, u) => s + u.quantity);
                final uninstallQty = j.acUnits
                    .where((u) => u.type == AppConstants.unitTypeUninstallOld)
                    .fold<int>(0, (s, u) => s + u.quantity);
                final uninstallSplitQty = j.acUnits
                    .where((u) => u.type == AppConstants.unitTypeUninstallSplit)
                    .fold<int>(0, (s, u) => s + u.quantity);
                final uninstallWindowQty = j.acUnits
                    .where(
                      (u) => u.type == AppConstants.unitTypeUninstallWindow,
                    )
                    .fold<int>(0, (s, u) => s + u.quantity);
                final uninstallStandingQty = j.acUnits
                    .where(
                      (u) =>
                          u.type == AppConstants.unitTypeUninstallFreestanding,
                    )
                    .fold<int>(0, (s, u) => s + u.quantity);
                final dolabQty = j.acUnits
                    .where((u) => u.type == 'Freestanding AC')
                    .fold<int>(0, (s, u) => s + u.quantity);
                final uninstallDetail = () {
                  final splitPart = uninstallSplitQty > 0
                      ? 'S:$uninstallSplitQty'
                      : '';
                  final windowPart = uninstallWindowQty > 0
                      ? 'W:$uninstallWindowQty'
                      : '';
                  final standingPart = uninstallStandingQty > 0
                      ? 'F:$uninstallStandingQty'
                      : '';
                  final parts = [
                    splitPart,
                    windowPart,
                    standingPart,
                  ].where((p) => p.isNotEmpty).toList();
                  if (parts.isNotEmpty) return parts.join('|');
                  return '';
                }();
                final uninstallTotal =
                    uninstallQty +
                    uninstallSplitQty +
                    uninstallWindowQty +
                    uninstallStandingQty;
                final bracketText = (j.charges?.bracketCount ?? 0) > 0
                    ? '${j.charges!.bracketCount}'
                    : '';
                final deliveryText =
                    j.charges != null &&
                        j.charges!.deliveryAmount > 0 &&
                        !AppFormatters.isCustomerCashPaid(
                          j.charges!.deliveryNote,
                        )
                    ? _plainAmount(j.charges!.deliveryAmount)
                    : '';
                final baseDescription = j.expenseNote.isNotEmpty
                    ? AppFormatters.safeText(j.expenseNote)
                    : (j.charges != null
                          ? AppFormatters.safeText(j.charges!.deliveryNote)
                          : '');
                final sharedInstallDescription = j.isSharedInstall
                    ? (locale == 'ur'
                          ? 'شیئرڈ: ${j.techName}'
                          : locale == 'ar'
                          ? 'مشترك: ${j.techName}'
                          : 'Shared: ${j.techName}')
                    : '';
                final description =
                    [baseDescription, sharedInstallDescription, uninstallDetail]
                        .where((p) => p.isNotEmpty)
                        .join(
                          [
                                    baseDescription,
                                    sharedInstallDescription,
                                    uninstallDetail,
                                  ].where((p) => p.isNotEmpty).length >
                                  1
                              ? ' | '
                              : '',
                        );
                return [
                  AppFormatters.date(j.date),
                  _safeTableCellText(j.invoiceNumber, maxLength: 24),
                  j.clientContact.isEmpty
                      ? ''
                      : _safeTableCellText(j.clientContact, maxLength: 20),
                  splitQty > 0 ? '$splitQty' : '',
                  windowQty > 0 ? '$windowQty' : '',
                  uninstallTotal > 0 ? '$uninstallTotal' : '',
                  dolabQty > 0 ? '$dolabQty' : '',
                  bracketText,
                  deliveryText,
                  _safeTableCellText(j.techName, maxLength: 24),
                  _safeTableCellText(description, maxLength: 70),
                ];
              }).toList(),
            ),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.0),
              1: const pw.FlexColumnWidth(1.0),
              2: const pw.FlexColumnWidth(1.0),
              3: const pw.FlexColumnWidth(0.55),
              4: const pw.FlexColumnWidth(0.55),
              5: const pw.FlexColumnWidth(0.75),
              6: const pw.FlexColumnWidth(0.65),
              7: const pw.FlexColumnWidth(0.75),
              8: const pw.FlexColumnWidth(0.75),
              9: const pw.FlexColumnWidth(1.0),
              10: const pw.FlexColumnWidth(2.0),
            },
            cellAlignments: {
              for (var i = 0; i < 11; i++) i: pw.Alignment.center,
              10: pw.Alignment.centerLeft,
              9: pw.Alignment.centerLeft,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 1.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: pw.WrapAlignment.spaceBetween,
            children: [
              pw.Text(
                '${locale == "ur"
                    ? "کل"
                    : locale == "ar"
                    ? "الإجمالي"
                    : "Total"}: ${jobs.length} ${locale == "ur"
                    ? "ملازمت"
                    : locale == "ar"
                    ? "وظائف"
                    : "jobs"}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "کل یونٹس"
                    : locale == "ar"
                    ? "إجمالي الوحدات"
                    : "Total Units"}: $totalUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "سپلٹ یونٹس"
                    : locale == "ar"
                    ? "وحدات سبليت"
                    : "Split Units"}: $totalSplitUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "ونڈو یونٹس"
                    : locale == "ar"
                    ? "وحدات الشباك"
                    : "Window Units"}: $totalWindowUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "دولاب یونٹس"
                    : locale == "ar"
                    ? "وحدات الدولاب"
                    : "Free Standing Units"}: $totalFreestandingUnits',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "کل اَن انسٹال"
                    : locale == "ar"
                    ? "إجمالي فك التركيب"
                    : "Total Uninstallations"}: $totalUninstallations',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "انسٹال بریکٹس"
                    : locale == "ar"
                    ? "الحوامل المركبة"
                    : "Brackets Installed"}: $totalInstalledBrackets',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "ڈیلیوری چارجز"
                    : locale == "ar"
                    ? "رسوم التوصيل"
                    : "Delivery Charges"}: ${_plainAmount(totalDeliveryCharges)}',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "سولو انسٹال"
                    : locale == "ar"
                    ? "تركيبات فردية"
                    : "Solo Installs"}: $soloJobsCount',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "شیئرڈ انسٹال"
                    : locale == "ar"
                    ? "تركيبات مشتركة"
                    : "Shared Installs"}: $sharedJobsCount',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "شیئرڈ یونٹس"
                    : locale == "ar"
                    ? "وحدات مشتركة"
                    : "Shared Units"}: $sharedUnitsTotal',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
              pw.Text(
                '${locale == "ur"
                    ? "سولو یونٹس"
                    : locale == "ar"
                    ? "وحدات فردية"
                    : "Solo Units"}: $soloUnitsTotal',
                style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                textDirection: dir,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          if (sharedByTechnician.isNotEmpty) ...[
            _sectionBanner(
              locale == 'ur'
                  ? 'شیئرڈ انسٹال کا تفصیل'
                  : locale == 'ar'
                  ? 'تفاصيل التركيبات المشتركة'
                  : 'Shared Installation Breakdown',
              font,
              pw.TextStyle(
                font: font,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              _kBrandBlue,
            ),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(
                locale,
                locale == 'ur'
                    ? ['ٹیکنیشن', 'شیئرڈ جابز', 'شیئرڈ یونٹس']
                    : locale == 'ar'
                    ? ['الفني', 'الأعمال المشتركة', 'الوحدات المشتركة']
                    : ['Technician', 'Shared Jobs', 'Shared Units'],
              ),
              data: _shapeTableForPdf(
                locale,
                sharedByTechnician.entries
                    .map(
                      (entry) => [
                        _safeTableCellText(entry.key, maxLength: 28),
                        '${entry.value.jobs}',
                        '${entry.value.units}',
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.8),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.0),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 2,
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          _sectionBanner(
            locale == 'ur'
                ? 'اَن انسٹال کا تفصیل'
                : locale == 'ar'
                ? 'تفاصيل فك التركيب'
                : 'Uninstallation Breakdown',
            font,
            pw.TextStyle(
              font: font,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            _kBrandBlue,
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'سپلٹ اَن انسٹال'
                        : locale == 'ar'
                        ? 'فك تركيب سبليت'
                        : 'Split Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallSplit).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'دولاب اَن انسٹال'
                        : locale == 'ar'
                        ? 'فك تركيب دولاب'
                        : 'Free Standing Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallFreestanding).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text(
                    locale == 'ur'
                        ? 'ونڈو اَن انسٹال'
                        : locale == 'ar'
                        ? 'فك تركيب النافذة'
                        : 'Window Uninstallations',
                    style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
                    textDirection: dir,
                  ),
                  pw.Text(
                    '${jobs.fold<int>(0, (s, j) => s + j.acUnits.where((u) => u.type == AppConstants.unitTypeUninstallWindow).fold<int>(0, (x, u) => x + u.quantity))}',
                    style: cellStyle.copyWith(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: _kBrandBlue,
                    ),
                    textDirection: dir,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate a one-page daily IN/OUT summary report for technician operations.
  static Future<Uint8List> generateTodayInOutReport({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    String locale = 'en',
    String? technicianName,
    String? reportTitle,
    DateTime? reportDate,
    String? periodLabel,
    bool monthlyMode = false,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);

    final periodDate = reportDate ?? DateTime.now();
    final workExpenses = expenses
        .where((e) => e.expenseType == AppConstants.expenseTypeWork)
        .toList();
    final homeExpenses = expenses
        .where((e) => e.expenseType == AppConstants.expenseTypeHome)
        .toList();

    final earnedToday = earnings.fold<double>(0, (s, e) => s + e.amount);
    final workTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    final homeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);
    final totalExpenses = workTotal + homeTotal;
    final net = earnedToday - totalExpenses;

    String amountPlain(double value) => value.toStringAsFixed(0);
    String amountWithSar(double value) => AppFormatters.currency(value);

    final byDay = <DateTime, Map<String, dynamic>>{};

    Map<String, dynamic> bucketFor(DateTime? date) {
      final d = date ?? periodDate;
      final key = DateTime(d.year, d.month, d.day);
      return byDay.putIfAbsent(
        key,
        () => {
          'earned': 0.0,
          'workTotal': 0.0,
          'homeTotal': 0.0,
          'earningParts': <String>[],
          'workParts': <String>[],
          'homeParts': <String>[],
        },
      );
    }

    for (final e in earnings) {
      final bucket = bucketFor(e.date);
      bucket['earned'] = (bucket['earned'] as double) + e.amount;
      (bucket['earningParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    for (final e in workExpenses) {
      final bucket = bucketFor(e.date);
      bucket['workTotal'] = (bucket['workTotal'] as double) + e.amount;
      (bucket['workParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    for (final e in homeExpenses) {
      final bucket = bucketFor(e.date);
      bucket['homeTotal'] = (bucket['homeTotal'] as double) + e.amount;
      (bucket['homeParts'] as List<String>).add(
        '${_translateCategoryForPdf(locale, AppFormatters.safeText(e.category))} (${amountPlain(e.amount)})',
      );
    }

    final sortedDays = byDay.keys.toList()..sort((a, b) => a.compareTo(b));

    List<String> rowForDay(DateTime day) {
      final bucket = byDay[day]!;
      final earned = bucket['earned'] as double;
      final work = bucket['workTotal'] as double;
      final home = bucket['homeTotal'] as double;
      final rowTotalExpenses = work + home;
      final rowNet = earned - rowTotalExpenses;
      final earningParts = bucket['earningParts'] as List<String>;
      final workParts = bucket['workParts'] as List<String>;
      final homeParts = bucket['homeParts'] as List<String>;

      final earningText = earningParts.isEmpty
          ? '-'
          : _safeTableCellText(earningParts.join(' | '), maxLength: 180);
      final workText = workParts.isEmpty
          ? '-'
          : _safeTableCellText(workParts.join(' | '), maxLength: 140);
      final homeText = homeParts.isEmpty
          ? '-'
          : _safeTableCellText(homeParts.join(' | '), maxLength: 180);

      return [
        AppFormatters.date(day),
        earningText,
        amountPlain(earned),
        workText,
        homeText,
        amountPlain(home),
        amountPlain(rowTotalExpenses),
        '${rowNet >= 0 ? '+' : '-'} ${amountPlain(rowNet.abs())}',
      ];
    }

    final tableRows = sortedDays.map(rowForDay).toList();
    if (tableRows.isEmpty) {
      final fallbackDate = monthlyMode
          ? DateTime(periodDate.year, periodDate.month, 1)
          : DateTime(periodDate.year, periodDate.month, periodDate.day);
      tableRows.add([
        AppFormatters.date(fallbackDate),
        '-',
        amountPlain(0),
        '-',
        '-',
        amountPlain(0),
        amountPlain(0),
        '+ ${amountPlain(0)}',
      ]);
    }

    if (monthlyMode && tableRows.length > 1) {
      final totalLabel = locale == 'ur'
          ? 'کل'
          : locale == 'ar'
          ? 'الإجمالي'
          : 'Total';
      tableRows.add([
        totalLabel,
        '-',
        amountWithSar(earnedToday),
        '-',
        '-',
        amountWithSar(homeTotal),
        amountWithSar(totalExpenses),
        '${net >= 0 ? '+' : '-'} ${amountWithSar(net.abs())}',
      ]);
    }

    final headers = locale == 'ur'
        ? [
            'تاریخ',
            'کمائی کی تفصیل',
            monthlyMode ? 'ماہ کی کمائی' : 'آج کی کمائی',
            'اخراجات',
            'گھر کے اخراجات کی تفصیل',
            'گھر کے اخراجات',
            monthlyMode ? 'ماہ کے کل اخراجات' : 'آج کے کل اخراجات',
            'خالص منافع/نقصان',
          ]
        : locale == 'ar'
        ? [
            'التاريخ',
            'تفاصيل الأرباح',
            monthlyMode ? 'أرباح الشهر' : 'أرباح اليوم',
            'المصروفات',
            'تفاصيل مصروفات المنزل',
            'مبلغ مصروفات المنزل',
            monthlyMode ? 'إجمالي مصروفات الشهر' : 'إجمالي مصروفات اليوم',
            'صافي الربح/الخسارة',
          ]
        : [
            'Date',
            'Earning Detail',
            monthlyMode ? 'Earned This Month' : 'Earned Today',
            'Expenses',
            'Home Expenses Details',
            'Home Expenses Amount',
            monthlyMode ? 'Total Expenses This Month' : 'Total Expenses Today',
            'Net Profit/Loss',
          ];

    final shapedHeaders = _shapeRowForPdf(locale, headers);
    final shapedRows = _shapeTableForPdf(locale, tableRows);

    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
        textDirection: dir,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle:
              reportTitle ??
              (monthlyMode
                  ? (locale == 'ur'
                        ? 'ماہانہ ان/آؤٹ رپورٹ'
                        : locale == 'ar'
                        ? 'تقرير شهري للدخول/الخروج'
                        : 'Monthly In/Out Report')
                  : (locale == 'ur'
                        ? 'آج کی ان/آؤٹ رپورٹ'
                        : locale == 'ar'
                        ? 'تقرير اليوم للدخول/الخروج'
                        : 'Today In/Out Report')),
          font: font,
          dir: dir,
          dateRange:
              periodLabel ??
              (monthlyMode
                  ? '${periodDate.month.toString().padLeft(2, '0')}/${periodDate.year}'
                  : AppFormatters.date(periodDate)),
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: cellStyle, textDirection: dir),
            pw.SizedBox(height: 6),
          ],
          pw.TableHelper.fromTextArray(
            context: context,
            headers: shapedHeaders,
            data: shapedRows,
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.75),
              1: const pw.FlexColumnWidth(3.2),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(2.2),
              5: const pw.FlexColumnWidth(1.1),
              6: const pw.FlexColumnWidth(1.4),
              7: const pw.FlexColumnWidth(1.0),
            },
            cellAlignments: {
              for (var i = 0; i < 8; i++) i: pw.Alignment.centerLeft,
              0: pw.Alignment.center,
              2: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate earnings report with today + month summaries by category.
  static Future<Uint8List> generateEarningsReport({
    required List<EarningModel> earnings,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      color: PdfColors.grey700,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final summaryStyle = cellStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final earningsHeaders = locale == 'ur'
        ? ['زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];

    final totalEarningsAmt = earnings.fold<double>(0, (s, e) => s + e.amount);
    final today = DateTime.now();
    final todaysEarnings = earnings
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();
    final todaysTotal = todaysEarnings.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: subStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],
          // KPI summary
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      locale == 'ur'
                          ? 'آج کی کمائی'
                          : locale == 'ar'
                          ? 'أرباح اليوم'
                          : 'Today Earned',
                      style: subStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(todaysTotal),
                      style: summaryStyle.copyWith(color: _kGreen),
                      textDirection: dir,
                    ),
                  ],
                ),
                pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
                pw.Column(
                  children: [
                    pw.Text(
                      locale == 'ur'
                          ? 'ماہ کی کمائی'
                          : locale == 'ar'
                          ? 'أرباح الشهر'
                          : 'Month Earned',
                      style: subStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(totalEarningsAmt),
                      style: summaryStyle.copyWith(color: _kGreen),
                      textDirection: dir,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          // Earnings table
          if (earnings.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, earningsHeaders),
              data: _shapeTableForPdf(
                locale,
                earnings
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kGreen),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            )
          else
            pw.Text(
              locale == 'ur'
                  ? 'کوئی کمائی نہیں'
                  : locale == 'ar'
                  ? 'لا توجد أرباح'
                  : 'No earnings',
              style: cellStyle,
              textDirection: dir,
            ),
        ],
      ),
    );
    return pdf.save();
  }

  /// Generate detailed expenses report split by work and home categories.
  static Future<Uint8List> generateExpensesDetailedReport({
    required List<ExpenseModel> expenses,
    required String title,
    String locale = 'en',
    String? technicianName,
    DateTime? fromDate,
    DateTime? toDate,
    ReportBrandingContext? reportBranding,
  }) async {
    const workExpenseType = 'work';
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final cellStyle = pw.TextStyle(font: font, fontSize: 8);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    final summaryStyle = cellStyle.copyWith(fontWeight: pw.FontWeight.bold);

    final workHeaders = locale == 'ur'
        ? ['زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];

    final homeHeaders = locale == 'ur'
        ? ['سامان', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['البند', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Item', 'Amount (SAR)', 'Date', 'Note'];

    final workExpenses = expenses
        .where((e) => e.expenseType == workExpenseType)
        .toList();
    final homeExpenses = expenses
        .where((e) => e.expenseType != workExpenseType)
        .toList();

    final today = DateTime.now();
    final todaysWork = workExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();
    final todaysHome = homeExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == today.year &&
              e.date!.month == today.month &&
              e.date!.day == today.day,
        )
        .toList();

    final todaysWorkTotal = todaysWork.fold<double>(0, (s, e) => s + e.amount);
    final todaysHomeTotal = todaysHome.fold<double>(0, (s, e) => s + e.amount);
    final monthWorkTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    final monthHomeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 16, 24, 16),
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        header: (ctx) => _pageHeader(
          ctx,
          reportTitle: title,
          font: font,
          dir: dir,
          dateRange: dateRange,
          reportBranding: reportBranding,
        ),
        footer: (ctx) => _pageFooter(
          ctx,
          font: font,
          dir: dir,
          reportBranding: reportBranding,
        ),
        build: (context) => [
          if (technicianName != null) ...[
            pw.Text(technicianName, style: cellStyle, textDirection: dir),
            pw.SizedBox(height: 8),
          ],
          // Summary KPI box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Today summary
                pw.Text(
                  locale == 'ur'
                      ? 'آج کے اخراجات'
                      : locale == 'ar'
                      ? 'نفقات اليوم'
                      : 'Today Expenses',
                  style: sectionStyle,
                  textDirection: dir,
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${locale == "ur"
                          ? "کام"
                          : locale == "ar"
                          ? "عمل"
                          : "Work"}: ${AppFormatters.currency(todaysWorkTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      '${locale == "ur"
                          ? "گھر"
                          : locale == "ar"
                          ? "منزل"
                          : "Home"}: ${AppFormatters.currency(todaysHomeTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(todaysWorkTotal + todaysHomeTotal),
                      style: summaryStyle.copyWith(color: _kRed),
                      textDirection: dir,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Month summary
                pw.Text(
                  locale == 'ur'
                      ? 'ماہ کے اخراجات'
                      : locale == 'ar'
                      ? 'نفقات الشهر'
                      : 'Month Expenses',
                  style: sectionStyle,
                  textDirection: dir,
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${locale == "ur"
                          ? "کام"
                          : locale == "ar"
                          ? "عمل"
                          : "Work"}: ${AppFormatters.currency(monthWorkTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      '${locale == "ur"
                          ? "گھر"
                          : locale == "ar"
                          ? "منزل"
                          : "Home"}: ${AppFormatters.currency(monthHomeTotal)}',
                      style: cellStyle,
                      textDirection: dir,
                    ),
                    pw.Text(
                      AppFormatters.currency(monthWorkTotal + monthHomeTotal),
                      style: summaryStyle.copyWith(color: _kRed),
                      textDirection: dir,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          // Work expenses section
          if (workExpenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kRed, width: 3)),
              ),
              child: pw.Text(
                locale == 'ur'
                    ? 'کام کے اخراجات'
                    : locale == 'ar'
                    ? 'نفقات العمل'
                    : 'Work Expenses',
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, workHeaders),
              data: _shapeTableForPdf(
                locale,
                workExpenses
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kRed),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          // Home expenses section
          if (homeExpenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.deepOrange, width: 3),
                ),
              ),
              child: pw.Text(
                locale == 'ur'
                    ? 'گھر کے اخراجات'
                    : locale == 'ar'
                    ? 'نفقات المنزل'
                    : 'Home Expenses',
                style: sectionStyle,
                textDirection: dir,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: _shapeRowForPdf(locale, homeHeaders),
              data: _shapeTableForPdf(
                locale,
                homeExpenses
                    .map(
                      (e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ],
                    )
                    .toList(),
              ),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.deepOrange,
              ),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  // ── Helper widget builders ──────────────────────────────────────────────────

  static pw.Widget _metaField(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
    pw.TextDirection dir,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: labelStyle, textDirection: dir),
        pw.Text(value, style: valueStyle, textDirection: dir),
      ],
    );
  }

  static pw.Widget _sectionBanner(
    String label,
    pw.Font? font,
    pw.TextStyle style,
    PdfColor color,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(label, style: style),
    );
  }

  static pw.Widget _signatureBox(
    String label,
    pw.Font? font,
    pw.TextDirection dir, {
    double width = 140,
  }) {
    return pw.Container(
      width: width,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 40,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
            textDirection: dir,
          ),
        ],
      ),
    );
  }

  // ── Output helpers ──────────────────────────────────────────────────────────

  /// Share or print the generated PDF bytes via the system share sheet.
  static Future<void> sharePdfBytes(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Show an interactive print/share preview for a jobs report.
  /// For large reports (>20 jobs), PDF generation happens in an isolate to prevent UI freeze.
  static Future<void> previewPdf(
    BuildContext context,
    List<JobModel> jobs,
    String locale,
    ReportBrandingContext? reportBranding,
  ) async {
    if (!context.mounted) return;

    final reportTitle = locale == 'ur'
        ? 'ملازمتوں کی رپورٹ'
        : locale == 'ar'
        ? 'تقرير الوظائف'
        : 'Jobs Report';

    Uint8List bytes;

    try {
      if (jobs.length > 20) {
        // Use isolate for large reports to avoid UI freeze
        bytes = await _generatePdfInIsolate(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          useDetails: true,
          maxPages: 2000,
          reportBranding: reportBranding,
        );
      } else {
        // Small reports can be generated on main thread
        bytes = await generateJobsDetailsReport(
          jobs: jobs,
          maxPages: 2000,
          title: reportTitle,
          locale: locale,
          reportBranding: reportBranding,
        );
      }
    } catch (_) {
      if (jobs.length > 20) {
        // Fallback to simpler report in isolate
        bytes = await _generatePdfInIsolate(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          useDetails: false,
          reportBranding: reportBranding,
        );
      } else {
        // Fallback for small reports
        bytes = await generateJobsReport(
          jobs: jobs,
          title: reportTitle,
          locale: locale,
          reportBranding: reportBranding,
        );
      }
    }

    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    }
  }

  /// Generate PDF in isolate for large reports.
  static Future<Uint8List> _generatePdfInIsolate({
    required List<JobModel> jobs,
    required String title,
    required String locale,
    required bool useDetails,
    int maxPages = 2000,
    ReportBrandingContext? reportBranding,
  }) async {
    return compute(
      _isolatePdfGeneration,
      _PdfGenerationParams(
        jobs: jobs,
        title: title,
        locale: locale,
        useDetails: useDetails,
        maxPages: maxPages,
        serviceCompanyName: reportBranding?.serviceCompany.name ?? '',
        serviceCompanyLogoBase64:
            reportBranding?.serviceCompany.logoBase64 ?? '',
        serviceCompanyPhoneNumber:
            reportBranding?.serviceCompany.phoneNumber ?? '',
        clientCompanyName: reportBranding?.clientCompany?.name ?? '',
        clientCompanyLogoBase64:
            reportBranding?.clientCompany?.logoBase64 ?? '',
      ),
    );
  }
}
