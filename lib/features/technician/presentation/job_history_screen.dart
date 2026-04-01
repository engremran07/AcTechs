import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/excel_export.dart';
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
  bool _isExportingExcel = false;
  String _periodFilter = 'all';
  DateTimeRange? _customDateRange;

  Future<void> _pickCustomDateRange() async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: now,
      initialDateRange: _customDateRange,
      helpText: l.selectPdfDateRange,
    );
    if (picked == null) return;
    setState(() {
      _periodFilter = 'custom';
      _customDateRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
  }

  DateTimeRange? _activeRange() {
    final now = DateTime.now();
    if (_periodFilter == 'today') {
      final start = DateTime(now.year, now.month, now.day);
      return DateTimeRange(start: start, end: start);
    }
    if (_periodFilter == 'month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return DateTimeRange(start: start, end: end);
    }
    if (_periodFilter == 'custom') {
      return _customDateRange;
    }
    return null;
  }

  String _periodLabel(AppLocalizations l) {
    final range = _activeRange();
    if (range == null) return l.all;
    if (_periodFilter == 'today') return l.today;
    if (_periodFilter == 'month') return l.thisMonth;
    return '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}';
  }

  List<JobModel> _applyFilters(List<JobModel> jobs) {
    var filtered = jobs.toList();

    final range = _activeRange();
    if (range != null) {
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((j) {
        final d = j.date;
        if (d == null) return false;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }

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
            PopupMenuButton<String>(
              tooltip: l.selectDate,
              icon: const Icon(Icons.date_range_rounded),
              onSelected: (value) async {
                if (value == 'custom') {
                  await _pickCustomDateRange();
                  return;
                }
                setState(() {
                  _periodFilter = value;
                  if (value != 'custom') {
                    _customDateRange = null;
                  }
                });
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'all', child: Text(l.all)),
                PopupMenuItem(value: 'today', child: Text(l.today)),
                PopupMenuItem(value: 'month', child: Text(l.thisMonth)),
                PopupMenuItem(
                  value: 'custom',
                  child: Text(l.selectPdfDateRange),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l.exportPdf,
              onPressed: () async {
                final jobList = jobs.value;
                if (jobList == null || jobList.isEmpty) return;
                final filtered = _applyFilters(jobList);
                try {
                  await PdfGenerator.previewPdf(context, filtered, locale);
                } catch (_) {
                  if (!context.mounted) return;
                  ErrorSnackbar.show(context, message: l.couldNotExport);
                }
              },
            ),
            IconButton(
              icon: _isExportingExcel
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined),
              tooltip: l.exportToExcel,
              onPressed: _isExportingExcel
                  ? null
                  : () async {
                      final jobList = jobs.value;
                      if (jobList == null || jobList.isEmpty) return;
                      final filtered = _applyFilters(jobList);
                      setState(() => _isExportingExcel = true);
                      try {
                        await ExcelExport.exportJobsToExcel(jobs: filtered);
                      } finally {
                        if (mounted) {
                          setState(() => _isExportingExcel = false);
                        }
                      }
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${l.date}: ${_periodLabel(l)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                                          text: job.invoiceNumber,
                                        ),
                                      );
                                      SuccessSnackbar.show(
                                        context,
                                        message: l.invoiceCopied,
                                      );
                                    } else if (action == 'export_pdf') {
                                      try {
                                        await PdfGenerator.previewPdf(context, [
                                          job,
                                        ], locale);
                                      } catch (_) {
                                        if (context.mounted) {
                                          ErrorSnackbar.show(
                                            context,
                                            message: l.couldNotExport,
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: _HistoryJobCard(
                                    job: job,
                                    onTap: () => context.push(
                                      '/tech/job/${job.id}',
                                      extra: job,
                                    ),
                                  ),
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
  const _HistoryJobCard({required this.job, required this.onTap});

  final JobModel job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ArcticCard(
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
                      '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
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
          if (job.clientContact.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 15,
                  color: ArcticTheme.arcticTextSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.clientContact,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await WhatsAppLauncher.openChat(job.clientContact);
                  },
                  icon: const Icon(
                    FontAwesomeIcons.whatsapp,
                    color: ArcticTheme.arcticSuccess,
                    size: 16,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 28,
                    minWidth: 28,
                  ),
                ),
              ],
            ),
          ],
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
        ),
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
