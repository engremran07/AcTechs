import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'dart:io';

/// Helper service for generating Excel exports of jobs, earnings, and expenses.
class ExcelExport {
  ExcelExport._();

  static String _safeText(String? value) {
    if (value == null) return '';
    return value.replaceAll('\n', ' ').trim();
  }

  static bool _isCustomerCashPaid(String? note) {
    final normalized = _safeText(note).toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('cash') ||
        normalized.contains('customer paid') ||
        normalized.contains('paid by customer');
  }

  /// Export jobs to Excel with bracket/delivery details.
  static Future<void> exportJobsToExcel({
    required List<JobModel> jobs,
    String? technicianName,
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1
    final sheet = excelFile['Jobs'];

    // Headers
    sheet.appendRow([
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Invoice Number'),
      excel_pkg.TextCellValue('Contact'),
      excel_pkg.TextCellValue('Split'),
      excel_pkg.TextCellValue('Window'),
      excel_pkg.TextCellValue('Free Standing'),
      excel_pkg.TextCellValue('Bracket'),
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
              !_isCustomerCashPaid(job.charges!.deliveryNote)
          ? job.charges!.deliveryAmount
          : 0;
      final baseDescription = job.expenseNote.isNotEmpty
          ? _safeText(job.expenseNote)
          : (job.charges != null ? _safeText(job.charges!.deliveryNote) : '');
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
        excel_pkg.TextCellValue(_safeText(job.invoiceNumber)),
        excel_pkg.TextCellValue(_safeText(job.clientContact)),
        excel_pkg.IntCellValue(splitQty),
        excel_pkg.IntCellValue(windowQty),
        excel_pkg.IntCellValue(dolabQty),
        if (bracketAmount > 0)
          excel_pkg.DoubleCellValue(bracketAmount.toDouble())
        else
          excel_pkg.TextCellValue(''),
        if (deliveryAmount > 0)
          excel_pkg.DoubleCellValue(deliveryAmount.toDouble())
        else
          excel_pkg.TextCellValue(''),
        excel_pkg.TextCellValue(_safeText(job.techName)),
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
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1
    final sheet = excelFile['Earnings'];

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
  }) async {
    final excelFile = excel_pkg.Excel.createExcel();
    excelFile.delete('Sheet1'); // Remove default Sheet1

    // Work sheet
    final workSheet = excelFile['Work Expenses'];
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
