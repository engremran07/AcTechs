import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).value;
    final allJobs = ref.watch(allJobsProvider);
    final pending = ref.watch(pendingApprovalsProvider);
    final technicians = ref.watch(allTechniciansProvider);
    final companies = ref.watch(allCompaniesProvider);

    void refresh() {
      ref.invalidate(allJobsProvider);
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(allTechniciansProvider);
      ref.invalidate(allCompaniesProvider);
    }

    return AppShortcuts(
      onRefresh: refresh,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.adminPanel),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => context.go('/admin/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await ref.read(signInProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ArcticRefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.welcomeBack,
                  style: Theme.of(context).textTheme.bodySmall,
                ).animate().fadeIn(),
                Text(
                  user?.name ?? l.admin,
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 24),

                // Summary Cards
                allJobs.when(
                  data: (jobs) {
                    final pendingCount = jobs.where((j) => j.isPending).length;
                    final approvedCount = jobs
                        .where((j) => j.isApproved)
                        .length;
                    final totalExpenses = jobs.fold<double>(
                      0,
                      (s, j) => s + j.expenses,
                    );

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DashCard(
                                title: l.totalJobs,
                                value: '${jobs.length}',
                                icon: Icons.work_outline,
                                color: ArcticTheme.arcticBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DashCard(
                                title: l.pending,
                                value: '$pendingCount',
                                icon: Icons.pending_outlined,
                                color: ArcticTheme.arcticPending,
                                onTap: () => context.go('/admin/approvals'),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DashCard(
                                title: l.approved,
                                value: '$approvedCount',
                                icon: Icons.check_circle_outline,
                                color: ArcticTheme.arcticSuccess,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DashCard(
                                title: l.expenses,
                                value: AppFormatters.currency(totalExpenses),
                                icon: Icons.payments_outlined,
                                color: ArcticTheme.arcticWarning,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      ],
                    );
                  },
                  loading: () => const ArcticShimmer(height: 90, count: 2),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Team Summary
                technicians.when(
                  data: (techs) {
                    final active = techs.where((t) => t.isActive).length;
                    return Column(
                      children: [
                        _DashCard(
                          title: l.team,
                          value: l.activeOfTotal(active, techs.length),
                          icon: Icons.people_outline,
                          color: ArcticTheme.arcticBlue,
                          onTap: () => context.go('/admin/team'),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 12),
                        companies.when(
                          data: (items) => _DashCard(
                            title: l.companies,
                            value: '${items.where((c) => c.isActive).length}',
                            icon: Icons.apartment_rounded,
                            color: ArcticTheme.arcticWarning,
                            onTap: () => context.go('/admin/companies'),
                          ),
                          loading: () =>
                              const ArcticShimmer(height: 70, count: 1),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                  loading: () => const ArcticShimmer(height: 70, count: 1),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Danger Zone
                Text(
                  l.dangerZone,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ArcticTheme.arcticError,
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 12),
                ArcticCard(
                  onTap: () => context.go('/admin/flush'),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ArcticTheme.arcticError.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: ArcticTheme.arcticError,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.flushDatabase,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: ArcticTheme.arcticError,
                              ),
                            ),
                            Text(
                              l.flushDatabaseSubtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 650.ms),
                const SizedBox(height: 24),

                // Recent Pending
                Text(
                  l.recentPending,
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 12),
                pending.when(
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return ArcticCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              l.noApprovals,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: jobs
                          .take(5)
                          .map(
                            (job) => ArcticCard(
                              onTap: () => context.go('/admin/approvals'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.clientName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        Text(
                                          '${job.techName} • INV-${job.invoiceNumber}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const StatusBadge(status: 'pending'),
                                ],
                              ),
                            ),
                          )
                          .toList()
                          .animate(interval: 80.ms)
                          .fadeIn()
                          .slideX(begin: 0.05),
                    );
                  },
                  loading: () => const ArcticShimmer(count: 3),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ArcticCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right,
              color: ArcticTheme.arcticTextSecondary,
            ),
        ],
      ),
    );
  }
}
