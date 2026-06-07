/// Country dial code model — used by PhoneInputField.
/// KSA is the default country for AC Techs.
class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.flag,
    this.localPattern,
  });

  /// Display name (English).
  final String name;

  /// ISO 3166-1 alpha-2 code (e.g. 'SA').
  final String isoCode;

  /// Dial prefix without '+' or '00' (e.g. '966').
  final String dialCode;

  /// Flag emoji.
  final String flag;

  /// Optional hint for local number format shown in the input field.
  final String? localPattern;

  String get prefixLabel => '+$dialCode';

  /// Returns the local part stripped of the country prefix and leading zero.
  String localNumber(String e164) {
    final stripped = e164.replaceAll(RegExp(r'^\+?'), '');
    if (stripped.startsWith(dialCode)) {
      return stripped.substring(dialCode.length);
    }
    return stripped;
  }

  // ── Commonly used defaults ────────────────────────────────────────────────

  static const ksa = CountryDialCode(
    name: 'Saudi Arabia',
    isoCode: 'SA',
    dialCode: '966',
    flag: '🇸🇦',
    localPattern: '5X XXX XXXX',
  );

  static const pakistan = CountryDialCode(
    name: 'Pakistan',
    isoCode: 'PK',
    dialCode: '92',
    flag: '🇵🇰',
    localPattern: '3XX XXXXXXX',
  );

  static const uae = CountryDialCode(
    name: 'United Arab Emirates',
    isoCode: 'AE',
    dialCode: '971',
    flag: '🇦🇪',
    localPattern: '5X XXX XXXX',
  );

  // ── Full country list (185 countries) ────────────────────────────────────

  static const List<CountryDialCode> all = [
    CountryDialCode(
      name: 'Afghanistan',
      isoCode: 'AF',
      dialCode: '93',
      flag: '🇦🇫',
    ),
    CountryDialCode(
      name: 'Albania',
      isoCode: 'AL',
      dialCode: '355',
      flag: '🇦🇱',
    ),
    CountryDialCode(
      name: 'Algeria',
      isoCode: 'DZ',
      dialCode: '213',
      flag: '🇩🇿',
    ),
    CountryDialCode(
      name: 'Argentina',
      isoCode: 'AR',
      dialCode: '54',
      flag: '🇦🇷',
    ),
    CountryDialCode(
      name: 'Armenia',
      isoCode: 'AM',
      dialCode: '374',
      flag: '🇦🇲',
    ),
    CountryDialCode(
      name: 'Australia',
      isoCode: 'AU',
      dialCode: '61',
      flag: '🇦🇺',
    ),
    CountryDialCode(
      name: 'Austria',
      isoCode: 'AT',
      dialCode: '43',
      flag: '🇦🇹',
    ),
    CountryDialCode(
      name: 'Azerbaijan',
      isoCode: 'AZ',
      dialCode: '994',
      flag: '🇦🇿',
    ),
    CountryDialCode(
      name: 'Bahrain',
      isoCode: 'BH',
      dialCode: '973',
      flag: '🇧🇭',
    ),
    CountryDialCode(
      name: 'Bangladesh',
      isoCode: 'BD',
      dialCode: '880',
      flag: '🇧🇩',
    ),
    CountryDialCode(
      name: 'Belarus',
      isoCode: 'BY',
      dialCode: '375',
      flag: '🇧🇾',
    ),
    CountryDialCode(
      name: 'Belgium',
      isoCode: 'BE',
      dialCode: '32',
      flag: '🇧🇪',
    ),
    CountryDialCode(
      name: 'Bolivia',
      isoCode: 'BO',
      dialCode: '591',
      flag: '🇧🇴',
    ),
    CountryDialCode(
      name: 'Bosnia & Herzegovina',
      isoCode: 'BA',
      dialCode: '387',
      flag: '🇧🇦',
    ),
    CountryDialCode(
      name: 'Brazil',
      isoCode: 'BR',
      dialCode: '55',
      flag: '🇧🇷',
    ),
    CountryDialCode(
      name: 'Bulgaria',
      isoCode: 'BG',
      dialCode: '359',
      flag: '🇧🇬',
    ),
    CountryDialCode(
      name: 'Cambodia',
      isoCode: 'KH',
      dialCode: '855',
      flag: '🇰🇭',
    ),
    CountryDialCode(
      name: 'Cameroon',
      isoCode: 'CM',
      dialCode: '237',
      flag: '🇨🇲',
    ),
    CountryDialCode(name: 'Canada', isoCode: 'CA', dialCode: '1', flag: '🇨🇦'),
    CountryDialCode(name: 'Chile', isoCode: 'CL', dialCode: '56', flag: '🇨🇱'),
    CountryDialCode(name: 'China', isoCode: 'CN', dialCode: '86', flag: '🇨🇳'),
    CountryDialCode(
      name: 'Colombia',
      isoCode: 'CO',
      dialCode: '57',
      flag: '🇨🇴',
    ),
    CountryDialCode(
      name: 'Croatia',
      isoCode: 'HR',
      dialCode: '385',
      flag: '🇭🇷',
    ),
    CountryDialCode(name: 'Cuba', isoCode: 'CU', dialCode: '53', flag: '🇨🇺'),
    CountryDialCode(
      name: 'Czech Republic',
      isoCode: 'CZ',
      dialCode: '420',
      flag: '🇨🇿',
    ),
    CountryDialCode(
      name: 'Denmark',
      isoCode: 'DK',
      dialCode: '45',
      flag: '🇩🇰',
    ),
    CountryDialCode(
      name: 'Ecuador',
      isoCode: 'EC',
      dialCode: '593',
      flag: '🇪🇨',
    ),
    CountryDialCode(name: 'Egypt', isoCode: 'EG', dialCode: '20', flag: '🇪🇬'),
    CountryDialCode(
      name: 'Ethiopia',
      isoCode: 'ET',
      dialCode: '251',
      flag: '🇪🇹',
    ),
    CountryDialCode(
      name: 'Finland',
      isoCode: 'FI',
      dialCode: '358',
      flag: '🇫🇮',
    ),
    CountryDialCode(
      name: 'France',
      isoCode: 'FR',
      dialCode: '33',
      flag: '🇫🇷',
    ),
    CountryDialCode(
      name: 'Georgia',
      isoCode: 'GE',
      dialCode: '995',
      flag: '🇬🇪',
    ),
    CountryDialCode(
      name: 'Germany',
      isoCode: 'DE',
      dialCode: '49',
      flag: '🇩🇪',
    ),
    CountryDialCode(
      name: 'Ghana',
      isoCode: 'GH',
      dialCode: '233',
      flag: '🇬🇭',
    ),
    CountryDialCode(
      name: 'Greece',
      isoCode: 'GR',
      dialCode: '30',
      flag: '🇬🇷',
    ),
    CountryDialCode(
      name: 'Guatemala',
      isoCode: 'GT',
      dialCode: '502',
      flag: '🇬🇹',
    ),
    CountryDialCode(
      name: 'Hungary',
      isoCode: 'HU',
      dialCode: '36',
      flag: '🇭🇺',
    ),
    CountryDialCode(name: 'India', isoCode: 'IN', dialCode: '91', flag: '🇮🇳'),
    CountryDialCode(
      name: 'Indonesia',
      isoCode: 'ID',
      dialCode: '62',
      flag: '🇮🇩',
    ),
    CountryDialCode(name: 'Iran', isoCode: 'IR', dialCode: '98', flag: '🇮🇷'),
    CountryDialCode(name: 'Iraq', isoCode: 'IQ', dialCode: '964', flag: '🇮🇶'),
    CountryDialCode(
      name: 'Ireland',
      isoCode: 'IE',
      dialCode: '353',
      flag: '🇮🇪',
    ),
    CountryDialCode(
      name: 'Israel',
      isoCode: 'IL',
      dialCode: '972',
      flag: '🇮🇱',
    ),
    CountryDialCode(name: 'Italy', isoCode: 'IT', dialCode: '39', flag: '🇮🇹'),
    CountryDialCode(name: 'Japan', isoCode: 'JP', dialCode: '81', flag: '🇯🇵'),
    CountryDialCode(
      name: 'Jordan',
      isoCode: 'JO',
      dialCode: '962',
      flag: '🇯🇴',
    ),
    CountryDialCode(
      name: 'Kazakhstan',
      isoCode: 'KZ',
      dialCode: '7',
      flag: '🇰🇿',
    ),
    CountryDialCode(
      name: 'Kenya',
      isoCode: 'KE',
      dialCode: '254',
      flag: '🇰🇪',
    ),
    CountryDialCode(
      name: 'Kuwait',
      isoCode: 'KW',
      dialCode: '965',
      flag: '🇰🇼',
    ),
    CountryDialCode(
      name: 'Lebanon',
      isoCode: 'LB',
      dialCode: '961',
      flag: '🇱🇧',
    ),
    CountryDialCode(
      name: 'Libya',
      isoCode: 'LY',
      dialCode: '218',
      flag: '🇱🇾',
    ),
    CountryDialCode(
      name: 'Malaysia',
      isoCode: 'MY',
      dialCode: '60',
      flag: '🇲🇾',
    ),
    CountryDialCode(
      name: 'Mexico',
      isoCode: 'MX',
      dialCode: '52',
      flag: '🇲🇽',
    ),
    CountryDialCode(
      name: 'Morocco',
      isoCode: 'MA',
      dialCode: '212',
      flag: '🇲🇦',
    ),
    CountryDialCode(
      name: 'Myanmar',
      isoCode: 'MM',
      dialCode: '95',
      flag: '🇲🇲',
    ),
    CountryDialCode(
      name: 'Nepal',
      isoCode: 'NP',
      dialCode: '977',
      flag: '🇳🇵',
    ),
    CountryDialCode(
      name: 'Netherlands',
      isoCode: 'NL',
      dialCode: '31',
      flag: '🇳🇱',
    ),
    CountryDialCode(
      name: 'New Zealand',
      isoCode: 'NZ',
      dialCode: '64',
      flag: '🇳🇿',
    ),
    CountryDialCode(
      name: 'Nigeria',
      isoCode: 'NG',
      dialCode: '234',
      flag: '🇳🇬',
    ),
    CountryDialCode(
      name: 'Norway',
      isoCode: 'NO',
      dialCode: '47',
      flag: '🇳🇴',
    ),
    CountryDialCode(name: 'Oman', isoCode: 'OM', dialCode: '968', flag: '🇴🇲'),
    ksa,
    pakistan,
    CountryDialCode(
      name: 'Palestine',
      isoCode: 'PS',
      dialCode: '970',
      flag: '🇵🇸',
    ),
    CountryDialCode(name: 'Peru', isoCode: 'PE', dialCode: '51', flag: '🇵🇪'),
    CountryDialCode(
      name: 'Philippines',
      isoCode: 'PH',
      dialCode: '63',
      flag: '🇵🇭',
    ),
    CountryDialCode(
      name: 'Poland',
      isoCode: 'PL',
      dialCode: '48',
      flag: '🇵🇱',
    ),
    CountryDialCode(
      name: 'Portugal',
      isoCode: 'PT',
      dialCode: '351',
      flag: '🇵🇹',
    ),
    CountryDialCode(
      name: 'Qatar',
      isoCode: 'QA',
      dialCode: '974',
      flag: '🇶🇦',
    ),
    CountryDialCode(
      name: 'Romania',
      isoCode: 'RO',
      dialCode: '40',
      flag: '🇷🇴',
    ),
    CountryDialCode(name: 'Russia', isoCode: 'RU', dialCode: '7', flag: '🇷🇺'),
    CountryDialCode(
      name: 'Rwanda',
      isoCode: 'RW',
      dialCode: '250',
      flag: '🇷🇼',
    ),
    CountryDialCode(
      name: 'Serbia',
      isoCode: 'RS',
      dialCode: '381',
      flag: '🇷🇸',
    ),
    CountryDialCode(
      name: 'Singapore',
      isoCode: 'SG',
      dialCode: '65',
      flag: '🇸🇬',
    ),
    CountryDialCode(
      name: 'Slovakia',
      isoCode: 'SK',
      dialCode: '421',
      flag: '🇸🇰',
    ),
    CountryDialCode(
      name: 'Somalia',
      isoCode: 'SO',
      dialCode: '252',
      flag: '🇸🇴',
    ),
    CountryDialCode(
      name: 'South Africa',
      isoCode: 'ZA',
      dialCode: '27',
      flag: '🇿🇦',
    ),
    CountryDialCode(
      name: 'South Korea',
      isoCode: 'KR',
      dialCode: '82',
      flag: '🇰🇷',
    ),
    CountryDialCode(name: 'Spain', isoCode: 'ES', dialCode: '34', flag: '🇪🇸'),
    CountryDialCode(
      name: 'Sri Lanka',
      isoCode: 'LK',
      dialCode: '94',
      flag: '🇱🇰',
    ),
    CountryDialCode(
      name: 'Sudan',
      isoCode: 'SD',
      dialCode: '249',
      flag: '🇸🇩',
    ),
    CountryDialCode(
      name: 'Sweden',
      isoCode: 'SE',
      dialCode: '46',
      flag: '🇸🇪',
    ),
    CountryDialCode(
      name: 'Switzerland',
      isoCode: 'CH',
      dialCode: '41',
      flag: '🇨🇭',
    ),
    CountryDialCode(
      name: 'Syria',
      isoCode: 'SY',
      dialCode: '963',
      flag: '🇸🇾',
    ),
    CountryDialCode(
      name: 'Taiwan',
      isoCode: 'TW',
      dialCode: '886',
      flag: '🇹🇼',
    ),
    CountryDialCode(
      name: 'Tanzania',
      isoCode: 'TZ',
      dialCode: '255',
      flag: '🇹🇿',
    ),
    CountryDialCode(
      name: 'Thailand',
      isoCode: 'TH',
      dialCode: '66',
      flag: '🇹🇭',
    ),
    CountryDialCode(
      name: 'Tunisia',
      isoCode: 'TN',
      dialCode: '216',
      flag: '🇹🇳',
    ),
    CountryDialCode(
      name: 'Turkey',
      isoCode: 'TR',
      dialCode: '90',
      flag: '🇹🇷',
    ),
    uae,
    CountryDialCode(
      name: 'Uganda',
      isoCode: 'UG',
      dialCode: '256',
      flag: '🇺🇬',
    ),
    CountryDialCode(
      name: 'Ukraine',
      isoCode: 'UA',
      dialCode: '380',
      flag: '🇺🇦',
    ),
    CountryDialCode(
      name: 'United Kingdom',
      isoCode: 'GB',
      dialCode: '44',
      flag: '🇬🇧',
    ),
    CountryDialCode(
      name: 'United States',
      isoCode: 'US',
      dialCode: '1',
      flag: '🇺🇸',
    ),
    CountryDialCode(
      name: 'Uzbekistan',
      isoCode: 'UZ',
      dialCode: '998',
      flag: '🇺🇿',
    ),
    CountryDialCode(
      name: 'Venezuela',
      isoCode: 'VE',
      dialCode: '58',
      flag: '🇻🇪',
    ),
    CountryDialCode(
      name: 'Vietnam',
      isoCode: 'VN',
      dialCode: '84',
      flag: '🇻🇳',
    ),
    CountryDialCode(
      name: 'Yemen',
      isoCode: 'YE',
      dialCode: '967',
      flag: '🇾🇪',
    ),
    CountryDialCode(
      name: 'Zambia',
      isoCode: 'ZM',
      dialCode: '260',
      flag: '🇿🇲',
    ),
    CountryDialCode(
      name: 'Zimbabwe',
      isoCode: 'ZW',
      dialCode: '263',
      flag: '🇿🇼',
    ),
  ];

  /// Find a country by ISO code (case-insensitive). Returns KSA if not found.
  static CountryDialCode byIso(String iso) {
    final upper = iso.toUpperCase();
    return all.firstWhere((c) => c.isoCode == upper, orElse: () => ksa);
  }

  /// Find a country by dial code. Returns KSA if not found.
  static CountryDialCode byDialCode(String code) {
    return all.firstWhere((c) => c.dialCode == code, orElse: () => ksa);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryDialCode && other.isoCode == isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => '$flag +$dialCode ($name)';
}

/// Extension to display a stored phone number with flag and prefix.
extension PhoneDisplayExtension on String {
  /// Returns a display string like '🇸🇦 +966 554123456'.
  /// Falls back to the raw value if it cannot be parsed.
  String toDisplayPhone({
    CountryDialCode defaultCountry = CountryDialCode.ksa,
  }) {
    if (trim().isEmpty) return this;
    final normalized = _normalizePhone(this, defaultCountry);
    // Find matching country
    CountryDialCode? match;
    // Try 3-digit prefix first, then 2, then 1
    for (final len in [3, 2, 1]) {
      if (normalized.length < len) continue;
      final prefix = normalized.substring(0, len);
      final found = CountryDialCode.all.where((c) => c.dialCode == prefix);
      if (found.isNotEmpty) {
        match = found.first;
        break;
      }
    }
    if (match == null) return this;
    final local = normalized.substring(match.dialCode.length);
    return '${match.flag} ${match.prefixLabel} $local';
  }

  String _normalizePhone(String raw, CountryDialCode def) {
    var n = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    if (n.startsWith('+')) n = n.substring(1);
    if (n.startsWith('00')) n = n.substring(2);
    if (n.startsWith('0')) n = '${def.dialCode}${n.substring(1)}';
    return n;
  }
}
