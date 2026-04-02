import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ac_techs/core/theme/app_fonts.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';

class ArcticTheme {
  ArcticTheme._();

  static const Color seedColor = Color(0xFF00D4FF);

  // ── Dark Mode Colors (deep navy arctic feel) ──
  static const Color arcticBlue = Color(0xFF00D4FF);
  static const Color arcticDarkBg = Color(0xFF0A0E1A);
  static const Color arcticSurface = Color(0xFF111827);
  static const Color arcticCard = Color(0xFF1A2332);
  static const Color arcticSuccess = Color(0xFF00E676);
  static const Color arcticError = Color(0xFFFF5252);
  static const Color arcticWarning = Color(0xFFFFAB40);
  static const Color arcticPending = Color(0xFFFFD740);
  static const Color arcticTextPrimary = Color(0xFFE2E8F0);
  static const Color arcticTextSecondary = Color(0xFF94A3B8);
  static const Color arcticDivider = Color(0xFF1E293B);

  // ── Gradient Accents (shared across themes) ──
  static const Color arcticBlueDark = Color(0xFF0099CC);
  static const Color arcticWarningDark = Color(0xFFFF8F00);
  static const Color arcticPurple = Color(0xFF9C27B0);

  // ── Light Mode Colors (clean, airy, professional) ──
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color lightBlue = Color(0xFF0284C7);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightWarning = Color(0xFFD97706);
  static const Color lightPending = Color(0xFFF59E0B);

  // ── High Contrast Colors (vivid neon-on-black, maximum readability) ──
  static const Color hcBg = Color(0xFF000000);
  static const Color hcSurface = Color(0xFF0D0D0D);
  static const Color hcCard = Color(0xFF0D0D0D);
  static const Color hcTextPrimary = Color(0xFFFFFFFF);
  static const Color hcTextSecondary = Color(0xFFE0E0E0);
  static const Color hcDivider = Color(0xFFFFD600);
  static const Color hcBlue = Color(0xFF00FFFF);
  static const Color hcSuccess = Color(0xFF00FF7F);
  static const Color hcError = Color(0xFFFF1744);
  static const Color hcWarning = Color(0xFFFFD600);
  static const Color hcPending = Color(0xFFFFD600);

  /// Returns the correct theme for the current mode + locale.
  static ThemeData themeForMode(
    AppThemeMode mode,
    String locale, {
    Brightness systemBrightness = Brightness.dark,
  }) {
    return switch (mode) {
      AppThemeMode.auto =>
        systemBrightness == Brightness.light
            ? lightThemeForLocale(locale)
            : darkThemeForLocale(locale),
      AppThemeMode.dark => darkThemeForLocale(locale),
      AppThemeMode.light => lightThemeForLocale(locale),
      AppThemeMode.highContrast => highContrastThemeForLocale(locale),
    };
  }

  static ThemeData get darkTheme => darkThemeForLocale('en');

  /// Locale-aware theme that swaps fonts for Urdu/Arabic.
  static ThemeData darkThemeForLocale(String locale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: arcticSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        primary: arcticBlue,
        error: arcticError,
      ),
      scaffoldBackgroundColor: arcticDarkBg,
      textTheme: AppFonts.textTheme(
        locale,
        textPrimary: arcticTextPrimary,
        textSecondary: arcticTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: arcticDarkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.heading(
          locale,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: arcticTextPrimary,
        ),
        iconTheme: const IconThemeData(color: arcticBlue),
      ),
      cardTheme: CardThemeData(
        color: arcticCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arcticBlue,
          foregroundColor: arcticDarkBg,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: arcticBlue,
          side: const BorderSide(color: arcticBlue),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: arcticCard,
        hintStyle: AppFonts.body(
          locale,
          fontSize: 14,
          color: arcticTextSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: arcticBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: arcticError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: arcticSurface,
        selectedItemColor: arcticBlue,
        unselectedItemColor: arcticTextSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.body(
          locale,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppFonts.body(locale, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: arcticDivider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: arcticCard,
        contentTextStyle: AppFonts.body(locale, color: arcticTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: arcticSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: arcticBlue,
        selectionColor: Color(0x5500D4FF),
        selectionHandleColor: arcticBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return arcticBlue;
          return arcticTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return arcticBlue.withValues(alpha: 0.3);
          }
          return arcticDivider;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: arcticCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════
  static ThemeData lightThemeForLocale(String locale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lightBlue,
      brightness: Brightness.light,
      surface: lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme.copyWith(
        primary: lightBlue,
        error: lightError,
        onSurface: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: AppFonts.textTheme(
        locale,
        textPrimary: lightTextPrimary,
        textSecondary: lightTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppFonts.heading(
          locale,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightDivider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightBlue,
          side: const BorderSide(color: lightBlue),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        hintStyle: AppFonts.body(
          locale,
          fontSize: 14,
          color: lightTextSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: arcticError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightBlue,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppFonts.body(
          locale,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppFonts.body(locale, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: AppFonts.body(locale, color: lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: lightBlue,
        selectionColor: Color(0x330284C7),
        selectionHandleColor: lightBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightBlue;
          return lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightBlue.withValues(alpha: 0.3);
          }
          return lightDivider;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HIGH CONTRAST THEME
  // ═══════════════════════════════════════════════════════════
  static ThemeData highContrastThemeForLocale(String locale) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: hcBlue,
      brightness: Brightness.dark,
      surface: hcSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme.copyWith(
        primary: hcBlue,
        error: hcError,
        onSurface: hcTextPrimary,
      ),
      scaffoldBackgroundColor: hcBg,
      textTheme: AppFonts.textTheme(
        locale,
        textPrimary: hcTextPrimary,
        textSecondary: hcTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: hcSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppFonts.heading(
          locale,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: hcBlue,
        ),
        iconTheme: const IconThemeData(color: hcBlue, size: 28),
      ),
      cardTheme: CardThemeData(
        color: hcCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: hcDivider, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hcBlue,
          foregroundColor: hcBg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: hcBlue, width: 2),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hcBlue,
          side: const BorderSide(color: hcBlue, width: 2),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppFonts.body(
            locale,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: hcCard,
        hintStyle: AppFonts.body(locale, fontSize: 14, color: hcTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hcDivider, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hcDivider, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hcBlue, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: hcError, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: hcSurface,
        selectedItemColor: hcBlue,
        unselectedItemColor: hcTextSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppFonts.body(
          locale,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: AppFonts.body(locale, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: hcDivider, thickness: 2),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: hcCard,
        contentTextStyle: AppFonts.body(locale, color: hcTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: hcDivider, width: 2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: hcSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: hcDivider, width: 2),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: hcBlue,
        selectionColor: Color(0x5500FFFF),
        selectionHandleColor: hcBlue,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return hcBlue;
          return hcTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return hcBlue.withValues(alpha: 0.5);
          }
          return hcSurface;
        }),
        trackOutlineColor: WidgetStateProperty.all(hcDivider),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: hcCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: hcDivider, width: 2),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: AppFonts.body(locale, fontSize: 14, color: hcBg),
        decoration: BoxDecoration(
          color: hcBlue,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Helper — resolve colors for the current mode.
  static Color cardColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticCard,
    AppThemeMode.light => lightCard,
    AppThemeMode.highContrast => hcCard,
  };

  static Color bgColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticDarkBg,
    AppThemeMode.light => lightBg,
    AppThemeMode.highContrast => hcBg,
  };

  static Color primaryColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticBlue,
    AppThemeMode.light => lightBlue,
    AppThemeMode.highContrast => hcBlue,
  };

  static Color successColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticSuccess,
    AppThemeMode.light => lightSuccess,
    AppThemeMode.highContrast => hcSuccess,
  };

  static Color errorColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticError,
    AppThemeMode.light => lightError,
    AppThemeMode.highContrast => hcError,
  };

  static Color warningColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticWarning,
    AppThemeMode.light => lightWarning,
    AppThemeMode.highContrast => hcWarning,
  };

  static Color pendingColor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticPending,
    AppThemeMode.light => lightPending,
    AppThemeMode.highContrast => hcPending,
  };

  static Color textPrimary(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticTextPrimary,
    AppThemeMode.light => lightTextPrimary,
    AppThemeMode.highContrast => hcTextPrimary,
  };

  static Color textSecondary(AppThemeMode mode) => switch (mode) {
    AppThemeMode.auto || AppThemeMode.dark => arcticTextSecondary,
    AppThemeMode.light => lightTextSecondary,
    AppThemeMode.highContrast => hcTextSecondary,
  };
}
