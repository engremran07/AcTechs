import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/theme/app_fonts.dart';

/// Unified PDF report generator with RTL font support for all 3 locales.
class PdfGenerator {
  PdfGenerator._();

  /// Load the correct font for the locale (cached after first call).
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
    return null; // Use default Latin font
  }

  static pw.TextDirection _dir(String locale) =>
      (locale == 'ur' || locale == 'ar')
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;

  /// Generate a jobs report PDF.
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

    final pdf = pw.Document();
    final headerStyle = pw.TextStyle(
      font: font,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // Table headers
    final headers = locale == 'ur'
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

    final statusLabel = {
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

    // Build pages (30 rows per page)
    const rowsPerPage = 30;
    for (var pageStart = 0; pageStart < jobs.length; pageStart += rowsPerPage) {
      final pageJobs = jobs.skip(pageStart).take(rowsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: dir,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: isRtl
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: headerStyle, textDirection: dir),
                pw.SizedBox(height: 4),
                if (technicianName != null)
                  pw.Text(technicianName, style: subStyle, textDirection: dir),
                if (fromDate != null && toDate != null)
                  pw.Text(
                    '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}',
                    style: subStyle,
                    textDirection: dir,
                  ),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: headers,
                  data: pageJobs
                      .map(
                        (j) => [
                          j.invoiceNumber,
                          j.techName,
                          j.clientName,
                          AppFormatters.date(j.date),
                          '${j.totalUnits}',
                          AppFormatters.currency(j.expenses),
                          statusLabel[j.status.name] ?? j.status.name,
                        ],
                      )
                      .toList(),
                  headerStyle: headerCellStyle,
                  cellStyle: cellStyle,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF00D4FF),
                  ),
                  cellAlignments: {
                    for (var i = 0; i < 7; i++) i: pw.Alignment.center,
                  },
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Summary row
                if (pageStart + rowsPerPage >= jobs.length) ...[
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        locale == 'ur'
                            ? 'کل ملازمتیں: ${jobs.length}'
                            : locale == 'ar'
                            ? 'إجمالي الوظائف: ${jobs.length}'
                            : 'Total Jobs: ${jobs.length}',
                        style: cellStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: dir,
                      ),
                      pw.Text(
                        locale == 'ur'
                            ? 'کل اخراجات: ${AppFormatters.currency(jobs.fold(0.0, (s, j) => s + j.expenses))}'
                            : locale == 'ar'
                            ? 'إجمالي المصاريف: ${AppFormatters.currency(jobs.fold(0.0, (s, j) => s + j.expenses))}'
                            : 'Total Expenses: ${AppFormatters.currency(jobs.fold(0.0, (s, j) => s + j.expenses))}',
                        style: cellStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: dir,
                      ),
                    ],
                  ),
                ],
                pw.Spacer(),
                pw.Text(
                  'Generated by AC Techs • ${AppFormatters.date(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Generate a monthly expenses + income report PDF.
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

    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(
      font: font,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final subStyle = pw.TextStyle(
      font: font,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    final sectionStyle = pw.TextStyle(
      font: font,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final cellStyle = pw.TextStyle(font: font, fontSize: 9);
    final headerCellStyle = pw.TextStyle(
      font: font,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // Labels
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

    // Earnings table headers
    final earningsHeaders = locale == 'ur'
        ? ['زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Category', 'Amount (SAR)', 'Date', 'Note'];

    // Expenses table headers
    final expensesHeaders = locale == 'ur'
        ? ['نوع', 'زمرہ', 'رقم', 'تاریخ', 'نوٹ']
        : locale == 'ar'
        ? ['النوع', 'الفئة', 'المبلغ', 'التاريخ', 'ملاحظة']
        : ['Type', 'Category', 'Amount (SAR)', 'Date', 'Note'];

    final totalEarningsAmt = earnings.fold<double>(0, (s, e) => s + e.amount);
    final totalExpensesAmt = expenses.fold<double>(0, (s, e) => s + e.amount);
    final netProfit = totalEarningsAmt - totalExpensesAmt;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: dir,
        crossAxisAlignment: isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        build: (context) => [
          // Header
          pw.Text(title, style: headerStyle, textDirection: dir),
          pw.SizedBox(height: 4),
          if (technicianName != null)
            pw.Text(technicianName, style: subStyle, textDirection: dir),
          if (fromDate != null && toDate != null)
            pw.Text(
              '${AppFormatters.date(fromDate)} — ${AppFormatters.date(toDate)}',
              style: subStyle,
              textDirection: dir,
            ),
          pw.SizedBox(height: 12),

          // Summary row
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(totalEarningsLabel,
                        style: subStyle, textDirection: dir),
                    pw.Text(AppFormatters.currency(totalEarningsAmt),
                        style: cellStyle.copyWith(
                          color: PdfColors.green700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: dir),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(totalExpensesLabel,
                        style: subStyle, textDirection: dir),
                    pw.Text(AppFormatters.currency(totalExpensesAmt),
                        style: cellStyle.copyWith(
                          color: PdfColors.red700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: dir),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(netLabel, style: subStyle, textDirection: dir),
                    pw.Text(AppFormatters.currency(netProfit.abs()),
                        style: cellStyle.copyWith(
                          color:
                              netProfit >= 0 ? PdfColors.green700 : PdfColors.red700,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: dir),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Earnings section
          if (earnings.isNotEmpty) ...[
            pw.Text(earningsLabel, style: sectionStyle, textDirection: dir),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: earningsHeaders,
              data: earnings
                  .map((e) => [
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ])
                  .toList(),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF00C853),
              ),
              cellAlignments: {
                for (var i = 0; i < 4; i++) i: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Expenses section
          if (expenses.isNotEmpty) ...[
            pw.Text(expensesLabel, style: sectionStyle, textDirection: dir),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: expensesHeaders,
              data: expenses
                  .map((e) => [
                        e.expenseType,
                        e.category,
                        AppFormatters.currency(e.amount),
                        AppFormatters.date(e.date),
                        e.note,
                      ])
                  .toList(),
              headerStyle: headerCellStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFD50000),
              ),
              cellAlignments: {
                for (var i = 0; i < 5; i++) i: pw.Alignment.center,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 3,
              ),
            ),
          ],

          pw.Spacer(),
          pw.Text(
            'Generated by AC Techs • ${AppFormatters.date(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Share or print the generated PDF bytes.
  static Future<void> sharePdfBytes(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// Generate a jobs report and show a print/share preview.
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
