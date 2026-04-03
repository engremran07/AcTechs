import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/providers/app_build_provider.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final buildAsync = ref.watch(appBuildNumberProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  size: 72,
                  color: ArcticTheme.arcticBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  l.updateRequiredTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
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
                  error: (_, _) => Text(
                    l.updateRequiredLoading,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(appBuildNumberProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.iUpdatedRefresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
