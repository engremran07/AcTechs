import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TechShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.dashboard_rounded),
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
              icon: const Icon(Icons.history_rounded),
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
