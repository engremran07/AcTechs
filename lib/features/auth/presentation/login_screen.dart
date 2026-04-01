import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/widgets/snackbars.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

const _kRememberEmailKey = 'remember_email';
const _kRememberMeKey = 'remember_me';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kRememberMeKey) ?? false;
    if (saved) {
      final email = prefs.getString(_kRememberEmailKey) ?? '';
      if (mounted) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save / clear remember me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool(_kRememberMeKey, true);
        await prefs.setString(_kRememberEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_kRememberMeKey);
        await prefs.remove(_kRememberEmailKey);
      }

      await ref
          .read(signInProvider.notifier)
          .signIn(_emailController.text.trim(), _passwordController.text);
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Language & Theme ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Language popup
                        PopupMenuButton<String>(
                          onSelected: (code) => ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(code),
                          icon: const Icon(Icons.language_rounded),
                          tooltip: l.language,
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  if (locale == 'en')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'en') const SizedBox(width: 8),
                                  Text(l.english),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ur',
                              child: Row(
                                children: [
                                  if (locale == 'ur')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'ur') const SizedBox(width: 8),
                                  Text(l.urdu),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'ar',
                              child: Row(
                                children: [
                                  if (locale == 'ar')
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  if (locale == 'ar') const SizedBox(width: 8),
                                  Text(l.arabic),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Theme popup
                        PopupMenuButton<AppThemeMode>(
                          onSelected: (mode) => ref
                              .read(appThemeModeProvider.notifier)
                              .setMode(mode),
                          icon: Icon(_themeIcon(themeMode)),
                          tooltip: l.theme,
                          itemBuilder: (_) => [
                            _themeMenuItem(
                              AppThemeMode.auto,
                              Icons.brightness_auto_rounded,
                              l.themeAuto,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.dark,
                              Icons.dark_mode_rounded,
                              l.themeDark,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.light,
                              Icons.light_mode_rounded,
                              l.themeLight,
                              themeMode,
                            ),
                            _themeMenuItem(
                              AppThemeMode.highContrast,
                              Icons.contrast_rounded,
                              l.themeHighContrast,
                              themeMode,
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    // Logo
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                ArcticTheme.arcticBlue,
                                ArcticTheme.arcticBlueDark,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: ArcticTheme.arcticBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.ac_unit_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5)),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l.appName,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 8),
                    Text(
                      l.appSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: InputDecoration(
                        hintText: l.email,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.enterEmail;
                        }
                        if (!value.contains('@')) {
                          return l.invalidEmail;
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: l.password,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l.enterPassword;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSignIn(),
                    ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                    const SizedBox(height: 12),

                    // Remember Me
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: ArcticTheme.arcticBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Text(
                            l.rememberMe,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 650.ms),
                    const SizedBox(height: 24),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArcticTheme.arcticDarkBg,
                                ),
                              )
                            : Text(l.signIn),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.auto:
        return Icons.brightness_auto_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.highContrast:
        return Icons.contrast_rounded;
    }
  }

  PopupMenuItem<AppThemeMode> _themeMenuItem(
    AppThemeMode mode,
    IconData icon,
    String label,
    AppThemeMode current,
  ) {
    final selected = mode == current;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
          Text(label),
          if (selected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
