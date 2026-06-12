import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/utils/responsive.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final _drawerController = ZoomDrawerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WhatsNewChecker.checkAndShow(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/approvals')) return 1;
    if (location.startsWith('/admin/analytics')) return 2;
    if (location.startsWith('/admin/team')) return 3;
    if (location.startsWith('/admin/all-jobs')) return 4;
    if (location.startsWith('/admin/companies')) return 5;
    if (location.startsWith('/admin/import')) return 6;
    if (location.startsWith('/admin/settlements')) return 7;
    if (location.startsWith('/admin/reconcile')) return 8;
    if (location.startsWith('/admin/settings')) return 9;
    if (location.startsWith('/admin/flush')) return 10;
    if (location.startsWith('/admin/jobs/filter/')) return -1;
    if (location.startsWith('/admin/job/')) return -1;
    return 0;
  }

  void _desktopNavigateTo(int index) {
    switch (index) {
      case 0:
        context.go('/admin');
      case 1:
        context.go('/admin/approvals');
      case 2:
        context.go('/admin/analytics');
      case 3:
        context.go('/admin/team');
      case 4:
        context.push('/admin/all-jobs');
      case 5:
        context.push('/admin/companies');
      case 6:
        context.push('/admin/import');
      case 7:
        context.push('/admin/settlements');
      case 8:
        context.push('/admin/reconcile');
      case 9:
        context.push('/admin/settings');
      case 10:
        context.push('/admin/flush');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final idx = _currentIndex(context);
    final isHome = idx == 0;
    final isDesktop = kIsWeb && Responsive.isDesktop(context);

    final mainContent = ShellBackNavigationScope(
      isHome: isHome,
      homeRoute: '/admin',
      child: Scaffold(
        body: ResponsiveBody(padding: EdgeInsets.zero, child: widget.child),
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: idx < 0 ? 0 : idx,
                  onDestinationSelected: (index) {
                    final current = idx;
                    if (current == index) {
                      HapticFeedback.selectionClick();
                      return;
                    }
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
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: l.dashboard,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.pending_actions_outlined),
                      selectedIcon: const Icon(Icons.pending_actions_rounded),
                      label: l.approvals,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.analytics_outlined),
                      selectedIcon: const Icon(Icons.analytics_rounded),
                      label: l.analytics,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.people_outline_rounded),
                      selectedIcon: const Icon(Icons.people_rounded),
                      label: l.team,
                    ),
                  ],
                ),
              ),
      ),
    );

    if (isDesktop) {
      // Desktop: NavigationDrawer with all 11 admin routes
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: NavigationDrawer(
                selectedIndex: idx < 0 ? 0 : idx,
                onDestinationSelected: _desktopNavigateTo,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
                    child: Text(
                      l.appName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const Divider(),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard_rounded),
                    label: Text(l.dashboard),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.pending_actions_outlined),
                    selectedIcon: const Icon(Icons.pending_actions_rounded),
                    label: Text(l.approvals),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.analytics_outlined),
                    selectedIcon: const Icon(Icons.analytics_rounded),
                    label: Text(l.analytics),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.people_outline_rounded),
                    selectedIcon: const Icon(Icons.people_rounded),
                    label: Text(l.team),
                  ),
                  const Divider(),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.list_alt_outlined),
                    selectedIcon: const Icon(Icons.list_alt_rounded),
                    label: Text(l.allJobs),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.business_outlined),
                    selectedIcon: const Icon(Icons.business_rounded),
                    label: Text(l.companies),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.upload_file_outlined),
                    selectedIcon: const Icon(Icons.upload_file_rounded),
                    label: Text(l.importHistoryData),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long_rounded),
                    label: Text(l.settlements),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    selectedIcon: const Icon(
                      Icons.assignment_turned_in_rounded,
                    ),
                    label: Text(l.reconciliation),
                  ),
                  const Divider(),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings_rounded),
                    label: Text(l.settings),
                  ),
                  NavigationDrawerDestination(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    selectedIcon: const Icon(Icons.delete_sweep_rounded),
                    label: Text(l.flushDatabase),
                  ),
                ],
              ),
            ),
            const VerticalDivider(thickness: 0.5, width: 1),
            Expanded(child: mainContent),
          ],
        ),
      );
    }

    return ZoomDrawerWrapper(
      controller: _drawerController,
      menuScreen: const DrawerMenuContent(isAdmin: true),
      mainScreen: mainContent,
    );
  }
}
