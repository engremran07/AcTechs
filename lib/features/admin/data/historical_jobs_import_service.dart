import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

class HistoricalImportResult {
  const HistoricalImportResult({
    required this.jobs,
    required this.skippedRows,
    required this.unresolvedTechnicians,
    required this.sheetSummaries,
  });

  final List<JobModel> jobs;
  final int skippedRows;
  final int unresolvedTechnicians;
  final List<HistoricalImportSheetSummary> sheetSummaries;
}

class HistoricalImportSheetSummary {
  const HistoricalImportSheetSummary({
    required this.sheetName,
    required this.importedRows,
    required this.skippedRows,
    required this.unresolvedTechnicians,
    required this.installedSplit,
    required this.installedWindow,
    required this.installedFreestanding,
    required this.uninstallSplit,
    required this.uninstallWindow,
    required this.uninstallFreestanding,
    required this.uninstallOld,
  });

  final String sheetName;
  final int importedRows;
  final int skippedRows;
  final int unresolvedTechnicians;
  final int installedSplit;
  final int installedWindow;
  final int installedFreestanding;
  final int uninstallSplit;
  final int uninstallWindow;
  final int uninstallFreestanding;
  final int uninstallOld;
}

class HistoricalJobsImportService {
  HistoricalJobsImportService._();

  static const Map<String, int> _monthTokens = {
    'jan': 1,
    'january': 1,
    'feb': 2,
    'february': 2,
    'mar': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'may': 5,
    'jun': 6,
    'june': 6,
    'jul': 7,
    'july': 7,
    'aug': 8,
    'august': 8,
    'sep': 9,
    'sept': 9,
    'september': 9,
    'oct': 10,
    'october': 10,
    'nov': 11,
    'november': 11,
    'dec': 12,
    'december': 12,
  };

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static HistoricalImportResult parseExcel({
    required Uint8List bytes,
    required List<UserModel> users,
    required String adminUid,
    UserModel? targetUser,
    CompanyModel? targetCompany,
    String? technicianKeyword,
  }) {
    final workbook = excel_pkg.Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      return const HistoricalImportResult(
        jobs: [],
        skippedRows: 0,
        unresolvedTechnicians: 0,
        sheetSummaries: [],
      );
    }

    final byUid = <String, UserModel>{};
    final byEmail = <String, UserModel>{};
    final byName = <String, UserModel>{};
    for (final u in users) {
      byUid[u.uid.trim().toLowerCase()] = u;
      byEmail[u.email.trim().toLowerCase()] = u;
      byName[u.name.trim().toLowerCase()] = u;
    }

    final jobsByInvoice = <String, JobModel>{};
    final sheetSummaries = <HistoricalImportSheetSummary>[];
    var skipped = 0;
    var unresolvedTech = 0;
    final normalizedKeyword = technicianKeyword?.trim().toLowerCase() ?? '';

    for (final entry in workbook.tables.entries) {
      final sheetName = entry.key;
      final sheet = entry.value;
      final rows = sheet.rows;
      if (rows.isEmpty) continue;

      final sheetPeriodDate = _sheetPeriodDate(sheetName);
      final sheetPeriodLabel = _sheetPeriodLabel(sheetName, sheetPeriodDate);

      final headerMap = _buildHeaderMap(rows.first);
      if (headerMap.isEmpty) continue;

      var sheetImportedRows = 0;
      var sheetSkippedRows = 0;
      var sheetUnresolvedTechnicians = 0;
      var sheetInstalledSplit = 0;
      var sheetInstalledWindow = 0;
      var sheetInstalledFreestanding = 0;
      var sheetUninstallSplit = 0;
      var sheetUninstallWindow = 0;
      var sheetUninstallFreestanding = 0;
      var sheetUninstallOld = 0;
      final sheetUniqueInvoices = <String>{};

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (_rowIsEmpty(row)) continue;

        final rawInvoice = _value(row, headerMap, [
          'invoice number',
          'invoice',
        ]);
        final invoice = _normalizeInvoice(rawInvoice);
        if (invoice.isEmpty) {
          skipped++;
          sheetSkippedRows++;
          continue;
        }

        if (normalizedKeyword.isNotEmpty &&
            !_rowMatchesKeyword(row, headerMap, normalizedKeyword)) {
          skipped++;
          sheetSkippedRows++;
          continue;
        }

        final sourceTechName = _value(row, headerMap, [
          'tech name',
          'technician name',
        ]);

        final tech =
            targetUser ?? _resolveUser(row, headerMap, byUid, byEmail, byName);
        if (tech == null) {
          unresolvedTech++;
          sheetUnresolvedTechnicians++;
          continue;
        }

        final splitQty = _intValue(row, headerMap, ['split']);
        final windowQty = _intValue(row, headerMap, ['window']);
        final standingQty = _intValue(row, headerMap, [
          'free standing',
          'freestanding',
          'dolab',
        ]);
        final uninstallTotal = _intValue(row, headerMap, [
          'uninstallation total',
          'uninstallation',
        ]);

        final description = _value(row, headerMap, ['description', 'note']);
        final uninstallSplitTagged = _extractTaggedValue(description, 'S');
        final uninstallWindowTagged = _extractTaggedValue(description, 'W');
        final uninstallStandingTagged = _extractTaggedValue(description, 'F');

        final uninstallDistribution = _distributeUninstallTypes(
          uninstallTotal: uninstallTotal,
          splitInstalled: splitQty,
          windowInstalled: windowQty,
          freestandingInstalled: standingQty,
          splitTagged: uninstallSplitTagged,
          windowTagged: uninstallWindowTagged,
          freestandingTagged: uninstallStandingTagged,
        );

        final units = <AcUnit>[];
        if (splitQty > 0) {
          units.add(AcUnit(type: 'Split AC', quantity: splitQty));
        }
        if (windowQty > 0) {
          units.add(AcUnit(type: 'Window AC', quantity: windowQty));
        }
        if (standingQty > 0) {
          units.add(AcUnit(type: 'Freestanding AC', quantity: standingQty));
        }
        if (uninstallDistribution.old > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallOld,
              quantity: uninstallDistribution.old,
            ),
          );
        }

        final invoiceKey = invoice.toLowerCase();
        sheetUniqueInvoices.add(invoiceKey);
        sheetInstalledSplit += splitQty;
        sheetInstalledWindow += windowQty;
        sheetInstalledFreestanding += standingQty;
        sheetUninstallSplit += uninstallDistribution.split;
        sheetUninstallWindow += uninstallDistribution.window;
        sheetUninstallFreestanding += uninstallDistribution.freestanding;
        sheetUninstallOld += uninstallDistribution.old;
        if (uninstallDistribution.split > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallSplit,
              quantity: uninstallDistribution.split,
            ),
          );
        }
        if (uninstallDistribution.window > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallWindow,
              quantity: uninstallDistribution.window,
            ),
          );
        }
        if (uninstallDistribution.freestanding > 0) {
          units.add(
            AcUnit(
              type: AppConstants.unitTypeUninstallFreestanding,
              quantity: uninstallDistribution.freestanding,
            ),
          );
        }

        final bracket = _doubleValue(row, headerMap, ['bracket']);
        final delivery = _doubleValue(row, headerMap, ['delivery']);
        final date =
            _dateValue(row, headerMap, ['date']) ??
            sheetPeriodDate ??
            DateTime.now();
        final contact = _value(row, headerMap, ['contact', 'client contact']);
        final clientName = _value(row, headerMap, ['client name']);
        final rowCompanyName = _value(row, headerMap, ['company']);
        final companyName = rowCompanyName.isNotEmpty
            ? rowCompanyName
            : (targetCompany?.name ?? '');

        final existing = jobsByInvoice[invoiceKey];
        if (existing == null) {
          jobsByInvoice[invoiceKey] = JobModel(
            techId: tech.uid,
            techName: tech.name,
            companyId: targetCompany?.id ?? '',
            companyName: companyName,
            invoiceNumber: invoice,
            clientName: clientName.isEmpty
                ? _importedClientName(sheetPeriodLabel, invoice)
                : clientName,
            clientContact: contact,
            acUnits: units,
            status: JobStatus.approved,
            expenses: 0,
            expenseNote: description,
            adminNote: _buildAdminImportNote(
              sourceTechName,
              targetUser,
              sheetName: sheetName,
              periodLabel: sheetPeriodLabel,
            ),
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
          );
        } else {
          jobsByInvoice[invoiceKey] = existing.copyWith(
            clientName:
                existing.clientName.trim().isEmpty &&
                    clientName.trim().isNotEmpty
                ? clientName
                : existing.clientName,
            clientContact:
                existing.clientContact.trim().isEmpty &&
                    contact.trim().isNotEmpty
                ? contact
                : existing.clientContact,
            acUnits: _mergeUnits(existing.acUnits, units),
            expenseNote: _mergeText(existing.expenseNote, description),
            charges: _mergeCharges(
              existing.charges,
              bracket,
              delivery,
              description,
            ),
            date: existing.date ?? date,
            submittedAt: existing.submittedAt ?? date,
            reviewedAt: existing.reviewedAt ?? date,
          );
        }
      }

      sheetImportedRows = sheetUniqueInvoices.length;

      sheetSummaries.add(
        HistoricalImportSheetSummary(
          sheetName: sheetName,
          importedRows: sheetImportedRows,
          skippedRows: sheetSkippedRows,
          unresolvedTechnicians: sheetUnresolvedTechnicians,
          installedSplit: sheetInstalledSplit,
          installedWindow: sheetInstalledWindow,
          installedFreestanding: sheetInstalledFreestanding,
          uninstallSplit: sheetUninstallSplit,
          uninstallWindow: sheetUninstallWindow,
          uninstallFreestanding: sheetUninstallFreestanding,
          uninstallOld: sheetUninstallOld,
        ),
      );
    }

    return HistoricalImportResult(
      jobs: jobsByInvoice.values.toList(),
      skippedRows: skipped,
      unresolvedTechnicians: unresolvedTech,
      sheetSummaries: sheetSummaries,
    );
  }

  static String _normalizeInvoice(String invoice) {
    final trimmed = invoice.trim();
    if (trimmed.isEmpty) return '';
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('INV-')) {
      return trimmed.substring(4).trim();
    }
    if (upper.startsWith('INV ')) {
      return trimmed.substring(4).trim();
    }
    return trimmed;
  }

  static List<AcUnit> _mergeUnits(List<AcUnit> first, List<AcUnit> second) {
    final totals = <String, int>{};
    for (final unit in first) {
      totals[unit.type] = (totals[unit.type] ?? 0) + unit.quantity;
    }
    for (final unit in second) {
      totals[unit.type] = (totals[unit.type] ?? 0) + unit.quantity;
    }

    return totals.entries
        .map((entry) => AcUnit(type: entry.key, quantity: entry.value))
        .toList();
  }

  static String _mergeText(String existing, String incoming) {
    final a = existing.trim();
    final b = incoming.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty || a == b) return a;
    return '$a | $b';
  }

  static InvoiceCharges _mergeCharges(
    InvoiceCharges? existing,
    double bracket,
    double delivery,
    String description,
  ) {
    final current = existing ?? const InvoiceCharges();
    final nextBracket = bracket > current.bracketAmount
        ? bracket
        : current.bracketAmount;
    final nextDelivery = delivery > current.deliveryAmount
        ? delivery
        : current.deliveryAmount;

    return current.copyWith(
      acBracket: current.acBracket || bracket > 0,
      bracketAmount: nextBracket,
      deliveryCharge: current.deliveryCharge || delivery > 0,
      deliveryAmount: nextDelivery,
      deliveryNote: _mergeText(current.deliveryNote, description),
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
      final key = _normalizeHeaderKey(
        (headerRow[i]?.value?.toString() ?? '').trim().toLowerCase(),
      );
      if (key.isNotEmpty) map[key] = i;
    }

    if (!map.containsKey('split')) {
      final contactIndex = map['contact'];
      final windowIndex = map['window'];
      if (contactIndex != null && windowIndex != null) {
        final candidateIndex = windowIndex - 1;
        if (candidateIndex > contactIndex &&
            candidateIndex < headerRow.length) {
          final candidateHeader =
              (headerRow[candidateIndex]?.value?.toString() ?? '').trim();
          if (candidateHeader.isEmpty) {
            map['split'] = candidateIndex;
          }
        }
      }
    }

    return map;
  }

  static String _normalizeHeaderKey(String rawKey) {
    return switch (rawKey) {
      'delery' => 'delivery',
      'c' => 'description',
      'uninstalation' => 'uninstallation',
      'uninstalation split/window' => 'uninstallation',
      _ => rawKey,
    };
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

    final excelSerial = double.tryParse(raw);
    if (excelSerial != null) {
      return _excelSerialToDate(excelSerial);
    }

    final parts = raw.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = int.tryParse(parts[1]) ?? 1;
      final y = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(y, m, d);
    }
    return null;
  }

  static DateTime _excelSerialToDate(double serial) {
    final wholeDays = serial.floor();
    final fractionalDay = serial - wholeDays;
    final baseDate = DateTime(1899, 12, 30);
    final dayPart = Duration(days: wholeDays);
    final timePart = Duration(milliseconds: (fractionalDay * 86400000).round());
    return baseDate.add(dayPart).add(timePart);
  }

  static int _extractTaggedValue(String description, String tag) {
    final regex = RegExp('(^|\\s|\\|)$tag:(\\d+)', caseSensitive: false);
    final match = regex.firstMatch(description);
    return match == null ? 0 : int.tryParse(match.group(2) ?? '') ?? 0;
  }

  static _UninstallDistribution _distributeUninstallTypes({
    required int uninstallTotal,
    required int splitInstalled,
    required int windowInstalled,
    required int freestandingInstalled,
    required int splitTagged,
    required int windowTagged,
    required int freestandingTagged,
  }) {
    var split = splitTagged;
    var window = windowTagged;
    var freestanding = freestandingTagged;

    final taggedTotal = split + window + freestanding;
    final effectiveTotal = uninstallTotal > taggedTotal
        ? uninstallTotal
        : taggedTotal;

    var remaining = effectiveTotal - taggedTotal;

    // If some uninstall units are not typed in Excel, infer them from the
    // installed AC mix on the same invoice before falling back to old AC.
    final splitCapacity = (splitInstalled - split).clamp(0, 9999);
    final splitAdd = remaining > splitCapacity ? splitCapacity : remaining;
    split += splitAdd;
    remaining -= splitAdd;

    final windowCapacity = (windowInstalled - window).clamp(0, 9999);
    final windowAdd = remaining > windowCapacity ? windowCapacity : remaining;
    window += windowAdd;
    remaining -= windowAdd;

    final freestandingCapacity = (freestandingInstalled - freestanding).clamp(
      0,
      9999,
    );
    final freestandingAdd = remaining > freestandingCapacity
        ? freestandingCapacity
        : remaining;
    freestanding += freestandingAdd;
    remaining -= freestandingAdd;

    final old = remaining.clamp(0, 9999);
    return _UninstallDistribution(
      split: split,
      window: window,
      freestanding: freestanding,
      old: old,
    );
  }

  static bool _rowMatchesKeyword(
    List<excel_pkg.Data?> row,
    Map<String, int> headerMap,
    String keyword,
  ) {
    final candidates = [
      _value(row, headerMap, ['tech name', 'technician name']),
      _value(row, headerMap, ['technician email', 'tech email', 'email']),
      _value(row, headerMap, ['technician id', 'tech id', 'techid', 'uid']),
    ];

    for (final candidate in candidates) {
      if (candidate.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  static String _buildAdminImportNote(
    String sourceTechName,
    UserModel? targetUser, {
    required String sheetName,
    required String periodLabel,
  }) {
    final sourceScope = 'Source: $sheetName • Period: $periodLabel';

    if (targetUser == null || sourceTechName.trim().isEmpty) {
      return 'Imported historical record • $sourceScope';
    }

    final normalizedSource = sourceTechName.trim().toLowerCase();
    final normalizedTarget = targetUser.name.trim().toLowerCase();
    if (normalizedSource == normalizedTarget) {
      return 'Imported historical record • $sourceScope';
    }

    return 'Imported historical record from $sourceTechName • $sourceScope';
  }

  static DateTime? _sheetPeriodDate(String sheetName) {
    final normalized = sheetName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    int? month;
    for (final token in _monthTokens.entries) {
      if (normalized.contains(token.key)) {
        month = token.value;
        break;
      }
    }

    final yearMatch = RegExp(r'(20\d{2})').firstMatch(normalized);
    final year = yearMatch == null ? null : int.tryParse(yearMatch.group(1)!);

    if (month == null || year == null) return null;
    return DateTime(year, month, 1);
  }

  static String _sheetPeriodLabel(String sheetName, DateTime? period) {
    if (period != null) {
      final monthLabel = _monthNames[period.month - 1];
      return '$monthLabel ${period.year}';
    }
    final cleaned = sheetName.trim();
    return cleaned.isEmpty ? 'Unknown Period' : cleaned;
  }

  static String _importedClientName(String periodLabel, String invoice) {
    return 'Imported $periodLabel • $invoice';
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

class _UninstallDistribution {
  const _UninstallDistribution({
    required this.split,
    required this.window,
    required this.freestanding,
    required this.old,
  });

  final int split;
  final int window;
  final int freestanding;
  final int old;
}
