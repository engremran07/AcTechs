import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

class AdminSharedInstallsScreen extends ConsumerWidget {
  const AdminSharedInstallsScreen({super.key});

  String _resolveTechnicianName(JobModel job, Map<String, String> namesById) {
    final byId = namesById[job.techId]?.trim() ?? '';
    if (byId.isNotEmpty) return byId;
    return job.techName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(approvedSharedInstallsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.approvedSharedInstalls)),
      body: SafeArea(
        child: jobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Text(
                  l.noMatchingJobs,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }
            // Group by sharedInstallGroupKey — one tile per invoice.
            final grouped = <String, List<JobModel>>{};
            for (final job in jobs) {
              final key = job.sharedInstallGroupKey.isNotEmpty
                  ? job.sharedInstallGroupKey
                  : job.id;
              (grouped[key] ??= []).add(job);
            }
            final sharedNamesByGroup =
                ref
                    .watch(
                      sharedInstallerNamesProvider(
                        SharedInstallerNamesQuery.fromKeys(grouped.keys),
                      ),
                    )
                    .value ??
                const <String, List<String>>{};
            final userNamesById = <String, String>{
              for (final user in (usersAsync.value ?? const <UserModel>[]))
                user.uid: user.name,
            };
            final groups = grouped.values.toList();
            return ArcticRefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(approvedSharedInstallsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupJobs = groups[index];
                  final rep = groupJobs.first;
                  final resolved =
                      (sharedNamesByGroup[rep.sharedInstallGroupKey] ??
                              const <String>[])
                          .map((name) => name.trim())
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList(growable: false)
                        ..sort();
                  final fallback =
                      groupJobs
                          .map((j) => _resolveTechnicianName(j, userNamesById))
                          .map((name) => name.trim())
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList(growable: false)
                        ..sort();
                  final techNames = (resolved.isNotEmpty ? resolved : fallback)
                      .join(', ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ArcticCard(
                      onTap: () {
                        if (groupJobs.length == 1) {
                          context.push('/admin/job/${rep.id}', extra: rep);
                        } else {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      rep.invoiceNumber,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  ...groupJobs.map(
                                    (j) => ListTile(
                                      title: Text(
                                        _resolveTechnicianName(
                                          j,
                                          userNamesById,
                                        ),
                                      ),
                                      subtitle: Text(j.invoiceNumber),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push(
                                          '/admin/job/${j.id}',
                                          extra: j,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rep.clientName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rep.invoiceNumber} • $techNames',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.date(rep.date),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const StatusBadge(status: 'approved'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: ArcticTheme.arcticBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: ArcticTheme.arcticBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.groups_rounded,
                                      size: 12,
                                      color: ArcticTheme.arcticBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${groupJobs.length} ${l.technicians}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: ArcticTheme.arcticBlue,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              l.genericError,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
    );
  }
}
