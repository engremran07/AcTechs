import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/providers/app_build_provider.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Shown when the admin has enabled enforceMinimumBuild and the current
/// APK build number is below the minimum. Prevents access until the app
/// is updated. Admins are exempt and never see this screen.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final buildAsync = ref.watch(appBuildNumberProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_outlined,
                size: 72,
                color: ArcticTheme.arcticWarning,
              ),
              const SizedBox(height: 24),
              Text(
                l.updateRequiredTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              buildAsync.when(
                data: (build) => Text(
                  l.updateRequiredBody(build),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                loading: () => Text(
                  l.updateRequiredLoading,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Re-check by invalidating the build number provider so
                  // if the user installs the update, the app will proceed.
                  ref.invalidate(appBuildNumberProvider);
                  ref.invalidate(approvalConfigProvider);
                },
                icon: const Icon(Icons.refresh),
                label: Text(l.iUpdatedRefresh),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await ref.read(signInProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                child: Text(l.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
