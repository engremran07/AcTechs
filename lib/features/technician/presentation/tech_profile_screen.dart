import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TechProfileScreen extends ConsumerWidget {
  const TechProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ArcticTheme.arcticBlue,
                        ArcticTheme.arcticBlue.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.name ?? 'T').substring(0, 1).toUpperCase(),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? AppLocalizations.of(context)!.technician,
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(delay: 100.ms),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Language Selection
          ArcticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.language,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  label: 'English',
                  code: 'en',
                  selected: user?.language == 'en',
                  onTap: () => _updateLanguage(ref, user?.uid, 'en'),
                ),
                _LanguageTile(
                  label: 'اردو',
                  code: 'ur',
                  selected: user?.language == 'ur',
                  onTap: () => _updateLanguage(ref, user?.uid, 'ur'),
                ),
                _LanguageTile(
                  label: 'العربية',
                  code: 'ar',
                  selected: user?.language == 'ar',
                  onTap: () => _updateLanguage(ref, user?.uid, 'ar'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),

          // Sign Out
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(signInProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(AppLocalizations.of(context)!.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticError,
              side: const BorderSide(color: ArcticTheme.arcticError),
            ),
          ).animate().fadeIn(delay: 400.ms),
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
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle, color: ArcticTheme.arcticBlue)
          : const Icon(
              Icons.circle_outlined,
              color: ArcticTheme.arcticTextSecondary,
            ),
      onTap: onTap,
    );
  }
}
