import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/user_model.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/auth/presentation/login_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_shell.dart';
import 'package:ac_techs/features/technician/presentation/tech_dashboard_screen.dart';
import 'package:ac_techs/features/technician/presentation/submit_job_screen.dart';
import 'package:ac_techs/features/technician/presentation/job_history_screen.dart';
import 'package:ac_techs/features/technician/presentation/tech_profile_screen.dart';
import 'package:ac_techs/features/admin/presentation/admin_shell.dart';
import 'package:ac_techs/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:ac_techs/features/admin/presentation/approvals_screen.dart';
import 'package:ac_techs/features/admin/presentation/analytics_screen.dart';
import 'package:ac_techs/features/admin/presentation/companies_screen.dart';
import 'package:ac_techs/features/admin/presentation/team_screen.dart';
import 'package:ac_techs/features/settings/presentation/settings_screen.dart';
import 'package:ac_techs/features/expenses/presentation/daily_in_out_screen.dart';
import 'package:ac_techs/features/expenses/presentation/monthly_summary_screen.dart';

final _routerKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Use a refreshListenable to trigger redirect without recreating GoRouter
  final notifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(currentUserProvider, (_, __) => notifier.value++);

  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    navigatorKey: _routerKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      final isLoggedIn = authState.value != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final user = currentUser.value;

      if (!isLoggedIn) {
        return isLoginRoute ? null : '/login';
      }

      if (isLoginRoute && user != null) {
        return user.isAdmin ? '/admin' : '/tech';
      }

      // Prevent technician from accessing admin routes and vice versa
      if (user != null) {
        final isAdminRoute = state.matchedLocation.startsWith('/admin');
        final isTechRoute = state.matchedLocation.startsWith('/tech');
        if (user.isAdmin && isTechRoute) return '/admin';
        if (!user.isAdmin && isAdminRoute) return '/tech';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => TechShell(child: child),
        routes: [
          GoRoute(
            path: '/tech',
            builder: (context, state) => const TechDashboardScreen(),
          ),
          GoRoute(
            path: '/tech/submit',
            builder: (context, state) => const SubmitJobScreen(),
          ),
          GoRoute(
            path: '/tech/inout',
            builder: (context, state) => const DailyInOutScreen(),
          ),
          GoRoute(
            path: '/tech/summary',
            builder: (context, state) => const MonthlySummaryScreen(),
          ),
          GoRoute(
            path: '/tech/history',
            builder: (context, state) => const JobHistoryScreen(),
          ),
          GoRoute(
            path: '/tech/profile',
            builder: (context, state) => const TechProfileScreen(),
          ),
          GoRoute(
            path: '/tech/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/approvals',
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/team',
            builder: (context, state) => const TeamScreen(),
          ),
          GoRoute(
            path: '/admin/companies',
            builder: (context, state) => const CompaniesScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
