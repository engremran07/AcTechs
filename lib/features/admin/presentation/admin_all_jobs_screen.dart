import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class AdminAllJobsScreen extends ConsumerStatefulWidget {
  const AdminAllJobsScreen({super.key});

  @override
  ConsumerState<AdminAllJobsScreen> createState() => _AdminAllJobsScreenState();
}

class _AdminAllJobsScreenState extends ConsumerState<AdminAllJobsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all' | 'pending' | 'approved' | 'rejected'
  String _techFilter = ''; // techId, or '' for all

  List<JobModel> _applyFilters(List<JobModel> all) {
    var result = all;
    if (_statusFilter != 'all') {
      result = result
          .where((j) => j.status.name == _statusFilter)
          .toList(growable: false);
    }
    if (_techFilter.isNotEmpty) {
      result = result
          .where((j) => j.techId == _techFilter)
          .toList(growable: false);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (j) =>
                j.invoiceNumber.toLowerCase().contains(q) ||
                j.techName.toLowerCase().contains(q) ||
                j.clientName.toLowerCase().contains(q),
          )
          .toList(growable: false);
    }
    return result;
  }

  Future<void> _showTransferDialog(JobModel job) async {
    final l = AppLocalizations.of(context)!;
    final techs = ref.read(allTechniciansProvider).value ?? const [];
    final available = techs
        .where((t) => t.isActive && t.uid != job.techId)
        .toList();
    UserModel? selectedTech;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.transferToTechnician),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.currentTechnicianLabel}: ${job.techName}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Text(l.transferJobNotAllowed)
                else
                  DropdownButton<UserModel>(
                    value: selectedTech,
                    isExpanded: true,
                    hint: Text(l.transferToTechnician),
                    items: available
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTech = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
            if (available.isNotEmpty)
              FilledButton(
                onPressed: selectedTech == null
                    ? null
                    : () async {
                        final admin = ref.read(currentUserProvider).value;
                        if (admin == null) return;
                        Navigator.of(ctx).pop();
                        try {
                          await ref
                              .read(jobRepositoryProvider)
                              .transferJob(
                                jobId: job.id,
                                newTechId: selectedTech!.uid,
                                newTechName: selectedTech!.name,
                                adminId: admin.uid,
                              );
                          if (!mounted) return;
                          AppFeedback.success(
                            context,
                            message: l.transferJobSuccess(selectedTech!.name),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          AppFeedback.error(context, message: l.genericError);
                        }
                      },
                child: Text(l.transferJob),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(allJobsProvider);
    final techsAsync = ref.watch(allTechniciansProvider);
    final techs = techsAsync.value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l.allJobs)),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l.search,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Status filter
                DropdownButton<String>(
                  value: _statusFilter,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(l.all)),
                    DropdownMenuItem(value: 'pending', child: Text(l.pending)),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text(l.approved),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text(l.rejected),
                    ),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
                const SizedBox(width: 8),
                // Technician filter
                if (techs.isNotEmpty)
                  DropdownButton<String>(
                    value: _techFilter.isEmpty ? '' : _techFilter,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    hint: Text(l.allTechs),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l.allTechs)),
                      ...techs.map(
                        (t) => DropdownMenuItem(
                          value: t.uid,
                          child: Text(t.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _techFilter = v ?? ''),
                  ),
              ],
            ),
          ),
          // ── Job list ────────────────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              data: (all) {
                final jobs = _applyFilters(all);
                if (jobs.isEmpty) {
                  return Center(child: Text(l.noJobsFound));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allJobsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: jobs.length,
                    itemBuilder: (ctx, i) {
                      final job = jobs[i];
                      return _AllJobTile(
                            job: job,
                            onTransfer: job.isSettlementLocked
                                ? null
                                : () => _showTransferDialog(job),
                          )
                          .animate(delay: (i * 40).ms)
                          .fadeIn()
                          .slideX(begin: 0.03);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.genericError,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Job tile ──────────────────────────────────────────────────────────────────

class _AllJobTile extends StatelessWidget {
  const _AllJobTile({required this.job, this.onTransfer});

  final JobModel job;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    String statusLabel;
    switch (job.status) {
      case JobStatus.approved:
        statusColor = ArcticTheme.arcticSuccess;
        statusLabel = l.approved;
      case JobStatus.rejected:
        statusColor = ArcticTheme.arcticError;
        statusLabel = l.rejected;
      case JobStatus.pending:
        statusColor = ArcticTheme.arcticPending;
        statusLabel = l.pending;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(
                job.invoiceNumber,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (job.isTransferPending) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ArcticTheme.arcticWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l.transferPendingBadge,
                  style: const TextStyle(
                    color: ArcticTheme.arcticWarning,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${job.techName} • ${job.clientName} • '
          '${AppFormatters.units(job.totalUnits)}'
          '${job.date != null ? " • ${AppFormatters.date(job.date!)}" : ""}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: onTransfer == null
            ? null
            : IconButton(
                tooltip: l.transferJob,
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: onTransfer,
              ),
      ),
    );
  }
}
