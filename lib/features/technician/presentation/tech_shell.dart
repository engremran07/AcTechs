import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/providers/shared_install_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TechShell extends ConsumerWidget {
  const TechShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/tech/submit')) return 1;
    if (location.startsWith('/tech/inout')) return 2;
    if (location.startsWith('/tech/summary')) return 2;
    if (location.startsWith('/tech/history')) return 3;
    if (location.startsWith('/tech/settings')) return 4;
    if (location.startsWith('/tech/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSettlementBatches = ref
        .watch(technicianSettlementInboxProvider)
        .maybeWhen(
          data: (jobs) => jobs
              .map((job) => job.settlementBatchId.trim())
              .where((id) => id.isNotEmpty)
              .toSet()
              .length,
          orElse: () => 0,
        );
    final sharedTeamsCount = ref
        .watch(pendingSharedInstallAggregatesProvider)
        .maybeWhen(data: (aggs) => aggs.length, orElse: () => 0);
    final isHome = _currentIndex(context) == 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Allow router to pop pushed screens (e.g., monthly summary pushed from in/out)
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (!isHome) {
          context.go('/tech');
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) {
            final current = _currentIndex(context);
            if (current == index) {
              HapticFeedback.selectionClick();
              return;
            }
            switch (index) {
              case 0:
                context.go('/tech');
              case 1:
                context.go('/tech/submit');
              case 2:
                context.go('/tech/inout');
              case 3:
                context.go('/tech/history');
              case 4:
                context.go('/tech/settings');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.dashboard_rounded),
                  if (sharedTeamsCount > 0)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: AppLocalizations.of(context)!.submit,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.swap_vert_rounded),
              label: AppLocalizations.of(context)!.inOut,
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.history_rounded),
                  if (pendingSettlementBatches > 0)
                    Positioned(
                      right: -2,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: AppLocalizations.of(context)!.history,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: AppLocalizations.of(context)!.settings,
            ),
          ],
        ),
      ),
    );
  }
}
