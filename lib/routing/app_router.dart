import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/auth/presentation/login_screen.dart';
import 'package:ac_techs/features/auth/presentation/splash_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_shell.dart';
import 'package:ac_techs/features/technician/presentation/tech_dashboard_screen.dart';
import 'package:ac_techs/features/technician/presentation/submit_job_screen.dart';
import 'package:ac_techs/features/technician/presentation/job_history_screen.dart';
import 'package:ac_techs/features/technician/presentation/job_details_screen.dart';
import 'package:ac_techs/features/jobs/presentation/job_type_filter_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_profile_screen.dart';
import 'package:ac_techs/features/admin/presentation/admin_shell.dart';
import 'package:ac_techs/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:ac_techs/features/admin/presentation/approvals_screen.dart';
import 'package:ac_techs/features/admin/presentation/analytics_screen.dart';
import 'package:ac_techs/features/admin/presentation/companies_screen.dart';
import 'package:ac_techs/features/admin/presentation/team_screen.dart';
import 'package:ac_techs/features/admin/presentation/flush_database_screen.dart';
import 'package:ac_techs/features/admin/presentation/historical_import_screen.dart';
import 'package:ac_techs/features/settings/presentation/settings_screen.dart';
import 'package:ac_techs/features/expenses/presentation/daily_in_out_screen.dart';
import 'package:ac_techs/features/expenses/presentation/monthly_summary_screen.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

final _routerKey = GlobalKey<NavigatorState>();

/// A `CustomTransitionPage` that fades and slides up slightly — used for all
/// full-screen route pushes so the app feels snappy and polished.
CustomTransitionPage<T> _slideFadePage<T>({
  required LocalKey pageKey,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeTween = CurveTween(curve: Curves.easeOut);
      final slideTween = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use a refreshListenable to trigger redirect without recreating GoRouter
  final notifier = ValueNotifier<int>(0);
  Timer? refreshDebounce;

  void queueRefresh() {
    if (refreshDebounce?.isActive ?? false) return;
    refreshDebounce = Timer(const Duration(milliseconds: 40), () {
      notifier.value++;
    });
  }

  ref.listen(authStateProvider, (_, _) => queueRefresh());
  ref.listen(currentUserProvider, (_, _) => queueRefresh());

  ref.onDispose(() {
    refreshDebounce?.cancel();
    notifier.dispose();
  });

  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isSplashRoute = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';

      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      final isAuthLoading = authState.isLoading;
      final isLoggedIn = authState.value != null;
      final user = currentUser.value;

      // Keep users on splash until auth + profile streams settle.
      if (isAuthLoading || (isLoggedIn && currentUser.isLoading)) {
        return isSplashRoute ? null : '/splash';
      }

      if (!isLoggedIn) {
        return isLoginRoute ? null : '/login';
      }

      if (currentUser.hasError || user == null) {
        return isLoginRoute ? null : '/login';
      }

      if (!user.isActive) {
        return '/login';
      }

      if (isSplashRoute || isLoginRoute) {
        return user.isAdmin ? '/admin' : '/tech';
      }

      // Prevent technician from accessing admin routes and vice versa
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isTechRoute = state.matchedLocation.startsWith('/tech');
      if (user.isAdmin && isTechRoute) return '/admin';
      if (!user.isAdmin && isAdminRoute) return '/tech';

      return null;
    },
    routes: [
      // ✅ Splash Screen (shown on every app launch)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return MaterialPage(child: SplashScreen(onComplete: () {}));
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _slideFadePage(pageKey: state.pageKey, child: const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => TechShell(child: child),
        routes: [
          GoRoute(
            path: '/tech',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TechDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/submit',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SubmitJobScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/inout',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const DailyInOutScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/summary',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const MonthlySummaryScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/history',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const JobHistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/job/:jobId',
            pageBuilder: (context, state) {
              final initialJob = state.extra is JobModel
                  ? state.extra as JobModel
                  : null;
              final jobId = state.pathParameters['jobId'] ?? '';
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobDetailsScreen(jobId: jobId, initialJob: initialJob),
              );
            },
          ),
          GoRoute(
            path: '/tech/jobs/filter/:type',
            pageBuilder: (context, state) {
              final typeRaw = state.pathParameters['type'] ?? '';
              final filter =
                  jobAcTypeFilterFromPath(typeRaw) ?? JobAcTypeFilter.split;
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobTypeFilterScreen(filter: filter, isAdminScope: false),
              );
            },
          ),
          GoRoute(
            path: '/tech/profile',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TechProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/tech/settings',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/approvals',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const ApprovalsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/team',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const TeamScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/companies',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const CompaniesScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/import',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const HistoricalImportScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/flush',
            pageBuilder: (context, state) => _slideFadePage(
              pageKey: state.pageKey,
              child: const FlushDatabaseScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/jobs/filter/:type',
            pageBuilder: (context, state) {
              final typeRaw = state.pathParameters['type'] ?? '';
              final filter =
                  jobAcTypeFilterFromPath(typeRaw) ?? JobAcTypeFilter.split;
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobTypeFilterScreen(filter: filter, isAdminScope: true),
              );
            },
          ),
          GoRoute(
            path: '/admin/job/:jobId',
            pageBuilder: (context, state) {
              final initialJob = state.extra is JobModel
                  ? state.extra as JobModel
                  : null;
              final jobId = state.pathParameters['jobId'] ?? '';
              return _slideFadePage(
                pageKey: state.pageKey,
                child: JobDetailsScreen(jobId: jobId, initialJob: initialJob),
              );
            },
          ),
        ],
      ),
    ],
  );
});
