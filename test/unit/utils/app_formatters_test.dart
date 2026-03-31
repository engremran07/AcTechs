import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';

void main() {
  group('AppFormatters.date()', () {
    test('formats a date as dd/MM/yyyy', () {
      final dt = DateTime(2024, 3, 5);
      expect(AppFormatters.date(dt), '05/03/2024');
    });

    test('pads single-digit day and month with leading zero', () {
      final dt = DateTime(2023, 1, 9);
      expect(AppFormatters.date(dt), '09/01/2023');
    });

    test('returns empty string for null date', () {
      expect(AppFormatters.date(null), '');
    });

    test('formats the last day of the year correctly', () {
      final dt = DateTime(2025, 12, 31);
      expect(AppFormatters.date(dt), '31/12/2025');
    });

    test('formats February 28th correctly', () {
      final dt = DateTime(2024, 2, 28);
      expect(AppFormatters.date(dt), '28/02/2024');
    });
  });

  group('AppFormatters.currency()', () {
    test('formats zero as SAR 0', () {
      expect(AppFormatters.currency(0), 'SAR 0');
    });

    test('formats a whole number without decimals', () {
      expect(AppFormatters.currency(1500), 'SAR 1500');
    });

    test('formats a decimal amount without decimals', () {
      expect(AppFormatters.currency(99.9), 'SAR 100');
    });

    test('formats a fractional amount by truncating to integer', () {
      expect(AppFormatters.currency(49.4), 'SAR 49');
    });

    test('has SAR prefix', () {
      final result = AppFormatters.currency(250);
      expect(result, startsWith('SAR '));
    });
  });

  group('AppFormatters.units()', () {
    test('returns "1 unit" for count 1', () {
      expect(AppFormatters.units(1), '1 unit');
    });

    test('returns "2 units" for count 2', () {
      expect(AppFormatters.units(2), '2 units');
    });

    test('returns "0 units" for count 0', () {
      expect(AppFormatters.units(0), '0 units');
    });

    test('returns "10 units" for count 10', () {
      expect(AppFormatters.units(10), '10 units');
    });

    test('singular form only for count 1', () {
      for (final count in [0, 2, 5, 100]) {
        expect(AppFormatters.units(count), endsWith('units'));
      }
      expect(AppFormatters.units(1), endsWith('unit'));
      expect(AppFormatters.units(1), isNot(endsWith('units')));
    });
  });

  group('AppFormatters.shortName()', () {
    test('returns full name when shorter than default max', () {
      expect(AppFormatters.shortName('Ali'), 'Ali');
    });

    test('returns full name when equal to default max', () {
      expect(AppFormatters.shortName('12345678'), '12345678');
    });

    test('truncates name longer than default max and appends ".."', () {
      expect(AppFormatters.shortName('123456789'), '12345678..');
    });

    test('uses custom max length', () {
      expect(AppFormatters.shortName('Hello World', 5), 'Hello..');
    });

    test('returns empty string for empty input', () {
      expect(AppFormatters.shortName(''), '');
    });

    test('appended ".." has exactly 2 dots', () {
      final result = AppFormatters.shortName('VeryLongNameHere');
      expect(result, endsWith('..'));
    });
  });
}
