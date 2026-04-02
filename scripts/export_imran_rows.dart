import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;

void main() {
  final source = File('docs/Amoudi AIO 2025.xlsx');
  if (!source.existsSync()) {
    stderr.writeln('Workbook not found: docs/Amoudi AIO 2025.xlsx');
    exitCode = 1;
    return;
  }

  final workbook = excel_pkg.Excel.decodeBytes(source.readAsBytesSync());
  final rows = <Map<String, dynamic>>[];

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
      if (!_normalizeLookup(techValue).contains('imran')) {
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

  final outputPath = 'logs/imran_rows_full.json';
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source': 'docs/Amoudi AIO 2025.xlsx',
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

String _normalizedCellText(String raw) {
  return raw
      .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
      .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
