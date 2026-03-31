import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/approvals')) return 1;
    if (location.startsWith('/admin/analytics')) return 2;
    if (location.startsWith('/admin/team')) return 3;
    if (location.startsWith('/admin/settings')) return -1; // Not in bottom nav
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final isHome = idx <= 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!isHome) {
          context.go('/admin');
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: idx < 0 ? 0 : idx,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/admin');
              case 1:
                context.go('/admin/approvals');
              case 2:
                context.go('/admin/analytics');
              case 3:
                context.go('/admin/team');
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: AppLocalizations.of(context)!.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pending_actions_rounded),
              label: AppLocalizations.of(context)!.approvals,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.analytics_outlined),
              label: AppLocalizations.of(context)!.analytics,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline_rounded),
              label: AppLocalizations.of(context)!.team,
            ),
          ],
        ),
      ),
    );
  }
}
