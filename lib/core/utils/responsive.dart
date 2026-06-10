import 'package:flutter/material.dart';

/// Responsive breakpoints and helpers to prevent overflow on
/// different Android phone brands (small 5", normal 6", tablet 8"+)
/// and web desktop browsers (1024px+, 1440px+).
class Responsive {
  Responsive._();

  static const double mobileSmall = 360;
  static const double mobileNormal = 400;
  static const double tablet = 600;

  /// Desktop breakpoints for web interface (admin dashboard, data tables).
  static const double desktop = 1024;
  static const double desktopWide = 1440;

  static bool isSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileNormal;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Returns true when width ≥ 1024px (web desktop / large tablet).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Returns true when width ≥ 1440px (large desktop monitors).
  static bool isDesktopWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopWide;

  /// Standard horizontal screen padding — tighter on small phones.
  static EdgeInsets screenPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileSmall) return const EdgeInsets.symmetric(horizontal: 12);
    if (w < tablet) return const EdgeInsets.symmetric(horizontal: 16);
    if (w >= desktop) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  /// Scaled font size for stat cards etc. that overflow on tiny screens.
  static double scaledFontSize(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileSmall) return base * 0.85;
    return base;
  }

  /// Max content width — constrained on tablet/desktop to avoid
  /// overly-wide layouts on large screens.
  ///
  /// - Mobile (<600px):     full width
  /// - Tablet (600–1023px): 600px
  /// - Desktop (1024–1439px): 900px (good for data tables)
  /// - Desktop wide (1440px+): 1200px
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopWide) return 1200;
    if (w >= desktop) return 900;
    if (w >= tablet) return 600;
    return w;
  }
}

/// A wrapper that constrains content width on tablets and centers it.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.screenPadding(context),
          child: child,
        ),
      ),
    );
  }
}
