import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/core/utils/secure_screen.dart';

class TechProfileScreen extends ConsumerStatefulWidget {
  const TechProfileScreen({super.key});

  @override
  ConsumerState<TechProfileScreen> createState() => _TechProfileScreenState();
}

class _TechProfileScreenState extends ConsumerState<TechProfileScreen> {
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  Future<void> _showEditProfileDialog() async {
    final l = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    var phoneValue = user.phone;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editProfile),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.name,
                  helperText: l.changeYourName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.required : null,
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
              ),
              const SizedBox(height: 12),
              PhoneInputField(
                initialValue: user.phone,
                onChanged: (value) => phoneValue = value,
                optional: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final newName = nameCtrl.text.trim();
    final normalizedPhone = phoneValue.trim();
    if (newName == user.name && normalizedPhone == user.phone) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(authRepositoryProvider)
          .updateOwnProfile(name: newName, phone: normalizedPhone);
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)!.profileUpdated,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.editProfile,
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
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
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.name ?? 'T').substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? l.technician,
                  style: Theme.of(context).textTheme.headlineSmall,
                ).animate().fadeIn(delay: 100.ms),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(delay: 200.ms),
                if ((user?.phone ?? '').isNotEmpty)
                  Text(
                    user!.phone.toDisplayPhone(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ).animate().fadeIn(delay: 260.ms),
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
                  l.language,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _LanguageTile(
                  label: l.english,
                  code: 'en',
                  selected: user?.language == 'en',
                  onTap: () => _updateLanguage(ref, 'en'),
                ),
                _LanguageTile(
                  label: l.urdu,
                  code: 'ur',
                  selected: user?.language == 'ur',
                  onTap: () => _updateLanguage(ref, 'ur'),
                ),
                _LanguageTile(
                  label: l.arabic,
                  code: 'ar',
                  selected: user?.language == 'ar',
                  onTap: () => _updateLanguage(ref, 'ar'),
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
            label: Text(l.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticError,
              side: const BorderSide(color: ArcticTheme.arcticError),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  void _updateLanguage(WidgetRef ref, String lang) {
    ref.read(appLocaleProvider.notifier).setLocale(lang);
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
