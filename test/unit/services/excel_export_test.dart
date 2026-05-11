import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/excel_export.dart';

void main() {
  String cellText(excel_pkg.Sheet sheet, String index) {
    return sheet
            .cell(excel_pkg.CellIndex.indexByString(index))
            .value
            ?.toString() ??
        '';
  }

  group('ExcelExport workbook builders', () {
    test(
      'buildJobsWorkbook uses per-type columns and aligns summary row',
      () {
        final workbook = ExcelExport.buildJobsWorkbook(
          jobs: [
            JobModel(
              techId: 'tech-1',
              techName: 'Tech One',
              companyId: 'company-1',
              companyName: 'AC Co',
              invoiceNumber: 'INV-100',
              clientName: 'Client',
              clientContact: '0500',
              isSharedInstall: true,
              sharedInstallGroupKey: 'company-1-inv-100',
              sharedInvoiceTotalUnits: 4,
              sharedContributionUnits: 2,
              sharedInvoiceSplitUnits: 4,
              sharedInvoiceBracketCount: 2,
              sharedDeliveryTeamCount: 2,
              techSplitShare: 2,
              techBracketShare: 1,
              charges: const InvoiceCharges(
                acBracket: true,
                bracketCount: 1,
                bracketAmount: 75,
              ),
              acUnits: const [AcUnit(type: 'Split AC', quantity: 2)],
              date: DateTime(2026, 4, 1),
            ),
          ],
          sharedInstallerNamesByGroup: const {
            'company-1-inv-100': ['Tech One', 'Tech Two'],
          },
          generatedAt: DateTime(2026, 4, 2, 9),
        );

        final sheet = workbook['Jobs'];
        // Branding header rows 1-4, column headers at row 5, data at row 6
        // 25 cols: A=Date B=Company C=Invoice D=Status E=Shared F=Team
        //          G=Inv.Split H=Tech.Split ... M=Inv.Bracket N=Tech.Bracket ...
        expect(cellText(sheet, 'A1'), 'Jobs Report');
        expect(cellText(sheet, 'B5'), 'Company');         // new admin column
        expect(cellText(sheet, 'C5'), 'Invoice');         // shifted right by 2
        expect(cellText(sheet, 'D5'), 'Status');          // new admin column
        expect(cellText(sheet, 'G5'), 'Inv.Split');       // per-type column
        expect(cellText(sheet, 'H5'), 'Tech.Split');      // renamed from My.Split
        expect(cellText(sheet, 'B6'), 'AC Co');           // company name
        expect(cellText(sheet, 'C6'), 'INV-100');         // invoice number
        expect(cellText(sheet, 'D6'), 'Pending');         // status (default)
        expect(cellText(sheet, 'E6'), 'Yes');             // shared
        expect(cellText(sheet, 'F6'), 'Tech One, Tech Two'); // team
        expect(cellText(sheet, 'G6'), '4');               // Inv.Split = sharedInvoiceSplitUnits
        expect(cellText(sheet, 'H6'), '2');               // Tech.Split = techSplitShare
        expect(cellText(sheet, 'M6'), '2');               // Inv.Bracket = sharedInvoiceBracketCount
        expect(cellText(sheet, 'N6'), '1');               // Tech.Bracket = techBracketShare
        // Summary row at row 8 (blank separator at row 7)
        expect(cellText(sheet, 'A8'), 'SUMMARY');
        expect(cellText(sheet, 'H8'), '2');               // totalTechSplit
        expect(cellText(sheet, 'N8'), '1');               // totalTechBracket
      },
    );

    test('buildExpensesWorkbook separates work and home totals', () {
      final workbook = ExcelExport.buildExpensesWorkbook(
        expenses: [
          ExpenseModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Fuel',
            amount: 120,
            expenseType: 'work',
            date: DateTime(2026, 4, 2),
          ),
          ExpenseModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Groceries',
            amount: 80,
            expenseType: 'home',
            date: DateTime(2026, 4, 2),
          ),
        ],
        generatedAt: DateTime(2026, 4, 2, 9),
      );

      // 5 cols: A=Tech B=Category C=Amount(SAR) D=Date E=Note
      expect(cellText(workbook['Work Expenses'], 'A5'), 'Tech');
      expect(cellText(workbook['Work Expenses'], 'A6'), 'Tech One');  // tech name
      expect(cellText(workbook['Work Expenses'], 'B6'), 'Fuel');       // category shifted to B
      expect(cellText(workbook['Work Expenses'], 'A7'), 'TOTAL');
      expect(cellText(workbook['Work Expenses'], 'C7'), '120.0');      // amount shifted to C

      expect(cellText(workbook['Home Expenses'], 'A6'), 'Tech One');   // tech name
      expect(cellText(workbook['Home Expenses'], 'B6'), 'Groceries');  // category shifted to B
      expect(cellText(workbook['Summary'], 'A6'), 'Work Expenses');
      expect(cellText(workbook['Summary'], 'B8'), '200.0');
      expect(cellText(workbook['Summary'], 'C8'), '200.0');
    });

    test('buildEarningsWorkbook appends a total row', () {
      final workbook = ExcelExport.buildEarningsWorkbook(
        earnings: [
          EarningModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Scrap Sale',
            amount: 250,
            date: DateTime(2026, 4, 2),
          ),
          EarningModel(
            techId: 'tech-1',
            techName: 'Tech One',
            category: 'Advance',
            amount: 100,
            date: DateTime(2026, 4, 2),
          ),
        ],
        generatedAt: DateTime(2026, 4, 2, 9),
      );

      final sheet = workbook['Earnings'];
      // 5 cols: A=Tech B=Category C=Amount(SAR) D=Date E=Note
      expect(cellText(sheet, 'A5'), 'Tech');
      expect(cellText(sheet, 'A6'), 'Tech One');  // tech name
      expect(cellText(sheet, 'B6'), 'Scrap Sale'); // category shifted to B
      expect(cellText(sheet, 'A8'), 'TOTAL');
      expect(cellText(sheet, 'C8'), '350.0');       // amount shifted to C
    });
  });
}
