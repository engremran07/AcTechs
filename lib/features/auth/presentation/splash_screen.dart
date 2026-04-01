import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/features/auth/presentation/widgets/ac_logo_icon_painter.dart';
import 'package:ac_techs/features/auth/presentation/widgets/ac_splash_painter.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Splash timeline (strict):
/// 1) Scene animation first.
/// 2) Logo appears only in the final 300 ms.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _outroController;
  bool _loggedSceneStart = false;
  bool _loggedLogoReveal = false;
  bool _startedOutro = false;

  static const Duration _sceneDuration = Duration(milliseconds: 7000);
  static const Duration _totalDuration = Duration(milliseconds: 7300);

  double get _logoStartT =>
      _sceneDuration.inMilliseconds / _totalDuration.inMilliseconds;

  @override
  void initState() {
    super.initState();

    _outroController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            debugPrint('SplashScreen: splash handoff complete');
            widget.onComplete();
          }
        });

    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..addListener(() {
        if (!_loggedSceneStart && _controller.value > 0) {
          _loggedSceneStart = true;
          debugPrint('SplashScreen: scene animation started');
        }
        if (!_loggedLogoReveal && _controller.value >= _logoStartT) {
          _loggedLogoReveal = true;
          debugPrint('SplashScreen: final logo reveal started (last 300ms)');
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !_startedOutro) {
          _startedOutro = true;
          debugPrint('SplashScreen: splash animation complete');
          _outroController.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _outroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context)!;
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final isRtl = locale == 'ur' || locale == 'ar';

    final currentMode = themeMode == AppThemeMode.auto
        ? (systemBrightness == Brightness.light
              ? AppThemeMode.light
              : AppThemeMode.dark)
        : themeMode;

    final (bgColor, primaryColor, accentColor, textColor) = _themeColors(
      currentMode,
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: AnimatedBuilder(
          animation: Listenable.merge([_controller, _outroController]),
          builder: (context, _) {
            final outroT = Curves.easeInOutCubic.transform(
              _outroController.value,
            );
            return Transform.translate(
              offset: Offset(0, -18 * outroT),
              child: Transform.scale(
                scale: 1 - (0.035 * outroT),
                child: Opacity(
                  opacity: 1 - (0.88 * outroT),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Builder(
                          builder: (context) {
                            final sceneProgress =
                                (_controller.value / _logoStartT).clamp(
                                  0.0,
                                  1.0,
                                );
                            return CustomPaint(
                              painter: AcSplashPainter(
                                progress: sceneProgress,
                                bgColor: bgColor,
                                primaryColor: primaryColor,
                                accentColor: accentColor,
                                textColor: textColor,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Builder(
                          builder: (context) {
                            final logoProgress = _logoProgress;
                            if (logoProgress <= 0.0) {
                              return const SizedBox.shrink();
                            }
                            return _buildFinalLogoOverlay(
                              logoProgress: logoProgress,
                              bgColor: bgColor,
                              primaryColor: primaryColor,
                              accentColor: accentColor,
                              textColor: textColor,
                              appName: l10n.appName,
                              isRtl: isRtl,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 40,
                        right: 40,
                        child: _buildProgressBar(primaryColor, accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double get _logoProgress {
    final t = _controller.value;
    if (t <= _logoStartT) return 0.0;
    return ((t - _logoStartT) / (1 - _logoStartT)).clamp(0.0, 1.0);
  }

  Widget _buildFinalLogoOverlay({
    required double logoProgress,
    required Color bgColor,
    required Color primaryColor,
    required Color accentColor,
    required Color textColor,
    required String appName,
    required bool isRtl,
  }) {
    final opacity = Curves.easeOut.transform(logoProgress);
    final scale = 0.78 + 0.22 * Curves.easeOutBack.transform(logoProgress);

    return Opacity(
      opacity: opacity,
      child: ColoredBox(
        color: bgColor.withValues(alpha: 0.35 * opacity),
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: AcLogoIconPainter(
                      progress: logoProgress,
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                      bgColor: bgColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: isRtl ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isRtl ? 0 : 2,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 72,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0),
                          primaryColor.withValues(alpha: 0.55),
                          accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color primaryColor, Color accentColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: primaryColor.withValues(alpha: 0.10)),
                    FractionallySizedBox(
                      widthFactor: _controller.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, accentColor],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_controller.value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: primaryColor.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }

  (Color, Color, Color, Color) _themeColors(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.dark => (
        ArcticTheme.arcticDarkBg,
        ArcticTheme.arcticBlue,
        const Color(0xFF00E5FF),
        ArcticTheme.arcticTextPrimary,
      ),
      AppThemeMode.light => (
        ArcticTheme.lightBg,
        ArcticTheme.lightBlue,
        const Color(0xFF0284C7),
        ArcticTheme.lightTextPrimary,
      ),
      AppThemeMode.highContrast => (
        ArcticTheme.hcBg,
        ArcticTheme.hcBlue,
        const Color(0xFFFFD600),
        ArcticTheme.hcTextPrimary,
      ),
      AppThemeMode.auto => (
        ArcticTheme.arcticDarkBg,
        ArcticTheme.arcticBlue,
        const Color(0xFF00E5FF),
        ArcticTheme.arcticTextPrimary,
      ),
    };
  }
}
