import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/theme/app_fonts.dart';

// ─── Brand colours (mirrors arctic_theme.dart) ───────────────────────────────
const _kBrandBlue = PdfColor.fromInt(0xFF00D4FF); // arctic blue
const _kBrandDark = PdfColor.fromInt(0xFF0D1117); // near-black
const _kGreen = PdfColor.fromInt(0xFF00C853);
const _kRed = PdfColor.fromInt(0xFFD50000);
const _kAmber = PdfColor.fromInt(0xFFFFB300);

/// Unified PDF report generator with RTL font support for all 3 locales.
///
/// All public methods are `static` so callers do not need an instance.
/// Fonts are loaded lazily and cached for the lifetime of the process.
class PdfGenerator {
  PdfGenerator._();

  // ── Font cache ──────────────────────────────────────────────────────────────
  static pw.Font? _cachedUrduFont;
  static pw.Font? _cachedArabicFont;

  static Future<pw.Font?> _getLocaleFont(String locale) async {
    if (locale == 'ur') {
      _cachedUrduFont ??= pw.Font.ttf(
        await rootBundle.load(AppFonts.pdfFontAsset('ur')),
      );
      return _cachedUrduFont;
    }
    if (locale == 'ar') {
      _cachedArabicFont ??= pw.Font.ttf(
        await rootBundle.load(AppFonts.pdfFontAsset('ar')),
      );
      return _cachedArabicFont;
    }
    return null; // pdf package's built-in Latin font
  }

  static pw.TextDirection _dir(String locale) =>
      (locale == 'ur' || locale == 'ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;

  // ── Shared page decorators ──────────────────────────────────────────────────

  /// Top brand banner shown on every page of every report.
  static pw.Widget _pageHeader(
    pw.Context ctx, {
    required String reportTitle,
    required pw.Font? font,
    required pw.TextDirection dir,
    String? dateRange,
  }) {
    return pw.Column(children: [
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const pw.BoxDecoration(color: _kBrandBlue),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'AC TECHS',
              style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _kBrandDark,
              ),
              textDirection: dir,
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _kBrandDark,
                  ),
                  textDirection: dir,
                ),
                if (dateRange != null)
                  pw.Text(
                    dateRange,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: _kBrandDark,
                    ),
                    textDirection: dir,
                  ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
    ]);
  }

  /// Bottom strip shown on every page: confidentiality note + page numbers.
  static pw.Widget _pageFooter(
    pw.Context ctx, {
    required pw.Font? font,
    required pw.TextDirection dir,
  }) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300, thickness: 0.5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'AC Techs — Confidential',
            style: pw.TextStyle(
              font: font,
              fontSize: 7,
              color: PdfColors.grey600,
            ),
            textDirection: dir,
          ),
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
    ]);
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
    final subStyle = pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700);
    final valStyle = pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold);
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
          pw.Column(children: [
            pw.Text(earningsLabel, style: subStyle, textDirection: dir),
            pw.Text(
              AppFormatters.currency(totalEarnings),
              style: valStyle.copyWith(color: _kGreen),
              textDirection: dir,
            ),
          ]),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(children: [
            pw.Text(expensesLabel, style: subStyle, textDirection: dir),
            pw.Text(
              AppFormatters.currency(totalExpenses),
              style: valStyle.copyWith(color: _kRed),
              textDirection: dir,
            ),
          ]),
          pw.Container(width: 0.5, height: 32, color: PdfColors.grey300),
          pw.Column(children: [
            pw.Text(netLabel, style: subStyle, textDirection: dir),
            pw.Text(
              AppFormatters.currency(net.abs()),
              style: valStyle.copyWith(color: net >= 0 ? _kGreen : _kRed),
              textDirection: dir,
            ),
          ]),
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
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700);
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
        : ['Invoice', 'Technician', 'Client', 'Date', 'Units', 'Expenses', 'Status'];

    final statusMap = _statusLabels(locale);

    final dateRange = (fromDate != null && toDate != null)
        ? '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}'
        : null;

    final totalExpenses = jobs.fold<double>(0, (s, j) => s + j.expenses);
    final totalEarningsLabel = locale == 'ur' ? 'کل آمدنی' : locale == 'ar' ? 'إجمالي الإيرادات' : 'Total Earnings';
    final totalExpensesLabel = locale == 'ur' ? 'کل اخراجات' : locale == 'ar' ? 'إجمالي المصروفات' : 'Total Expenses';
    final netLabel = locale == 'ur' ? 'خالص منافع' : locale == 'ar' ? 'صافي الربح' : 'Net Profit';
    final totalJobsLabel = locale == 'ur'
        ? 'کل ملازمتیں: ${jobs.length}'
        : locale == 'ar'
        ? 'إجمالي الوظائف: ${jobs.length}'
        : 'Total Jobs: ${jobs.length}';

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
        ),
        footer: (ctx) => _pageFooter(ctx, font: font, dir: dir),
        build: (context) => [
          // Technician / date meta
          if (technicianName != null)
            pw.Text(technicianName, style: subStyle, textDirection: dir),
          pw.SizedBox(height: 10),

          // KPI summary box
          _kpiBox(
            earningsLabel: totalEarningsLabel,
            expensesLabel: totalExpensesLabel,
            netLabel: netLabel,
            totalEarnings: 0,
            totalExpenses: totalExpenses,
            font: font,
            dir: dir,
          ),
          pw.SizedBox(height: 12),

          // Jobs table
          pw.TableHelper.fromTextArray(
            context: context,
            headers: tableHeaders,
            data: jobs.map((j) {
              final statusText = statusMap[j.status.name] ?? j.status.name;
              return [
                j.invoiceNumber,
                j.techName,
                j.clientName,
                AppFormatters.date(j.date),
                '${j.totalUnits}',
                AppFormatters.currency(j.expenses),
                statusText,
              ];
            }).toList(),
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
  }) async {
    final font = await _getLocaleFont(locale);
    final dir = _dir(locale);
    final isRtl = locale == 'ur' || locale == 'ar';

    final subStyle = pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700);
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
    final earningsLabel = locale == 'ur' ? 'آمدنی (IN)' : locale == 'ar' ? 'الإيرادات (الدخل)' : 'Earnings (IN)';
    final expensesLabel = locale == 'ur' ? 'اخراجات (OUT)' : locale == 'ar' ? 'المصروفات (الخروج)' : 'Expenses (OUT)';
    final totalEarningsLabel = locale == 'ur' ? 'کل آمدنی' : locale == 'ar' ? 'إجمالي الإيرادات' : 'Total Earnings';
    final totalExpensesLabel = locale == 'ur' ? 'کل اخراجات' : locale == 'ar' ? 'إجمالي المصروفات' : 'Total Expenses';
    final netLabel = locale == 'ur' ? 'خالص منافع' : locale == 'ar' ? 'صافي الربح' : 'Net Profit';
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
        ),
        footer: (ctx) => _pageFooter(ctx, font: font, dir: dir),
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
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kGreen, width: 3)),
              ),
              child: pw.Text(earningsLabel, style: sectionStyle, textDirection: dir),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: earningsHeaders,
              data: earnings.map((e) => [
                e.category,
                AppFormatters.currency(e.amount),
                AppFormatters.date(e.date),
                e.note,
              ]).toList(),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kGreen),
              cellAlignments: {for (var i = 0; i < 4; i++) i: pw.Alignment.center},
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Expenses section ───────────────────────────────────────────────
          if (expenses.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: _kRed, width: 3)),
              ),
              child: pw.Text(expensesLabel, style: sectionStyle, textDirection: dir),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: expensesHeaders,
              data: expenses.map((e) => [
                e.expenseType,
                e.category,
                AppFormatters.currency(e.amount),
                AppFormatters.date(e.date),
                e.note,
              ]).toList(),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: _kRed),
              cellAlignments: {for (var i = 0; i < 5; i++) i: pw.Alignment.center},
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
    final align = isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;

    final titleStyle = pw.TextStyle(font: font, fontSize: 20, fontWeight: pw.FontWeight.bold);
    final sectionStyle = pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final labelStyle = pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold);
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final headerCellStyle = pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white);

    // i18n field labels
    final invoiceLabel = locale == 'ur' ? 'انوائس نمبر' : locale == 'ar' ? 'رقم الفاتورة' : 'Invoice No.';
    final dateLabel = locale == 'ur' ? 'تاریخ' : locale == 'ar' ? 'التاريخ' : 'Date';
    final clientLabel = locale == 'ur' ? 'کلائنٹ' : locale == 'ar' ? 'العميل' : 'Client';
    final contactLabel = locale == 'ur' ? 'رابطہ' : locale == 'ar' ? 'التواصل' : 'Contact';
    final techLabel = locale == 'ur' ? 'ٹیکنیشن' : locale == 'ar' ? 'الفني' : 'Technician';
    final statusLabel = locale == 'ur' ? 'حالت' : locale == 'ar' ? 'الحالة' : 'Status';
    final companyLabel = locale == 'ur' ? 'کمپنی' : locale == 'ar' ? 'الشركة' : 'Company';
    final unitsLabel = locale == 'ur' ? 'اے سی یونٹس' : locale == 'ar' ? 'وحدات التكييف' : 'AC Units';
    final chargesLabel = locale == 'ur' ? 'اضافی چارجز' : locale == 'ar' ? 'رسوم إضافية' : 'Additional Charges';
    final expensesLabel = locale == 'ur' ? 'اخراجات' : locale == 'ar' ? 'المصاريف' : 'Job Expenses';
    final totalLabel = locale == 'ur' ? 'کل' : locale == 'ar' ? 'الإجمالي' : 'Total';
    final sigLabel = locale == 'ur' ? 'دستخط' : locale == 'ar' ? 'التوقيع' : 'Signature';
    final stampLabel = locale == 'ur' ? 'مہر' : locale == 'ar' ? 'الختم' : 'Stamp';
    final unitTypeLabel = locale == 'ur' ? 'قسم' : locale == 'ar' ? 'النوع' : 'Type';
    final qtyLabel = locale == 'ur' ? 'تعداد' : locale == 'ar' ? 'الكمية' : 'Qty';
    final bracketLabel = locale == 'ur' ? 'بریکٹ' : locale == 'ar' ? 'الحامل' : 'Bracket';
    final deliveryLabel = locale == 'ur' ? 'ڈیلیوری' : locale == 'ar' ? 'التوصيل' : 'Delivery';
    final yesLabel = locale == 'ur' ? 'ہاں' : locale == 'ar' ? 'نعم' : 'Yes';
    final noLabel = locale == 'ur' ? 'نہیں' : locale == 'ar' ? 'لا' : 'No';
    final invoiceTitle = locale == 'ur' ? 'سروس انوائس' : locale == 'ar' ? 'فاتورة الخدمة' : 'Service Invoice';

    final statusText = _statusLabels(locale)[job.status.name] ?? job.status.name;
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
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    pw.Expanded(child: _metaField(invoiceLabel, job.invoiceNumber, labelStyle, valueStyle, dir)),
                    pw.Expanded(child: _metaField(dateLabel, AppFormatters.date(job.date), labelStyle, valueStyle, dir)),
                    pw.Expanded(child: _metaField(statusLabel, statusText, labelStyle, valueStyle, dir)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(child: _metaField(clientLabel, job.clientName, labelStyle, valueStyle, dir)),
                    pw.Expanded(child: _metaField(contactLabel, job.clientContact.isEmpty ? '—' : job.clientContact, labelStyle, valueStyle, dir)),
                    pw.Expanded(child: _metaField(techLabel, job.techName, labelStyle, valueStyle, dir)),
                  ],
                ),
                if (job.companyName.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _metaField(companyLabel, job.companyName, labelStyle, valueStyle, dir),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ── AC Units section ──────────────────────────────────────────────
          _sectionBanner(unitsLabel, font, sectionStyle, _kBrandBlue),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [unitTypeLabel, qtyLabel],
            data: job.acUnits.map((u) => [u.type, '${u.quantity}']).toList(),
            headerStyle: headerCellStyle,
            cellStyle: cellStyle,
            headerDecoration: const pw.BoxDecoration(color: _kBrandBlue),
            cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          pw.SizedBox(height: 4),
          pw.Align(
            alignment: isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
            child: pw.Text(
              '$totalLabel: ${job.totalUnits}',
              style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold),
              textDirection: dir,
            ),
          ),
          pw.SizedBox(height: 14),

          // ── Additional charges section ─────────────────────────────────────
          if (job.charges != null) ...[
            _sectionBanner(chargesLabel, font, sectionStyle, PdfColors.blueGrey700),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                locale == 'ur' ? 'آئٹم' : locale == 'ar' ? 'البند' : 'Item',
                locale == 'ur' ? 'شامل' : locale == 'ar' ? 'مضمن' : 'Included',
                locale == 'ur' ? 'رقم' : locale == 'ar' ? 'المبلغ' : 'Amount (SAR)',
              ],
              data: [
                [
                  bracketLabel,
                  job.charges!.acBracket ? yesLabel : noLabel,
                  job.charges!.acBracket ? AppFormatters.currency(job.charges!.bracketAmount) : '—',
                ],
                [
                  '$deliveryLabel${job.charges!.deliveryNote.isNotEmpty ? " (${job.charges!.deliveryNote})" : ""}',
                  job.charges!.deliveryCharge ? yesLabel : noLabel,
                  job.charges!.deliveryCharge ? AppFormatters.currency(job.charges!.deliveryAmount) : '—',
                ],
              ],
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            pw.SizedBox(height: 4),
            pw.Align(
              alignment: isRtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
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
                  style: cellStyle.copyWith(fontWeight: pw.FontWeight.bold, color: _kRed),
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
                '${locale == "ur" ? "ایڈمن نوٹ" : locale == "ar" ? "ملاحظة الإدارة" : "Admin Note"}: ${job.adminNote}',
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
                '${locale == "ur" ? "کلائنٹ" : locale == "ar" ? "العميل" : "Client"}  $sigLabel',
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
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
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
  static Future<void> previewPdf(
    BuildContext context,
    List<JobModel> jobs,
    String locale,
  ) async {
    final bytes = await generateJobsReport(
      jobs: jobs,
      title: 'Jobs Report',
      locale: locale,
    );
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}
