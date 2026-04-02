import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;

void main() {
  final file = File('docs/Amoudi AIO 2025.xlsx');
  if (!file.existsSync()) {
    stderr.writeln('Workbook not found');
    exitCode = 1;
    return;
  }

  final bytes = file.readAsBytesSync();
  final workbook = excel_pkg.Excel.decodeBytes(bytes);

  print('ANALYZING JUNE SHEET FOR ZERO-UNIT ROWS\n');

  final junRow = workbook.tables['Jun'];
  if (junRow == null) {
    print('June sheet not found');
    return;
  }

  final rows = junRow.rows;
  final headerMap = _buildHeaderMap(rows.first);

  print('Header mapping:');
  headerMap.forEach((k, v) {
    print('  $k → column $v');
  });
  print('');

  final zeroUnitRows = [6, 32, 33, 59, 74]; // From debug output

  for (final rowIdx in zeroUnitRows) {
    final row = rows[rowIdx];
    print('ROW ${rowIdx + 1}:');

    for (var i = 0; i < row.length; i++) {
      final cell = row[i];
      final value = cell?.value?.toString() ?? '';
      if (value.trim().isNotEmpty) {
        print('  col[$i]: "$value"');
      }
    }

    final invoiceRaw = _value(row, headerMap, ['invoice number', 'invoice']);
    final techRaw = _value(row, headerMap, ['tech name', 'technician name']);
    final splitRaw = _value(row, headerMap, ['split']);
    final windowRaw = _value(row, headerMap, ['window']);
    final standingRaw = _value(row, headerMap, [
      'free standing',
      'freestanding',
      'dolab',
    ]);
    final uninstallRaw = _value(row, headerMap, [
      'uninstallation total',
      'uninstallation',
    ]);
    final descRaw = _value(row, headerMap, ['description', 'note']);

    print('  Extracted:');
    print('    invoice=$invoiceRaw');
    print('    tech=$techRaw');
    print('    split=$splitRaw');
    print('    window=$windowRaw');
    print('    standing=$standingRaw');
    print('    uninstall=$uninstallRaw');
    print('    description=$descRaw');
    print('');
  }
}

Map<String, int> _buildHeaderMap(List<excel_pkg.Data?> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final rawVal = (headerRow[i]?.value?.toString() ?? '').trim().toLowerCase();
    if (rawVal.isEmpty) continue;

    final key = _normalizeHeaderKey(rawVal);
    if (key.isNotEmpty) map[key] = i;
  }
  return map;
}

String _normalizeHeaderKey(String rawKey) {
  final normalized = rawKey
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9 /]'), '')
      .trim();

  return switch (normalized) {
    'invoice no' ||
    'invoice #' ||
    'invoice number' ||
    'invoice' ||
    'inv' => 'invoice number',
    'tech name' || 'technician name' || 'tech' || 'technician' => 'tech name',
    'split' => 'split',
    'window' || 'windows' => 'window',
    'free standing' ||
    'freestanding' ||
    'standing' ||
    'dolab' => 'freestanding',
    'uninstall' ||
    'uninstallation total' ||
    'uninstalation' ||
    'uninstalation split/window' => 'uninstallation total',
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
    final v = (row[idx]?.value?.toString() ?? '').trim();
    if (v.isNotEmpty) return v;
  }
  return '';
}
