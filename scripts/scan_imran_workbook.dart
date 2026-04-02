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

  var totalRows = 0;
  var matchedRows = 0;
  var rowsWithoutTechnicianName = 0;
  var rowsWithLeadingOrTrailing = 0;
  var rowsWithHiddenWhitespace = 0;
  final technicianCounts = <String, int>{};

  print('Workbook: $workbookPath');
  print(
    technicianFilter.isEmpty
        ? 'Technician filter: (none, all rows considered)'
        : 'Technician filter: "$technicianFilter"',
  );
  print('Sheets: ${workbook.tables.length}');
  print('');

  for (final entry in workbook.tables.entries) {
    final sheetName = entry.key;
    final rows = entry.value.rows;
    if (rows.isEmpty) {
      continue;
    }

    final headerMap = _buildHeaderMap(rows.first);
    final techIndex = _findFirstIndex(headerMap, const [
      'technician name',
      'tech name',
      'technician',
      'tech',
    ]);
    final invoiceIndex = _findFirstIndex(headerMap, const [
      'invoice number',
      'invoice',
    ]);
    final dateIndex = _findFirstIndex(headerMap, const ['date']);

    var sheetMatched = 0;
    var sheetNoTechName = 0;
    var sheetLeadTrail = 0;
    var sheetHiddenWhitespace = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_rowIsEmpty(row)) {
        continue;
      }

      totalRows++;

      var hasLeadTrail = false;
      var hasHiddenWhitespace = false;

      for (final cell in row) {
        final raw = cell?.value?.toString() ?? '';
        if (raw.isEmpty) {
          continue;
        }

        if (raw != raw.trim()) {
          hasLeadTrail = true;
        }
        if (RegExp(
          r'[\u00A0\u2007\u202F\u200B\u200C\u200D\uFEFF]',
        ).hasMatch(raw)) {
          hasHiddenWhitespace = true;
        }
      }

      if (hasLeadTrail) {
        rowsWithLeadingOrTrailing++;
        sheetLeadTrail++;
      }
      if (hasHiddenWhitespace) {
        rowsWithHiddenWhitespace++;
        sheetHiddenWhitespace++;
      }

      final techRaw = _indexValue(row, techIndex);
      final techNormalized = _normalizeLookup(techRaw);
      if (techNormalized.isEmpty) {
        rowsWithoutTechnicianName++;
        sheetNoTechName++;
      } else {
        _incrementTechnicianCount(technicianCounts, techRaw);
      }

      if (technicianFilter.isNotEmpty &&
          !techNormalized.contains(technicianFilter)) {
        continue;
      }

      matchedRows++;
      sheetMatched++;

      final invoice = _indexValue(row, invoiceIndex);
      final date = _indexValue(row, dateIndex);
      print(
        '[MATCH] sheet="$sheetName" row=${i + 1} tech="$techRaw" invoice="$invoice" date="$date"',
      );
    }

    if (sheetMatched > 0 ||
        sheetNoTechName > 0 ||
        sheetLeadTrail > 0 ||
        sheetHiddenWhitespace > 0) {
      print(
        '[SHEET] "$sheetName" matches=$sheetMatched no-tech-name-rows=$sheetNoTechName lead/trail-space-rows=$sheetLeadTrail hidden-whitespace-rows=$sheetHiddenWhitespace',
      );
    }
  }

  print('');
  print('Summary:');
  print('  Total non-empty data rows: $totalRows');
  print('  Rows matched by filter: $matchedRows');
  print('  Rows with no technician name: $rowsWithoutTechnicianName');
  print('  Rows with leading/trailing spaces: $rowsWithLeadingOrTrailing');
  print('  Rows with hidden unicode whitespace: $rowsWithHiddenWhitespace');
  print('  Unique technician names found: ${technicianCounts.length}');
  if (technicianCounts.isNotEmpty) {
    print('  Technician counts:');
    final sorted = technicianCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      print('    ${entry.key}: ${entry.value}');
    }
  }
}

void _incrementTechnicianCount(Map<String, int> counts, String rawName) {
  final name = _normalizeCellText(rawName);
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

bool _rowIsEmpty(List<excel_pkg.Data?> row) {
  for (final cell in row) {
    final value = _normalizeCellText(cell?.value?.toString() ?? '');
    if (value.isNotEmpty) {
      return false;
    }
  }
  return true;
}

Map<String, int> _buildHeaderMap(List<excel_pkg.Data?> row) {
  final map = <String, int>{};
  for (var i = 0; i < row.length; i++) {
    final key = _normalizeHeaderKey(row[i]?.value?.toString() ?? '');
    if (key.isNotEmpty) {
      map[key] = i;
    }
  }
  return map;
}

int? _findFirstIndex(Map<String, int> headerMap, List<String> keys) {
  for (final key in keys) {
    final idx = headerMap[_normalizeHeaderKey(key)];
    if (idx != null) {
      return idx;
    }
  }
  return null;
}

String _indexValue(List<excel_pkg.Data?> row, int? index) {
  if (index == null || index >= row.length) {
    return '';
  }
  return _normalizeCellText(row[index]?.value?.toString() ?? '');
}

String _normalizeHeaderKey(String raw) {
  final value = _normalizeLookup(raw)
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 /]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return switch (value) {
    'invoice no' ||
    'invoice #' ||
    'inv' ||
    'invoice' ||
    'invoice number' => 'invoice number',
    'tech name' ||
    'technician name' ||
    'tech' ||
    'technician' => 'technician name',
    _ => value,
  };
}

String _normalizeLookup(String raw) {
  return _normalizeCellText(raw).toLowerCase();
}

String _normalizeCellText(String raw) {
  return raw
      .replaceAll(RegExp(r'[\u00A0\u2007\u202F]'), ' ')
      .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
