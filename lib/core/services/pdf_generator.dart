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
