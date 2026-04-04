import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';

/// Helper service for generating Excel exports of jobs, earnings, and expenses.
class ExcelExport {
  ExcelExport._();

  static void _appendReportBrandingHeader({
    required excel_pkg.Sheet sheet,
    required String reportTitle,
    ReportBrandingContext? reportBranding,
  }) {
    final serviceCompany = reportBranding?.serviceCompany;
    final clientCompany = reportBranding?.clientCompany;
    final serviceName = serviceCompany?.name.trim().isNotEmpty ?? false
        ? serviceCompany!.name.trim()
        : AppConstants.appName;

    sheet.appendRow([excel_pkg.TextCellValue(reportTitle)]);
    sheet.appendRow([
      excel_pkg.TextCellValue('Service Company'),
      excel_pkg.TextCellValue(serviceName),
    ]);
    if (serviceCompany?.phoneNumber.trim().isNotEmpty ?? false) {
      sheet.appendRow([
        excel_pkg.TextCellValue('Service Phone'),
        excel_pkg.TextCellValue(serviceCompany!.phoneNumber.trim()),
      ]);
    }
    if (clientCompany?.name.trim().isNotEmpty ?? false) {
      sheet.appendRow([
        excel_pkg.TextCellValue('Client Company'),
        excel_pkg.TextCellValue(clientCompany!.name.trim()),
      ]);
    }
    sheet.appendRow([
      excel_pkg.TextCellValue('Generated At'),
      excel_pkg.TextCellValue(AppFormatters.dateTime(DateTime.now())),
    ]);
    sheet.appendRow([excel_pkg.TextCellValue('')]);
  }

  /// Export jobs to Excel with bracket/delivery details.
  static Future<void> exportJobsToExcel({
    required List<JobModel> jobs,
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1
    final sheet = excelFile['Jobs'];

    _appendReportBrandingHeader(
      sheet: sheet,
      reportTitle: 'Jobs Report',
      reportBranding: reportBranding,
    );

    // Headers
    sheet.appendRow([
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Invoice Number'),
      excel_pkg.TextCellValue('Shared Install'),
      excel_pkg.TextCellValue('Shared Group Key'),
      excel_pkg.TextCellValue('Invoice Total Units'),
      excel_pkg.TextCellValue('My Share Units'),
      excel_pkg.TextCellValue('Contact'),
      excel_pkg.TextCellValue('Split'),
      excel_pkg.TextCellValue('Window'),
      excel_pkg.TextCellValue('Free Standing'),
      excel_pkg.TextCellValue('Bracket'),
      excel_pkg.TextCellValue('Invoice Brackets'),
      excel_pkg.TextCellValue('My Brackets'),
      excel_pkg.TextCellValue('Shared Team Size'),
      excel_pkg.TextCellValue('Delivery'),
      excel_pkg.TextCellValue('Tech Name'),
      excel_pkg.TextCellValue('Description'),
      excel_pkg.TextCellValue('Uninstallation Total'),
      excel_pkg.TextCellValue('Uninstall Split'),
      excel_pkg.TextCellValue('Uninstall Window'),
      excel_pkg.TextCellValue('Uninstall Standing'),
      excel_pkg.TextCellValue('Uninstall Old'),
    ]);

    var totalSplit = 0;
    var totalWindow = 0;
    var totalStanding = 0;
    var totalBracketJobs = 0;
    var totalBracketZeroPriceJobs = 0;
    var totalUninstall = 0;
    var totalUninstallSplit = 0;
    var totalUninstallWindow = 0;
    var totalUninstallStanding = 0;
    var totalUninstallOld = 0;

    // Data
    for (final job in jobs) {
      final splitQty = job.acUnits
          .where((u) => u.type == 'Split AC')
          .fold<int>(0, (s, u) => s + u.quantity);
      final windowQty = job.acUnits
          .where((u) => u.type == 'Window AC')
          .fold<int>(0, (s, u) => s + u.quantity);
      final uninstallQty = job.acUnits
          .where((u) => u.type == AppConstants.unitTypeUninstallOld)
          .fold<int>(0, (s, u) => s + u.quantity);
      final uninstallSplitQty = job.acUnits
          .where((u) => u.type == AppConstants.unitTypeUninstallSplit)
          .fold<int>(0, (s, u) => s + u.quantity);
      final uninstallWindowQty = job.acUnits
          .where((u) => u.type == AppConstants.unitTypeUninstallWindow)
          .fold<int>(0, (s, u) => s + u.quantity);
      final uninstallStandingQty = job.acUnits
          .where((u) => u.type == AppConstants.unitTypeUninstallFreestanding)
          .fold<int>(0, (s, u) => s + u.quantity);
      final dolabQty = job.acUnits
          .where((u) => u.type == 'Freestanding AC')
          .fold<int>(0, (s, u) => s + u.quantity);
      final uninstallDetail = () {
        final splitPart = uninstallSplitQty > 0 ? 'S:$uninstallSplitQty' : '';
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
        if (parts.isNotEmpty) return parts.join(' | ');
        return '';
      }();
      final uninstallTotal =
          uninstallQty +
          uninstallSplitQty +
          uninstallWindowQty +
          uninstallStandingQty;
      final contributionUnits = job.isSharedInstall
          ? (job.sharedContributionUnits > 0
                ? job.sharedContributionUnits
                : job.totalUnits)
          : job.totalUnits;
      totalSplit += splitQty;
      totalWindow += windowQty;
      totalStanding += dolabQty;
      totalUninstall += uninstallTotal;
      totalUninstallSplit += uninstallSplitQty;
      totalUninstallWindow += uninstallWindowQty;
      totalUninstallStanding += uninstallStandingQty;
      totalUninstallOld += uninstallQty;
      final bracketAmount = job.charges != null && job.charges!.acBracket
          ? job.charges!.bracketAmount
          : 0;
      if (job.charges?.acBracket ?? false) {
        totalBracketJobs++;
        if (bracketAmount <= 0) {
          totalBracketZeroPriceJobs++;
        }
      }
      final deliveryAmount =
          job.charges != null &&
              job.charges!.deliveryCharge &&
              !AppFormatters.isCustomerCashPaid(job.charges!.deliveryNote)
          ? job.charges!.deliveryAmount
          : 0;
      final baseDescription = job.expenseNote.isNotEmpty
          ? AppFormatters.safeText(job.expenseNote)
          : (job.charges != null
                ? AppFormatters.safeText(job.charges!.deliveryNote)
                : '');
      final description = [baseDescription, uninstallDetail]
          .where((p) => p.isNotEmpty)
          .join(
            baseDescription.isNotEmpty && uninstallDetail.isNotEmpty
                ? ' | '
                : '',
          );

      sheet.appendRow([
        excel_pkg.TextCellValue(
          job.date != null
              ? '${job.date!.day.toString().padLeft(2, '0')}/${job.date!.month.toString().padLeft(2, '0')}/${job.date!.year}'
              : '',
        ),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.invoiceNumber)),
        excel_pkg.TextCellValue(job.isSharedInstall ? 'Yes' : 'No'),
        excel_pkg.TextCellValue(
          AppFormatters.safeText(job.sharedInstallGroupKey),
        ),
        excel_pkg.IntCellValue(job.sharedInvoiceTotalUnits),
        excel_pkg.IntCellValue(contributionUnits),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.clientContact)),
        excel_pkg.IntCellValue(splitQty),
        excel_pkg.IntCellValue(windowQty),
        excel_pkg.IntCellValue(dolabQty),
        if (bracketAmount > 0)
          excel_pkg.DoubleCellValue(bracketAmount.toDouble())
        else
          excel_pkg.TextCellValue(''),
        excel_pkg.IntCellValue(job.sharedInvoiceBracketCount),
        excel_pkg.IntCellValue(job.techBracketShare),
        excel_pkg.IntCellValue(job.sharedDeliveryTeamCount),
        if (deliveryAmount > 0)
          excel_pkg.DoubleCellValue(deliveryAmount.toDouble())
        else
          excel_pkg.TextCellValue(''),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.techName)),
        excel_pkg.TextCellValue(description),
        excel_pkg.IntCellValue(uninstallTotal),
        excel_pkg.IntCellValue(uninstallSplitQty),
        excel_pkg.IntCellValue(uninstallWindowQty),
        excel_pkg.IntCellValue(uninstallStandingQty),
        excel_pkg.IntCellValue(uninstallQty),
      ]);
    }

    sheet.appendRow([excel_pkg.TextCellValue('')]);
    sheet.appendRow([
      excel_pkg.TextCellValue('SUMMARY'),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.IntCellValue(totalSplit),
      excel_pkg.IntCellValue(totalWindow),
      excel_pkg.IntCellValue(totalStanding),
      excel_pkg.IntCellValue(totalBracketJobs),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.IntCellValue(totalUninstall),
      excel_pkg.IntCellValue(totalUninstallSplit),
      excel_pkg.IntCellValue(totalUninstallWindow),
      excel_pkg.IntCellValue(totalUninstallStanding),
      excel_pkg.IntCellValue(totalUninstallOld),
    ]);
    sheet.appendRow([
      excel_pkg.TextCellValue('Bracket Zero Price Count'),
      excel_pkg.IntCellValue(totalBracketZeroPriceJobs),
    ]);

    await _shareExcelFile(excelFile, 'jobs_report');
  }

  /// Export earnings to Excel with category breakdown.
  static Future<void> exportEarningsToExcel({
    required List<EarningModel> earnings,
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1
    final sheet = excelFile['Earnings'];

    _appendReportBrandingHeader(
      sheet: sheet,
      reportTitle: 'Earnings Report',
      reportBranding: reportBranding,
    );

    // Headers
    sheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);

    // Data
    for (final earning in earnings) {
      sheet.appendRow([
        excel_pkg.TextCellValue(earning.category),
        excel_pkg.DoubleCellValue(earning.amount),
        excel_pkg.TextCellValue(
          earning.date != null
              ? '${earning.date!.day.toString().padLeft(2, '0')}/${earning.date!.month.toString().padLeft(2, '0')}/${earning.date!.year}'
              : '',
        ),
        excel_pkg.TextCellValue(earning.note),
      ]);
    }

    // Summary row
    final totalEarnings = earnings.fold<double>(0, (s, e) => s + e.amount);
    sheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(totalEarnings),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);

    await _shareExcelFile(excelFile, 'earnings_report');
  }

  /// Export expenses to Excel split by work and home.
  static Future<void> exportExpensesToExcel({
    required List<ExpenseModel> expenses,
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1

    // Work sheet
    final workSheet = excelFile['Work Expenses'];
    _appendReportBrandingHeader(
      sheet: workSheet,
      reportTitle: 'Expenses Report',
      reportBranding: reportBranding,
    );
    workSheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);

    final workExpenses = expenses
        .where((e) => e.expenseType == 'work')
        .toList();
    for (final expense in workExpenses) {
      workSheet.appendRow([
        excel_pkg.TextCellValue(expense.category),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(
          expense.date != null
              ? '${expense.date!.day.toString().padLeft(2, '0')}/${expense.date!.month.toString().padLeft(2, '0')}/${expense.date!.year}'
              : '',
        ),
        excel_pkg.TextCellValue(expense.note),
      ]);
    }

    final workTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    workSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(workTotal),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);

    // Home sheet
    final homeSheet = excelFile['Home Expenses'];
    _appendReportBrandingHeader(
      sheet: homeSheet,
      reportTitle: 'Expenses Report',
      reportBranding: reportBranding,
    );
    homeSheet.appendRow([
      excel_pkg.TextCellValue('Item'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);

    final homeExpenses = expenses
        .where((e) => e.expenseType != 'work')
        .toList();
    for (final expense in homeExpenses) {
      homeSheet.appendRow([
        excel_pkg.TextCellValue(expense.category),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(
          expense.date != null
              ? '${expense.date!.day.toString().padLeft(2, '0')}/${expense.date!.month.toString().padLeft(2, '0')}/${expense.date!.year}'
              : '',
        ),
        excel_pkg.TextCellValue(expense.note),
      ]);
    }

    final homeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);
    homeSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(homeTotal),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);

    // Summary sheet
    final summarySheet = excelFile['Summary'];
    _appendReportBrandingHeader(
      sheet: summarySheet,
      reportTitle: 'Expenses Summary',
      reportBranding: reportBranding,
    );
    final now = DateTime.now();
    final todaysWork = workExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == now.year &&
              e.date!.month == now.month &&
              e.date!.day == now.day,
        )
        .fold<double>(0, (s, e) => s + e.amount);
    final todaysHome = homeExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == now.year &&
              e.date!.month == now.month &&
              e.date!.day == now.day,
        )
        .fold<double>(0, (s, e) => s + e.amount);

    summarySheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Today (SAR)'),
      excel_pkg.TextCellValue('Month (SAR)'),
    ]);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Work Expenses'),
      excel_pkg.DoubleCellValue(todaysWork),
      excel_pkg.DoubleCellValue(workTotal),
    ]);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Home Expenses'),
      excel_pkg.DoubleCellValue(todaysHome),
      excel_pkg.DoubleCellValue(homeTotal),
    ]);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(todaysWork + todaysHome),
      excel_pkg.DoubleCellValue(workTotal + homeTotal),
    ]);

    await _shareExcelFile(excelFile, 'expenses_report');
  }

  static Future<void> _shareExcelFile(
    excel_pkg.Excel excelFile,
    String baseFileName,
  ) async {
    final bytes = excelFile.save();
    if (bytes == null) return;

    final now = DateTime.now();
    final fileName =
        '${baseFileName}_${now.year}_${now.month.toString().padLeft(2, "0")}_${now.day.toString().padLeft(2, "0")}.xlsx';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort cleanup only.
      }
    }
  }
}
