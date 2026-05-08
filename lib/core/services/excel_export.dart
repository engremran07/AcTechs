import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';

/// Helper service for generating Excel exports of jobs, earnings, and expenses.
class ExcelExport {
  ExcelExport._();

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static void _centerRow(excel_pkg.Sheet sheet, int rowIndex) {
    if (rowIndex >= sheet.maxRows) return;
    for (final cell in sheet.rows[rowIndex]) {
      if (cell != null) {
        cell.cellStyle = excel_pkg.CellStyle(
          horizontalAlign: excel_pkg.HorizontalAlign.Center,
        );
      }
    }
  }

  static void _appendReportBrandingHeader({
    required excel_pkg.Sheet sheet,
    required String reportTitle,
    required DateTime generatedAt,
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
      excel_pkg.TextCellValue(AppFormatters.dateTime(generatedAt)),
    ]);
    sheet.appendRow([excel_pkg.TextCellValue('')]);
  }

  static excel_pkg.Excel buildJobsWorkbook({
    required List<JobModel> jobs,
    Map<String, List<String>> sharedInstallerNamesByGroup =
        const <String, List<String>>{},
    ReportBrandingContext? reportBranding,
    DateTime? generatedAt,
  }) {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1');
    final sheet = excelFile['Jobs'];
    final reportTime = generatedAt ?? DateTime.now();

    _appendReportBrandingHeader(
      sheet: sheet,
      reportTitle: 'Jobs Report',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );

    sheet.appendRow([
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Invoice Number'),
      excel_pkg.TextCellValue('Shared Install'),
      excel_pkg.TextCellValue('Shared Technicians'),
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
    _centerRow(sheet, sheet.maxRows - 1);

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
        excel_pkg.TextCellValue(_formatDate(job.date)),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.invoiceNumber)),
        excel_pkg.TextCellValue(job.isSharedInstall ? 'Yes' : 'No'),
        excel_pkg.TextCellValue(
          AppFormatters.safeText(
            (sharedInstallerNamesByGroup[job.sharedInstallGroupKey] ??
                    const <String>[])
                .join(', '),
          ),
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
      _centerRow(sheet, sheet.maxRows - 1);
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
    _centerRow(sheet, sheet.maxRows - 1);
    sheet.appendRow([
      excel_pkg.TextCellValue('Bracket Zero Price Count'),
      excel_pkg.IntCellValue(totalBracketZeroPriceJobs),
    ]);
    _centerRow(sheet, sheet.maxRows - 1);

    return excelFile;
  }

  static excel_pkg.Excel buildEarningsWorkbook({
    required List<EarningModel> earnings,
    ReportBrandingContext? reportBranding,
    DateTime? generatedAt,
  }) {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1');
    final sheet = excelFile['Earnings'];
    final reportTime = generatedAt ?? DateTime.now();

    _appendReportBrandingHeader(
      sheet: sheet,
      reportTitle: 'Earnings Report',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );

    sheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(sheet, sheet.maxRows - 1);

    for (final earning in earnings) {
      sheet.appendRow([
        excel_pkg.TextCellValue(earning.category),
        excel_pkg.DoubleCellValue(earning.amount),
        excel_pkg.TextCellValue(_formatDate(earning.date)),
        excel_pkg.TextCellValue(earning.note),
      ]);
      _centerRow(sheet, sheet.maxRows - 1);
    }

    final totalEarnings = earnings.fold<double>(0, (s, e) => s + e.amount);
    sheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(totalEarnings),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(sheet, sheet.maxRows - 1);

    return excelFile;
  }

  static excel_pkg.Excel buildExpensesWorkbook({
    required List<ExpenseModel> expenses,
    ReportBrandingContext? reportBranding,
    DateTime? generatedAt,
  }) {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1');
    final reportTime = generatedAt ?? DateTime.now();

    final workSheet = excelFile['Work Expenses'];
    _appendReportBrandingHeader(
      sheet: workSheet,
      reportTitle: 'Expenses Report',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    workSheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(workSheet, workSheet.maxRows - 1);

    final workExpenses = expenses
        .where((e) => e.expenseType == 'work')
        .toList();
    for (final expense in workExpenses) {
      workSheet.appendRow([
        excel_pkg.TextCellValue(expense.category),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(_formatDate(expense.date)),
        excel_pkg.TextCellValue(expense.note),
      ]);
      _centerRow(workSheet, workSheet.maxRows - 1);
    }

    final workTotal = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    workSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(workTotal),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(workSheet, workSheet.maxRows - 1);

    final homeSheet = excelFile['Home Expenses'];
    _appendReportBrandingHeader(
      sheet: homeSheet,
      reportTitle: 'Expenses Report',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    homeSheet.appendRow([
      excel_pkg.TextCellValue('Item'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(homeSheet, homeSheet.maxRows - 1);

    final homeExpenses = expenses
        .where((e) => e.expenseType != 'work')
        .toList();
    for (final expense in homeExpenses) {
      homeSheet.appendRow([
        excel_pkg.TextCellValue(expense.category),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(_formatDate(expense.date)),
        excel_pkg.TextCellValue(expense.note),
      ]);
      _centerRow(homeSheet, homeSheet.maxRows - 1);
    }

    final homeTotal = homeExpenses.fold<double>(0, (s, e) => s + e.amount);
    homeSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(homeTotal),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(homeSheet, homeSheet.maxRows - 1);

    final summarySheet = excelFile['Summary'];
    _appendReportBrandingHeader(
      sheet: summarySheet,
      reportTitle: 'Expenses Summary',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    final todaysWork = workExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == reportTime.year &&
              e.date!.month == reportTime.month &&
              e.date!.day == reportTime.day,
        )
        .fold<double>(0, (s, e) => s + e.amount);
    final todaysHome = homeExpenses
        .where(
          (e) =>
              e.date != null &&
              e.date!.year == reportTime.year &&
              e.date!.month == reportTime.month &&
              e.date!.day == reportTime.day,
        )
        .fold<double>(0, (s, e) => s + e.amount);

    summarySheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Today (SAR)'),
      excel_pkg.TextCellValue('Month (SAR)'),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Work Expenses'),
      excel_pkg.DoubleCellValue(todaysWork),
      excel_pkg.DoubleCellValue(workTotal),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Home Expenses'),
      excel_pkg.DoubleCellValue(todaysHome),
      excel_pkg.DoubleCellValue(homeTotal),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(todaysWork + todaysHome),
      excel_pkg.DoubleCellValue(workTotal + homeTotal),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);

    return excelFile;
  }

  /// Export jobs to Excel with bracket/delivery details.
  static Future<void> exportJobsToExcel({
    required List<JobModel> jobs,
    Map<String, List<String>> sharedInstallerNamesByGroup =
        const <String, List<String>>{},
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = buildJobsWorkbook(
      jobs: jobs,
      sharedInstallerNamesByGroup: sharedInstallerNamesByGroup,
      reportBranding: reportBranding,
    );

    await _shareExcelFile(excelFile, 'jobs_report');
  }

  /// Export earnings to Excel with category breakdown.
  static Future<void> exportEarningsToExcel({
    required List<EarningModel> earnings,
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = buildEarningsWorkbook(
      earnings: earnings,
      reportBranding: reportBranding,
    );

    await _shareExcelFile(excelFile, 'earnings_report');
  }

  /// Export expenses to Excel split by work and home.
  static Future<void> exportExpensesToExcel({
    required List<ExpenseModel> expenses,
    String? technicianName,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = buildExpensesWorkbook(
      expenses: expenses,
      reportBranding: reportBranding,
    );

    await _shareExcelFile(excelFile, 'expenses_report');
  }

  /// Build a workbook combining earnings and expenses — used for In/Out reports.
  static excel_pkg.Excel buildInOutWorkbook({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    required DateTime reportDate,
    bool dailyMode = false,
    ReportBrandingContext? reportBranding,
    DateTime? generatedAt,
  }) {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1');
    final reportTime = generatedAt ?? DateTime.now();
    final title = dailyMode ? 'Daily In/Out Report' : 'Monthly In/Out Report';

    // ── Earnings sheet ──────────────────────────────────────────────────
    final earningsSheet = excelFile['Earnings'];
    _appendReportBrandingHeader(
      sheet: earningsSheet,
      reportTitle: title,
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    earningsSheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Status'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(earningsSheet, earningsSheet.maxRows - 1);
    for (final e in earnings) {
      earningsSheet.appendRow([
        excel_pkg.TextCellValue(e.category),
        excel_pkg.DoubleCellValue(e.amount),
        excel_pkg.TextCellValue(e.status.name),
        excel_pkg.TextCellValue(_formatDate(e.date)),
        excel_pkg.TextCellValue(e.note),
      ]);
      _centerRow(earningsSheet, earningsSheet.maxRows - 1);
    }
    final totalEarnings = earnings.fold<double>(0, (s, e) => s + e.amount);
    earningsSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(totalEarnings),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(earningsSheet, earningsSheet.maxRows - 1);

    // ── Work Expenses sheet ─────────────────────────────────────────────
    final workSheet = excelFile['Work Expenses'];
    _appendReportBrandingHeader(
      sheet: workSheet,
      reportTitle: title,
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    workSheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(workSheet, workSheet.maxRows - 1);
    final workExpenses = expenses
        .where((e) => e.expenseType == 'work')
        .toList();
    for (final e in workExpenses) {
      workSheet.appendRow([
        excel_pkg.TextCellValue(e.category),
        excel_pkg.DoubleCellValue(e.amount),
        excel_pkg.TextCellValue(_formatDate(e.date)),
        excel_pkg.TextCellValue(e.note),
      ]);
      _centerRow(workSheet, workSheet.maxRows - 1);
    }
    final totalWork = workExpenses.fold<double>(0, (s, e) => s + e.amount);
    workSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(totalWork),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(workSheet, workSheet.maxRows - 1);

    // ── Home Expenses sheet ─────────────────────────────────────────────
    final homeSheet = excelFile['Home Expenses'];
    _appendReportBrandingHeader(
      sheet: homeSheet,
      reportTitle: title,
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    homeSheet.appendRow([
      excel_pkg.TextCellValue('Item'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);
    _centerRow(homeSheet, homeSheet.maxRows - 1);
    final homeExpenses = expenses
        .where((e) => e.expenseType != 'work')
        .toList();
    for (final e in homeExpenses) {
      homeSheet.appendRow([
        excel_pkg.TextCellValue(e.category),
        excel_pkg.DoubleCellValue(e.amount),
        excel_pkg.TextCellValue(_formatDate(e.date)),
        excel_pkg.TextCellValue(e.note),
      ]);
      _centerRow(homeSheet, homeSheet.maxRows - 1);
    }
    final totalHome = homeExpenses.fold<double>(0, (s, e) => s + e.amount);
    homeSheet.appendRow([
      excel_pkg.TextCellValue('TOTAL'),
      excel_pkg.DoubleCellValue(totalHome),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(homeSheet, homeSheet.maxRows - 1);

    // ── Summary sheet ───────────────────────────────────────────────────
    final summarySheet = excelFile['Summary'];
    _appendReportBrandingHeader(
      sheet: summarySheet,
      reportTitle: title,
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Amount (SAR)'),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Total Income'),
      excel_pkg.DoubleCellValue(totalEarnings),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Work Expenses'),
      excel_pkg.DoubleCellValue(totalWork),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Home Expenses'),
      excel_pkg.DoubleCellValue(totalHome),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    final totalExpenses = totalWork + totalHome;
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Total Expenses'),
      excel_pkg.DoubleCellValue(totalExpenses),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);
    summarySheet.appendRow([
      excel_pkg.TextCellValue('Net Balance'),
      excel_pkg.DoubleCellValue(totalEarnings - totalExpenses),
    ]);
    _centerRow(summarySheet, summarySheet.maxRows - 1);

    return excelFile;
  }

  /// Export earnings + expenses In/Out report to Excel.
  static Future<void> exportInOutToExcel({
    required List<EarningModel> earnings,
    required List<ExpenseModel> expenses,
    required DateTime reportDate,
    bool dailyMode = false,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = buildInOutWorkbook(
      earnings: earnings,
      expenses: expenses,
      reportDate: reportDate,
      dailyMode: dailyMode,
      reportBranding: reportBranding,
    );
    final prefix = dailyMode ? 'daily_inout' : 'monthly_inout';
    await _shareExcelFile(excelFile, prefix);
  }

  /// Build a workbook for payment settlement report.
  static excel_pkg.Excel buildSettlementWorkbook({
    required List<JobModel> jobs,
    ReportBrandingContext? reportBranding,
    DateTime? generatedAt,
  }) {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1');
    final sheet = excelFile['Settlements'];
    final reportTime = generatedAt ?? DateTime.now();

    _appendReportBrandingHeader(
      sheet: sheet,
      reportTitle: 'Payment Settlement Report',
      generatedAt: reportTime,
      reportBranding: reportBranding,
    );

    sheet.appendRow([
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Invoice Number'),
      excel_pkg.TextCellValue('Technician'),
      excel_pkg.TextCellValue('Total Units'),
      excel_pkg.TextCellValue('Settlement Status'),
      excel_pkg.TextCellValue('Amount (SAR)'),
      excel_pkg.TextCellValue('Payment Method'),
    ]);
    _centerRow(sheet, sheet.maxRows - 1);

    var totalSettled = 0.0;
    for (final job in jobs) {
      final totalUnits = job.acUnits.fold<int>(0, (s, u) => s + u.quantity);
      final statusLabel = job.settlementStatus.name
          .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
          .trim();
      totalSettled += job.settlementAmount;
      sheet.appendRow([
        excel_pkg.TextCellValue(_formatDate(job.date)),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.invoiceNumber)),
        excel_pkg.TextCellValue(AppFormatters.safeText(job.techName)),
        excel_pkg.IntCellValue(totalUnits),
        excel_pkg.TextCellValue(statusLabel),
        excel_pkg.DoubleCellValue(job.settlementAmount),
        excel_pkg.TextCellValue(
          AppFormatters.safeText(job.settlementPaymentMethod),
        ),
      ]);
      _centerRow(sheet, sheet.maxRows - 1);
    }

    sheet.appendRow([excel_pkg.TextCellValue('')]);
    sheet.appendRow([
      excel_pkg.TextCellValue('TOTAL SETTLED'),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.TextCellValue(''),
      excel_pkg.DoubleCellValue(totalSettled),
      excel_pkg.TextCellValue(''),
    ]);
    _centerRow(sheet, sheet.maxRows - 1);

    return excelFile;
  }

  /// Export payment settlement report to Excel.
  static Future<void> exportSettlementToExcel({
    required List<JobModel> jobs,
    ReportBrandingContext? reportBranding,
  }) async {
    final excelFile = buildSettlementWorkbook(
      jobs: jobs,
      reportBranding: reportBranding,
    );
    await _shareExcelFile(excelFile, 'settlement_report');
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
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
