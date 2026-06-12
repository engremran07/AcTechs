import 'package:flutter/material.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';

class MonthPalette {
  MonthPalette._();

  static const List<Color> _colors = [
    ArcticTheme.arcticBlue,
    ArcticTheme.arcticSuccess,
    ArcticTheme.arcticWarning,
    ArcticTheme.arcticPurple,
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFFF472B6),
  ];

  static Color forMonthKey(String monthKey) {
    final key = monthKey.trim();
    if (key.isEmpty) return ArcticTheme.arcticBlue;
    var hash = 0;
    for (final codeUnit in key.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
    }
    return _colors[hash % _colors.length];
  }
}
