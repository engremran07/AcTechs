import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ──
          _ProfileHeader(
            name: user?.name ?? 'User',
            email: user?.email ?? '',
            role: user?.role ?? 'technician',
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // ── Theme Section ──
          _SectionTitle(title: l.appearance),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                _ThemeTile(
                  icon: Icons.brightness_auto_rounded,
                  label: l.themeAuto,
                  sublabel: l.themeAutoDesc,
                  selected: themeMode == AppThemeMode.auto,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.auto),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.dark_mode_rounded,
                  label: l.themeDark,
                  sublabel: l.themeDarkDesc,
                  selected: themeMode == AppThemeMode.dark,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.dark),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.light_mode_rounded,
                  label: l.themeLight,
                  sublabel: l.themeLightDesc,
                  selected: themeMode == AppThemeMode.light,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.light),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.contrast_rounded,
                  label: l.themeHighContrast,
                  sublabel: l.themeHighContrastDesc,
                  selected: themeMode == AppThemeMode.highContrast,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.highContrast),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          // ── Language Section ──
          _SectionTitle(title: l.language),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                _LanguageTile(
                  flag: '🇬🇧',
                  label: l.english,
                  selected: locale == 'en',
                  onTap: () => _updateLanguage(ref, user?.uid, 'en'),
                ),
                const Divider(height: 1),
                _LanguageTile(
                  flag: '🇵🇰',
                  label: l.urdu,
                  selected: locale == 'ur',
                  onTap: () => _updateLanguage(ref, user?.uid, 'ur'),
                ),
                const Divider(height: 1),
                _LanguageTile(
                  flag: '🇸🇦',
                  label: l.arabic,
                  selected: locale == 'ar',
                  onTap: () => _updateLanguage(ref, user?.uid, 'ar'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          // ── App Info ──
          _SectionTitle(title: l.about),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: l.version,
                  value: '1.0.0',
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.business_rounded,
                  label: l.company,
                  value: l.appName,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: l.region,
                  value: l.saudiArabia,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.03),
          const SizedBox(height: 32),

          // ── Sign Out ──
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await _confirmSignOut(context);
              if (!confirmed) return;
              await ref.read(signInProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticError,
              side: const BorderSide(color: ArcticTheme.arcticError),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _updateLanguage(WidgetRef ref, String? uid, String lang) {
    ref.read(appLocaleProvider.notifier).setLocale(lang);
    if (uid != null) {
      ref.read(userRepositoryProvider).updateLanguage(uid, lang);
    }
  }

  Future<bool> _confirmSignOut(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.signOut),
            content: Text(l.signOutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArcticTheme.arcticError,
                ),
                child: Text(l.signOut),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Private Widgets ──

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return ArcticCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [ArcticTheme.arcticWarning, ArcticTheme.arcticWarningDark]
                    : [ArcticTheme.arcticBlue, ArcticTheme.arcticBlueDark],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isAdmin
                                ? ArcticTheme.arcticWarning
                                : ArcticTheme.arcticBlue)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAdmin
                        ? (AppLocalizations.of(context)?.administrator ??
                              'Administrator')
                        : (AppLocalizations.of(context)?.technician ??
                              'Technician'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isAdmin
                          ? ArcticTheme.arcticWarning
                          : ArcticTheme.arcticBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: Text(value, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
