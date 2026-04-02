import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;

void main(List<String> args) {
  final workbookPath = args.isNotEmpty
      ? args.first
      : 'docs/Amoudi AIO 2025.xlsx';
  final technicianFilter = args.length > 1 ? _normalizeLookup(args[1]) : '';

  final file = File(workbookPath);
  if (!file.existsSync()) {
    stderr.writeln('Workbook not found: $workbookPath');
    exitCode = 1;
    return;
  }

  final bytes = file.readAsBytesSync();
  final workbook = excel_pkg.Excel.decodeBytes(bytes);

  var totalMatched = 0;
  var rowsWithoutTechnicianName = 0;
  var rejectedByInvoice = 0;
  var rejectedByUnits = 0;
  final technicianNameCounts = <String, int>{};

  final rejectedRows = <Map<String, dynamic>>[];

  for (final entry in workbook.tables.entries) {
    final sheetName = entry.key;
    final rows = entry.value.rows;
    if (rows.isEmpty) continue;

    final headerMap = _buildHeaderMap(rows.first);
    if (headerMap.isEmpty) continue;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_rowIsEmpty(row)) continue;

      final techRaw = _value(row, headerMap, ['tech name', 'technician name']);
      final techNormalized = _normalizeLookup(techRaw);
      if (techNormalized.isEmpty) {
        rowsWithoutTechnicianName++;
      } else {
        _incrementTechnicianCount(technicianNameCounts, techRaw);
      }

      if (technicianFilter.isNotEmpty &&
          !techNormalized.contains(technicianFilter)) {
        continue;
      }

      totalMatched++;

      final rawInvoice = _value(row, headerMap, ['invoice number', 'invoice']);
      final invoice = _normalizeInvoice(rawInvoice);
      if (invoice.isEmpty) {
        rejectedByInvoice++;
        rejectedRows.add({
          'sheet': sheetName,
          'row': i + 1,
          'reason': 'empty_invoice',
          'invoice_raw': rawInvoice,
          'tech_name': techRaw,
        });
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

      final hasUnits =
          splitQty > 0 ||
          windowQty > 0 ||
          standingQty > 0 ||
          uninstallTotal > 0 ||
          uninstallSplitTagged > 0 ||
          uninstallWindowTagged > 0 ||
          uninstallStandingTagged > 0;

      if (!hasUnits) {
        rejectedByUnits++;
        rejectedRows.add({
          'sheet': sheetName,
          'row': i + 1,
          'reason': 'no_units',
          'invoice': invoice,
          'tech_name': techRaw,
          'split': splitQty,
          'window': windowQty,
          'standing': standingQty,
          'uninstall_total': uninstallTotal,
          'uninstall_split_tagged': uninstallSplitTagged,
          'uninstall_window_tagged': uninstallWindowTagged,
          'uninstall_standing_tagged': uninstallStandingTagged,
        });
      }
    }
  }

  print('Total matched rows: $totalMatched');
  print('Rows with no technician name: $rowsWithoutTechnicianName');
  print('Unique technician names found: ${technicianNameCounts.length}');
  print('Rejected (empty invoice): $rejectedByInvoice');
  print('Rejected (no units): $rejectedByUnits');
  print(
    'Valid for import: ${totalMatched - rejectedByInvoice - rejectedByUnits}',
  );
  print('');

  if (rejectedRows.isNotEmpty) {
    print('REJECTED ROWS:');
    for (final row in rejectedRows) {
      print(
        '  [${row['sheet']}:${row['row']}] ${row['reason']} — invoice="${row['invoice'] ?? row['invoice_raw']}" tech="${row['tech_name']}"',
      );
      if (row.containsKey('split')) {
        print(
          '      split=${row['split']} window=${row['window']} standing=${row['standing']} uninstall=${row['uninstall_total']} (S:${row['uninstall_split_tagged']} W:${row['uninstall_window_tagged']} F:${row['uninstall_standing_tagged']})',
        );
      }
    }
  }

  final outputPath = technicianFilter.isEmpty
      ? 'logs/import_debug_all_technicians.json'
      : 'logs/import_debug_${_sanitizeForFileName(technicianFilter)}.json';
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source': workbookPath,
        'technicianFilter': technicianFilter,
        'total_matched': totalMatched,
        'rows_without_technician_name': rowsWithoutTechnicianName,
        'technician_name_counts': technicianNameCounts,
        'rejected_by_invoice': rejectedByInvoice,
        'rejected_by_units': rejectedByUnits,
        'valid_for_import': totalMatched - rejectedByInvoice - rejectedByUnits,
        'rejected_rows': rejectedRows,
      }),
    );

  print('');
  print('Full debug output saved to $outputPath');
}

bool _rowIsEmpty(List<excel_pkg.Data?> row) {
  for (final cell in row) {
    if (_normalizeText(cell?.value?.toString() ?? '').isNotEmpty) {
      return false;
    }
  }
  return true;
}

Map<String, int> _buildHeaderMap(List<excel_pkg.Data?> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final key = _normalizeHeaderKey(
      (headerRow[i]?.value?.toString() ?? '').trim().toLowerCase(),
    );
    if (key.isNotEmpty) map[key] = i;
  }
  return map;
}

String _normalizeHeaderKey(String rawKey) {
  final normalized = rawKey
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 /]'), '')
      .trim();

  return switch (normalized) {
    'inv' ||
    'invoice no' ||
    'invoice #' ||
    'invoice number' ||
    'invoice' => 'invoice number',
    'tech' ||
    'tech name' ||
    'technician' ||
    'technician name' => 'technician name',
    'split' => 'split',
    'window' || 'windows' => 'window',
    'free standing' ||
    'freestanding' ||
    'standing' ||
    'dolab' => 'freestanding',
    'uninstall' ||
    'uninstallation total' ||
    'uninstalation' => 'uninstallation total',
    'description' || 'note' || 'remarks' || 'c' => 'description',
    _ => normalized,
  };
}

String _value(
  List<excel_pkg.Data?> row,
  Map<String, int> headerMap,
  List<String> possibleKeys,
) {
  for (final k in possibleKeys) {
    final idx = headerMap[_normalizeHeaderKey(k)];
    if (idx == null || idx >= row.length) continue;
    final v = _normalizeText(row[idx]?.value?.toString() ?? '');
    if (v.isNotEmpty) return v;
  }
  return '';
}

int _intValue(
  List<excel_pkg.Data?> row,
  Map<String, int> headerMap,
  List<String> keys,
) {
  final raw = _value(row, headerMap, keys);
  if (raw.isEmpty) return 0;
  final normalized = _normalizeNumeric(raw);
  return int.tryParse(normalized) ?? double.tryParse(normalized)?.round() ?? 0;
}

int _extractTaggedValue(String description, String tag) {
  final regex = RegExp('(^|\\s|\\|)$tag:(\\d+)', caseSensitive: false);
  final match = regex.firstMatch(description);
  return match == null ? 0 : int.tryParse(match.group(2) ?? '') ?? 0;
}

String _normalizeText(String raw) {
  return raw
      .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
      .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeLookup(String raw) {
  return _normalizeText(raw).toLowerCase();
}

void _incrementTechnicianCount(Map<String, int> counts, String rawName) {
  final name = _normalizeText(rawName);
  if (name.isEmpty) {
    return;
  }

  final normalized = _normalizeLookup(name);
  final existingKey = counts.keys.firstWhere(
    (key) => _normalizeLookup(key) == normalized,
    orElse: () => '',
  );

  final targetKey = existingKey.isEmpty ? name : existingKey;
  counts[targetKey] = (counts[targetKey] ?? 0) + 1;
}

String _sanitizeForFileName(String value) {
  return value
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
}

String _normalizeInvoice(String raw) {
  final text = _normalizeText(raw);
  if (text.isEmpty) return '';
  return text.replaceAll(RegExp(r'[^0-9a-zA-Z\-]'), '').toUpperCase();
}

String _normalizeNumeric(String raw) {
  final normalized = _normalizeText(raw).replaceAll(',', '');
  final direct = normalized.replaceAll(RegExp(r'[^0-9.+\-]'), '');
  if (direct.isNotEmpty) return direct;
  final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(normalized);
  return match?.group(0) ?? '';
}
