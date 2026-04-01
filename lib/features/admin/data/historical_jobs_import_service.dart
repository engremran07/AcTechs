import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

class HistoricalImportResult {
  const HistoricalImportResult({
    required this.jobs,
    required this.skippedRows,
    required this.unresolvedTechnicians,
  });

  final List<JobModel> jobs;
  final int skippedRows;
  final int unresolvedTechnicians;
}

class HistoricalJobsImportService {
  HistoricalJobsImportService._();

  static HistoricalImportResult parseExcel({
    required Uint8List bytes,
    required List<UserModel> users,
    required String adminUid,
  }) {
    final workbook = excel_pkg.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const HistoricalImportResult(
        jobs: [],
        skippedRows: 0,
        unresolvedTechnicians: 0,
      );
    }

    final sheet = workbook.tables.values.first;
    final rows = sheet.rows;
    if (rows.isEmpty) {
      return const HistoricalImportResult(
        jobs: [],
        skippedRows: 0,
        unresolvedTechnicians: 0,
      );
    }

    final headerMap = _buildHeaderMap(rows.first);
    final byUid = <String, UserModel>{};
    final byEmail = <String, UserModel>{};
    final byName = <String, UserModel>{};
    for (final u in users) {
      byUid[u.uid.trim().toLowerCase()] = u;
      byEmail[u.email.trim().toLowerCase()] = u;
      byName[u.name.trim().toLowerCase()] = u;
    }

    final jobs = <JobModel>[];
    var skipped = 0;
    var unresolvedTech = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_rowIsEmpty(row)) continue;

      final invoice = _value(row, headerMap, ['invoice number', 'invoice']);
      if (invoice.isEmpty) {
        skipped++;
        continue;
      }

      final tech = _resolveUser(row, headerMap, byUid, byEmail, byName);
      if (tech == null) {
        unresolvedTech++;
        continue;
      }

      final splitQty = _intValue(row, headerMap, ['split']);
      final windowQty = _intValue(row, headerMap, ['window']);
      final standingQty = _intValue(row, headerMap, [
        'free standing',
        'freestanding',
      ]);
      final uninstallTotal = _intValue(row, headerMap, [
        'uninstallation total',
        'uninstalation split/window',
      ]);

      final description = _value(row, headerMap, ['description', 'note']);
      final uninstallSplit = _extractTaggedValue(description, 'S');
      final uninstallWindow = _extractTaggedValue(description, 'W');
      final uninstallStanding = _extractTaggedValue(description, 'F');
      final uninstallOld =
          (uninstallTotal -
                  uninstallSplit -
                  uninstallWindow -
                  uninstallStanding)
              .clamp(0, 9999);

      final units = <AcUnit>[];
      if (splitQty > 0) units.add(AcUnit(type: 'Split AC', quantity: splitQty));
      if (windowQty > 0) {
        units.add(AcUnit(type: 'Window AC', quantity: windowQty));
      }
      if (standingQty > 0) {
        units.add(AcUnit(type: 'Freestanding AC', quantity: standingQty));
      }
      if (uninstallOld > 0) {
        units.add(
          AcUnit(
            type: AppConstants.unitTypeUninstallOld,
            quantity: uninstallOld,
          ),
        );
      }
      if (uninstallSplit > 0) {
        units.add(
          AcUnit(
            type: AppConstants.unitTypeUninstallSplit,
            quantity: uninstallSplit,
          ),
        );
      }
      if (uninstallWindow > 0) {
        units.add(
          AcUnit(
            type: AppConstants.unitTypeUninstallWindow,
            quantity: uninstallWindow,
          ),
        );
      }
      if (uninstallStanding > 0) {
        units.add(
          AcUnit(
            type: AppConstants.unitTypeUninstallFreestanding,
            quantity: uninstallStanding,
          ),
        );
      }

      final bracket = _doubleValue(row, headerMap, ['bracket']);
      final delivery = _doubleValue(row, headerMap, ['delivery']);
      final date = _dateValue(row, headerMap, ['date']) ?? DateTime.now();
      final contact = _value(row, headerMap, ['contact', 'client contact']);
      final clientName = _value(row, headerMap, ['client name']);
      final companyName = _value(row, headerMap, ['company']);

      jobs.add(
        JobModel(
          techId: tech.uid,
          techName: tech.name,
          companyName: companyName,
          invoiceNumber: invoice,
          clientName: clientName.isEmpty ? 'Imported Client' : clientName,
          clientContact: contact,
          acUnits: units,
          status: JobStatus.approved,
          expenses: 0,
          expenseNote: description,
          adminNote: 'Imported historical record',
          approvedBy: adminUid,
          charges: InvoiceCharges(
            acBracket: bracket > 0,
            bracketAmount: bracket,
            deliveryCharge: delivery > 0,
            deliveryAmount: delivery,
            deliveryNote: description,
          ),
          date: date,
          submittedAt: date,
          reviewedAt: date,
        ),
      );
    }

    return HistoricalImportResult(
      jobs: jobs,
      skippedRows: skipped,
      unresolvedTechnicians: unresolvedTech,
    );
  }

  static bool _rowIsEmpty(List<excel_pkg.Data?> row) {
    for (final cell in row) {
      if ((cell?.value?.toString() ?? '').trim().isNotEmpty) return false;
    }
    return true;
  }

  static Map<String, int> _buildHeaderMap(List<excel_pkg.Data?> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = (headerRow[i]?.value?.toString() ?? '').trim().toLowerCase();
      if (key.isNotEmpty) map[key] = i;
    }
    return map;
  }

  static String _value(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> possibleKeys,
  ) {
    for (final k in possibleKeys) {
      final idx = headerMap[k];
      if (idx == null || idx >= row.length) continue;
      final v = (row[idx]?.value?.toString() ?? '').trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static int _intValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? double.tryParse(raw)?.round() ?? 0;
  }

  static double _doubleValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  static DateTime? _dateValue(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    List<String> keys,
  ) {
    final raw = _value(row, headerMap, keys);
    if (raw.isEmpty) return null;

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    final parts = raw.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = int.tryParse(parts[1]) ?? 1;
      final y = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(y, m, d);
    }
    return null;
  }

  static int _extractTaggedValue(String description, String tag) {
    final regex = RegExp('(^|\\s|\\|)$tag:(\\d+)', caseSensitive: false);
    final match = regex.firstMatch(description);
    return match == null ? 0 : int.tryParse(match.group(2) ?? '') ?? 0;
  }

  static UserModel? _resolveUser(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    Map<String, UserModel> byUid,
    Map<String, UserModel> byEmail,
    Map<String, UserModel> byName,
  ) {
    final uid = _value(row, headerMap, [
      'technician id',
      'tech id',
      'techid',
      'uid',
    ]).toLowerCase();
    if (uid.isNotEmpty && byUid.containsKey(uid)) return byUid[uid];

    final email = _value(row, headerMap, [
      'technician email',
      'tech email',
      'email',
    ]).toLowerCase();
    if (email.isNotEmpty && byEmail.containsKey(email)) return byEmail[email];

    final name = _value(row, headerMap, [
      'tech name',
      'technician name',
    ]).toLowerCase();
    if (name.isNotEmpty && byName.containsKey(name)) return byName[name];

    return null;
  }
}
