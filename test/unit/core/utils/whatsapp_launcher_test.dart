import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/models/country_dial_code.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';

void main() {
  group('WhatsAppLauncher.normalizeNumber', () {
    // Create a US-like country code for testing NANP
    const usLike = CountryDialCode(
      name: 'United States',
      isoCode: 'US',
      dialCode: '1',
      flag: '🇺🇸',
    );

    final cases = <({String input, String expected, CountryDialCode country})>[
      (input: '+966554123456', expected: '966554123456', country: CountryDialCode.ksa),
      (input: '00966554123456', expected: '966554123456', country: CountryDialCode.ksa),
      (input: '0554123456', expected: '966554123456', country: CountryDialCode.ksa),
      (input: '00554123456', expected: '966554123456', country: CountryDialCode.ksa),
      (input: '+1 (415) 555-0123', expected: '14155550123', country: CountryDialCode.ksa),
      (input: '14155550123', expected: '14155550123', country: CountryDialCode.ksa),
      (input: '4155550123', expected: '14155550123', country: usLike),
      (input: '   ', expected: '', country: CountryDialCode.ksa),
      // WA-002 fix: Pakistan 10-digit numbers without leading 0 are returned as-is
      // (the function only prepends country code for recognized local formats)
      (input: '3221234567', expected: '3221234567', country: CountryDialCode.ksa),
      (input: '3001234567', expected: '3001234567', country: CountryDialCode.ksa),
    ];

    for (final c in cases) {
      test('normalizes "${c.input}" -> "${c.expected}" (country: ${c.country.dialCode})', () {
        final normalized = WhatsAppLauncher.normalizeNumber(
          c.input,
          defaultCountry: c.country,
        );
        expect(normalized, c.expected);
      });
    }

    // NANP only applies when context country is US/Canada (dialCode 1)
    test('NANP detection only applies for US/Canada context (dialCode 1)', () {
      // When default is US-like (dialCode 1), treat 10-digit as NANP
      final usNormalized = WhatsAppLauncher.normalizeNumber(
        '4155550123',
        defaultCountry: usLike,
      );
      expect(usNormalized, '14155550123');

      // When default is KSA, NANP not applied (unrecognized format returned as-is)
      final ksaNormalized = WhatsAppLauncher.normalizeNumber(
        '4155550123',
        defaultCountry: CountryDialCode.ksa,
      );
      expect(ksaNormalized, '4155550123');
    });
  });
}
