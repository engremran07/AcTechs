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
import 'package:ac_techs/core/utils/job_search_filter.dart';
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
  final Set<String> _selectedJobIds = {};
  bool _isBulkProcessing = false;

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
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      result = JobSearchFilter.apply(result, query: q);
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

  Future<void> _showBulkTransferDialog() async {
    final l = AppLocalizations.of(context)!;
    final techs = ref.read(allTechniciansProvider).value ?? const [];
    final available = techs.where((t) => t.isActive).toList();
    UserModel? selected;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.transferJob),
          content: available.isEmpty
              ? Text(l.noActiveTechnicians)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.selectedCount(_selectedJobIds.length)} — ${l.transferToTechnician}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<UserModel>(
                      value: selected,
                      isExpanded: true,
                      hint: Text(l.transferToTechnician),
                      items: available
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text(t.name)),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => selected = v),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
            if (available.isNotEmpty)
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(ctx).pop(true),
                child: Text(l.transferJob),
              ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected == null) return;
    if (!mounted) return;

    // BLK-004: confirmation before committing bulk transfer
    final l2 = AppLocalizations.of(context)!;
    final jobCount = _selectedJobIds.length;
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l2.transferJob),
        content: Text(
          '${l2.selectedCount(jobCount)} \u2192 ${selected!.name}?\n${l2.cannotBeUndone}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l2.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l2.transferJob),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;
    if (!mounted) return;

    setState(() => _isBulkProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      final count = await ref
          .read(jobRepositoryProvider)
          .bulkTransferJobs(
            jobIds: _selectedJobIds.toList(),
            newTechId: selected!.uid,
            newTechName: selected!.name,
            adminId: admin.uid,
          );
      if (!mounted) return;
      setState(() => _selectedJobIds.clear());
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)!.bulkTransferSuccess(count),
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        message: AppLocalizations.of(context)!.bulkTransferFailed,
      );
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  Future<void> _bulkCancelTransferRequests(List<JobModel> visibleJobs) async {
    final l = AppLocalizations.of(context)!;
    final pendingIds = _selectedJobIds
        .where(
          (id) => visibleJobs.any((j) => j.id == id && j.isTransferPending),
        )
        .toList();
    if (pendingIds.isEmpty) return;

    setState(() => _isBulkProcessing = true);
    try {
      await ref
          .read(jobRepositoryProvider)
          .bulkCancelTransferRequests(pendingIds);
      if (!mounted) return;
      setState(() => _selectedJobIds.clear());
      AppFeedback.success(
        context,
        message: l.bulkCancelTransferSuccess(pendingIds.length),
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error(context, message: l.bulkCancelTransferFailed);
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
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
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _selectedJobIds.clear();
                    }),
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
                  onChanged: (v) => setState(() {
                    _statusFilter = v ?? 'all';
                    _selectedJobIds.clear();
                  }),
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
                    onChanged: (v) => setState(() {
                      _techFilter = v ?? '';
                      _selectedJobIds.clear();
                    }),
                  ),
              ],
            ),
          ),
          // ── Bulk action bar ─────────────────────────────────────────────
          if (_selectedJobIds.isNotEmpty)
            BulkActionBar(
              selectedCount: _selectedJobIds.length,
              isProcessing: _isBulkProcessing,
              onClear: () => setState(() => _selectedJobIds.clear()),
              actions: [
                BulkAction(
                  label: l.transferJob,
                  icon: Icons.swap_horiz_rounded,
                  color: ArcticTheme.arcticBlue,
                  onPressed: _showBulkTransferDialog,
                ),
                BulkAction(
                  label: l.cancelTransferRequest,
                  icon: Icons.cancel_outlined,
                  color: ArcticTheme.arcticWarning,
                  onPressed: () => jobsAsync.whenData(
                    (all) => _bulkCancelTransferRequests(_applyFilters(all)),
                  ),
                ),
              ],
            ),
          // ── Job list ────────────────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              data: (all) {
                final jobs = _applyFilters(all);
                // Prune stale selections
                _selectedJobIds.removeWhere(
                  (id) => !jobs.any((j) => j.id == id),
                );
                // UX-001: only show limit note when the cap was hit (≥ 150 docs returned)
                final limitHit = all.length >= 150;
                if (jobs.isEmpty) {
                  return Center(child: Text(l.noJobsFound));
                }
                return Column(
                  children: [
                    if (limitHit)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            l.allJobsLimitNote,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ref.invalidate(allJobsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: jobs.length,
                          itemBuilder: (ctx, i) {
                            final job = jobs[i];
                            final isSelected = _selectedJobIds.contains(job.id);
                            return _AllJobTile(
                                  job: job,
                                  isSelected: isSelected,
                                  onTransfer:
                                      _selectedJobIds.isEmpty &&
                                          !job.isSettlementLocked
                                      ? () => _showTransferDialog(job)
                                      : null,
                                  onTap: _selectedJobIds.isNotEmpty
                                      ? () => setState(() {
                                          if (isSelected) {
                                            _selectedJobIds.remove(job.id);
                                          } else {
                                            _selectedJobIds.add(job.id);
                                          }
                                        })
                                      : null,
                                  onLongPress: () => setState(() {
                                    _selectedJobIds.add(job.id);
                                  }),
                                )
                                .animate(delay: (i * 40).ms)
                                .fadeIn()
                                .slideX(begin: 0.03);
                          },
                        ),
                      ),
                    ),
                  ],
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
  const _AllJobTile({
    required this.job,
    this.isSelected = false,
    this.onTransfer,
    this.onTap,
    this.onLongPress,
  });

  final JobModel job;
  final bool isSelected;
  final VoidCallback? onTransfer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

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
      color: isSelected ? cs.primary.withValues(alpha: 0.12) : null,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary, width: 1.5),
            )
          : null,
      child: ListTile(
        dense: true,
        onTap: onTap,
        onLongPress: onLongPress,
        leading: isSelected
            ? Icon(Icons.check_circle_rounded, color: cs.primary)
            : null,
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
            if (job.transferredFromTechId.isNotEmpty &&
                !job.isTransferPending) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l.transferredBadge,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
