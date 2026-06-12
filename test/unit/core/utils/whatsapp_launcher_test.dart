import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/country_dial_code.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';

void main() {
  group('WhatsAppLauncher.normalizeNumber', () {
    final cases = <({String input, String expected})>[
      (input: '+966554123456', expected: '966554123456'),
      (input: '00966554123456', expected: '966554123456'),
      (input: '0554123456', expected: '966554123456'),
      (input: '00554123456', expected: '966554123456'),
      (input: '+1 (415) 555-0123', expected: '14155550123'),
      (input: '14155550123', expected: '14155550123'),
      (input: '4155550123', expected: '14155550123'),
      (input: '   ', expected: ''),
    ];

    for (final c in cases) {
      test('normalizes "${c.input}" -> "${c.expected}"', () {
        final normalized = WhatsAppLauncher.normalizeNumber(
          c.input,
          defaultCountry: CountryDialCode.ksa,
        );
        expect(normalized, c.expected);
      });
    }
  });
}
