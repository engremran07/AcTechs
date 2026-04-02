import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;

void main(List<String> args) {
  final workbookPath = args.isNotEmpty
      ? args.first
      : 'docs/Amoudi AIO 2025.xlsx';
  final technicianFilter = args.length > 1 ? _normalizeLookup(args[1]) : '';

  final source = File(workbookPath);
  if (!source.existsSync()) {
    stderr.writeln('Workbook not found: $workbookPath');
    exitCode = 1;
    return;
  }

  final workbook = excel_pkg.Excel.decodeBytes(source.readAsBytesSync());
  final rows = <Map<String, dynamic>>[];
  var rowsWithoutTechnicianName = 0;
  final technicianNameCounts = <String, int>{};

  for (final entry in workbook.tables.entries) {
    final sheetName = entry.key;
    final tableRows = entry.value.rows;
    if (tableRows.isEmpty) {
      continue;
    }

    final headers = _headers(tableRows.first);
    if (headers.isEmpty) {
      continue;
    }

    final techIndex = _findHeaderIndex(headers, const [
      'tech name',
      'technician name',
      'tech',
      'technician',
    ]);
    if (techIndex == null) {
      continue;
    }

    for (var i = 1; i < tableRows.length; i++) {
      final row = tableRows[i];
      if (_isEmptyRow(row)) {
        continue;
      }

      final techValue = _normalizedCellValue(row, techIndex);
      final normalizedTech = _normalizeLookup(techValue);
      if (normalizedTech.isEmpty) {
        rowsWithoutTechnicianName++;
      } else {
        _incrementTechnicianCount(technicianNameCounts, techValue);
      }

      if (technicianFilter.isNotEmpty &&
          !normalizedTech.contains(technicianFilter)) {
        continue;
      }

      final data = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        final key = headers[c].isEmpty ? 'column_${c + 1}' : headers[c];
        data[key] = _normalizedCellValue(row, c);
      }

      rows.add({
        'sheet': sheetName,
        'rowNumber': i + 1,
        'techName': techValue,
        'data': data,
      });
    }
  }

  final outputPath = technicianFilter.isEmpty
      ? 'logs/technician_rows_full.json'
      : 'logs/technician_rows_${_sanitizeForFileName(technicianFilter)}.json';
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source': workbookPath,
        'technicianFilter': technicianFilter,
        'rowsWithoutTechnicianName': rowsWithoutTechnicianName,
        'uniqueTechnicianNameCount': technicianNameCounts.length,
        'technicianNameCounts': technicianNameCounts,
        'matchedRows': rows.length,
        'rows': rows,
      }),
    );

  print('Exported ${rows.length} matching rows to $outputPath');
}

List<String> _headers(List<excel_pkg.Data?> headerRow) {
  return List<String>.generate(headerRow.length, (i) {
    final raw = _normalizedCellText(headerRow[i]?.value?.toString() ?? '');
    return raw;
  });
}

int? _findHeaderIndex(List<String> headers, List<String> candidates) {
  final normalizedCandidates = candidates.map(_normalizeLookup).toSet();
  for (var i = 0; i < headers.length; i++) {
    final normalized = _normalizeLookup(headers[i]);
    if (normalizedCandidates.contains(normalized)) {
      return i;
    }
  }
  return null;
}

bool _isEmptyRow(List<excel_pkg.Data?> row) {
  for (final cell in row) {
    if (_normalizedCellText(cell?.value?.toString() ?? '').isNotEmpty) {
      return false;
    }
  }
  return true;
}

String _normalizedCellValue(List<excel_pkg.Data?> row, int index) {
  if (index < 0 || index >= row.length) {
    return '';
  }
  return _normalizedCellText(row[index]?.value?.toString() ?? '');
}

String _normalizeLookup(String raw) {
  return _normalizedCellText(raw).toLowerCase();
}

void _incrementTechnicianCount(Map<String, int> counts, String rawName) {
  final name = _normalizedCellText(rawName);
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

String _normalizedCellText(String raw) {
  return raw
      .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
      .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
