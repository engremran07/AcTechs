import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

class JobHistoryScreen extends ConsumerStatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  ConsumerState<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends ConsumerState<JobHistoryScreen> {
  String _search = '';
  String _statusFilter = 'all';
  bool _sortNewest = true;

  List<JobModel> _applyFilters(List<JobModel> jobs) {
    var filtered = jobs.toList();

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered
          .where(
            (j) =>
                j.clientName.toLowerCase().contains(q) ||
                j.invoiceNumber.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered.where((j) => j.status.name == _statusFilter).toList();
    }

    filtered.sort((a, b) {
      final aDate = a.date ?? DateTime(2000);
      final bDate = b.date ?? DateTime(2000);
      return _sortNewest ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(technicianJobsProvider);
    final locale = ref.watch(appLocaleProvider);
    final l = AppLocalizations.of(context)!;

    void refresh() {
      HapticFeedback.lightImpact();
      ref.invalidate(technicianJobsProvider);
    }

    return AppShortcuts(
      onRefresh: refresh,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.jobHistory),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l.exportPdf,
              onPressed: () async {
                final jobList = jobs.value;
                if (jobList == null || jobList.isEmpty) return;
                final filtered = _applyFilters(jobList);
                await PdfGenerator.previewPdf(context, filtered, locale);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: jobs.when(
            data: (jobList) {
              final pendingCount = jobList.where((j) => j.isPending).length;
              final approvedCount = jobList.where((j) => j.isApproved).length;
              final rejectedCount = jobList.where((j) => j.isRejected).length;
              final filtered = _applyFilters(jobList);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ArcticSearchBar(
                      hint: l.searchByClientOrInvoice,
                      onChanged: (v) => setState(() => _search = v),
                      trailing: SortButton<bool>(
                        currentValue: _sortNewest,
                        options: [
                          SortOption(label: l.newestFirst, value: true),
                          SortOption(label: l.oldestFirst, value: false),
                        ],
                        onSelected: (v) => setState(() => _sortNewest = v),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: StatusFilterChips(
                      selected: _statusFilter,
                      onSelected: (v) => setState(() => _statusFilter = v),
                      pendingCount: pendingCount,
                      approvedCount: approvedCount,
                      rejectedCount: rejectedCount,
                    ),
                  ),
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: ArcticTheme.arcticTextSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _search.isNotEmpty
                                  ? l.noMatchingJobs
                                  : l.noJobsYet,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ArcticRefreshIndicator(
                        onRefresh: () async => refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final job = filtered[index];
                            return ContextMenuRegion(
                                  menuItems: [
                                    ContextMenuItem(
                                      id: 'copy_invoice',
                                      label: l.copyInvoice,
                                      icon: Icons.copy_rounded,
                                    ),
                                    ContextMenuItem(
                                      id: 'export_pdf',
                                      label: l.exportAsPdf,
                                      icon: Icons.picture_as_pdf_rounded,
                                    ),
                                  ],
                                  onSelected: (action) async {
                                    if (action == 'copy_invoice') {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: 'INV-${job.invoiceNumber}',
                                        ),
                                      );
                                      SuccessSnackbar.show(
                                        context,
                                        message: l.invoiceCopied,
                                      );
                                    } else if (action == 'export_pdf') {
                                      await PdfGenerator.previewPdf(context, [
                                        job,
                                      ], locale);
                                    }
                                  },
                                  child: _HistoryJobCard(job: job),
                                )
                                .animate(delay: (index * 80).ms)
                                .fadeIn()
                                .slideX(begin: 0.05);
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: ArcticShimmer(count: 5),
            ),
            error: (error, _) => error is AppException
                ? Center(child: ErrorCard(exception: error))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _HistoryJobCard extends StatelessWidget {
  const _HistoryJobCard({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.clientName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INV-${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status.name),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.ac_unit_rounded,
                label: AppFormatters.units(job.totalUnits),
              ),
              const SizedBox(width: 12),
              if (job.expenses > 0)
                Flexible(
                  child: _InfoChip(
                    icon: Icons.payments_outlined,
                    label: AppFormatters.currency(job.expenses),
                    color: ArcticTheme.arcticWarning,
                  ),
                ),
            ],
          ),
          if (job.isRejected && job.adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ArcticTheme.arcticError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: ArcticTheme.arcticError,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      job.adminNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticError,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? ArcticTheme.arcticTextSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c),
        ),
      ],
    );
  }
}
