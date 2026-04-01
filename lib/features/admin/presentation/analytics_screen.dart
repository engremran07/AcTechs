import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/excel_export.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isExporting = false;
  bool _isExportingTodayCompanyPdf = false;
  String _periodFilter = 'all';
  String _reportPreset = 'all';
  String _technicianFilter = 'all';
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

  List<JobModel> _applyPeriodFilter(List<JobModel> jobs) {
    final range = _activeRange();
    if (range == null) return jobs;
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
    return jobs.where((j) {
      final d = j.date;
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<JobModel> _applyTechnicianFilter(List<JobModel> jobs) {
    if (_technicianFilter == 'all') return jobs;
    return jobs.where((j) => j.techId == _technicianFilter).toList();
  }

  List<JobModel> _effectiveJobs(List<JobModel> jobs) {
    final periodScoped = _applyPeriodFilter(jobs);
    if (_reportPreset == 'byTech') {
      return _applyTechnicianFilter(periodScoped);
    }
    return periodScoped;
  }

  String _periodLabel(AppLocalizations l) {
    final range = _activeRange();
    if (range == null) return l.all;
    if (_periodFilter == 'today') return l.today;
    if (_periodFilter == 'month') return l.thisMonth;
    return '${AppFormatters.date(range.start)} - ${AppFormatters.date(range.end)}';
  }

  Future<void> _exportToPdf(List<JobModel> jobs) async {
    final locale = ref.read(appLocaleProvider);
    try {
      await PdfGenerator.previewPdf(context, jobs, locale);
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotExport,
        );
      }
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final scopedJobs = _applyTechnicianFilter(
        _applyPeriodFilter(ref.read(allJobsProvider).value ?? const []),
      );
      final jobs = scopedJobs;

      if (jobs.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: AppLocalizations.of(context)!.noJobsForPeriod,
          );
        }
        return;
      }

      await ExcelExport.exportJobsToExcel(jobs: jobs);

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.exportReady(jobs.length),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotExport,
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTodayCompanyInvoicesPdf(List<JobModel> jobs) async {
    setState(() => _isExportingTodayCompanyPdf = true);
    try {
      final l = AppLocalizations.of(context)!;
      final locale = ref.read(appLocaleProvider);
      final now = DateTime.now();

      if (jobs.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.noJobsForPeriod);
        }
        return;
      }

      final bytes = await PdfGenerator.generateTodayCompanyInvoicesReport(
        jobs: jobs,
        locale: locale,
      );

      await PdfGenerator.sharePdfBytes(
        bytes,
        'company_invoices_today_${now.year}_${now.month}_${now.day}.pdf',
      );
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotExport,
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingTodayCompanyPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = ref.watch(allJobsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.analytics),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.technicians,
            icon: const Icon(Icons.manage_accounts_outlined),
            onSelected: (value) {
              setState(() => _technicianFilter = value);
            },
            itemBuilder: (_) {
              final users = usersAsync.value ?? const <UserModel>[];
              final techs = users.where((u) => !u.isAdmin).toList();
              return [
                PopupMenuItem(value: 'all', child: Text(l.all)),
                ...techs.map(
                  (u) => PopupMenuItem(value: u.uid, child: Text(u.name)),
                ),
              ];
            },
          ),
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
              PopupMenuItem(value: 'custom', child: Text(l.selectPdfDateRange)),
            ],
          ),
          IconButton(
            onPressed: _isExportingTodayCompanyPdf
                ? null
                : () {
                    final jobs = ref.read(allJobsProvider).value;
                    if (jobs != null) {
                      _exportTodayCompanyInvoicesPdf(
                        _applyTechnicianFilter(_applyPeriodFilter(jobs)),
                      );
                    }
                  },
            icon: _isExportingTodayCompanyPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apartment_rounded),
            tooltip: l.exportTodayCompanyInvoices,
          ),
          IconButton(
            onPressed: () {
              final jobs = ref.read(allJobsProvider).value;
              if (jobs != null && jobs.isNotEmpty) {
                _exportToPdf(_applyTechnicianFilter(_applyPeriodFilter(jobs)));
              }
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l.exportToPdf,
          ),
          IconButton(
            onPressed: _isExporting ? null : _exportToExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: l.exportToExcel,
          ),
        ],
      ),
      body: SafeArea(
        child: allJobs.when(
          data: (jobs) {
            final scopedJobs = _effectiveJobs(jobs);
            final approved = scopedJobs.where((j) => j.isApproved).length;
            final pending = scopedJobs.where((j) => j.isPending).length;
            final rejected = scopedJobs.where((j) => j.isRejected).length;
            final totalExpenses = scopedJobs.fold<double>(
              0,
              (s, j) => s + j.expenses,
            );

            final uninstallOld = scopedJobs.fold<int>(
              0,
              (s, j) =>
                  s +
                  j.acUnits
                      .where((u) => u.type == 'Uninstallation (Old AC)')
                      .fold<int>(0, (x, u) => x + u.quantity),
            );
            final uninstallSplit = scopedJobs.fold<int>(
              0,
              (s, j) =>
                  s +
                  j.acUnits
                      .where((u) => u.type == 'Uninstallation Split')
                      .fold<int>(0, (x, u) => x + u.quantity),
            );
            final uninstallWindow = scopedJobs.fold<int>(
              0,
              (s, j) =>
                  s +
                  j.acUnits
                      .where((u) => u.type == 'Uninstallation Window')
                      .fold<int>(0, (x, u) => x + u.quantity),
            );
            final uninstallStanding = scopedJobs.fold<int>(
              0,
              (s, j) =>
                  s +
                  j.acUnits
                      .where((u) => u.type == 'Uninstallation Freestanding')
                      .fold<int>(0, (x, u) => x + u.quantity),
            );
            final uninstallTotal =
                uninstallOld +
                uninstallSplit +
                uninstallWindow +
                uninstallStanding;

            // Jobs per technician
            final techJobs = <String, int>{};
            for (final job in scopedJobs) {
              techJobs[job.techName] = (techJobs[job.techName] ?? 0) + 1;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.reportPreset,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'all',
                      label: Text(l.all),
                      icon: const Icon(Icons.dashboard_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'byTech',
                      label: Text(l.byTechnician),
                      icon: const Icon(Icons.manage_accounts_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'uninstall',
                      label: Text(l.uninstallRateBreakdown),
                      icon: const Icon(Icons.build_circle_outlined),
                    ),
                  ],
                  selected: {_reportPreset},
                  onSelectionChanged: (selection) {
                    setState(() => _reportPreset = selection.first);
                  },
                  showSelectedIcon: false,
                ),
                if (_reportPreset == 'byTech') ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l.technician}: ${_technicianFilter == 'all' ? l.all : (usersAsync.value?.firstWhere(
                                (u) => u.uid == _technicianFilter,
                                orElse: () => const UserModel(uid: '', name: '', email: ''),
                              ).name ?? l.all)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${l.date}: ${_periodLabel(l)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                  ),
                ),
                if (_reportPreset == 'uninstall') ...[
                  ArcticCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.uninstallRateBreakdown,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: l.uninstallSplit,
                          value:
                              '$uninstallSplit (${uninstallTotal == 0 ? 0 : ((uninstallSplit / uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstallWindow,
                          value:
                              '$uninstallWindow (${uninstallTotal == 0 ? 0 : ((uninstallWindow / uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstallStanding,
                          value:
                              '$uninstallStanding (${uninstallTotal == 0 ? 0 : ((uninstallStanding / uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.catUninstallOldAc,
                          value:
                              '$uninstallOld (${uninstallTotal == 0 ? 0 : ((uninstallOld / uninstallTotal) * 100).toStringAsFixed(1)}%)',
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: l.uninstalls,
                          value: '$uninstallTotal',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                ],
                // Status Pie Chart
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.jobStatus,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    PieChartSectionData(
                                      value: approved.toDouble(),
                                      color: ArcticTheme.arcticSuccess,
                                      title: '$approved',
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      radius: 50,
                                    ),
                                    PieChartSectionData(
                                      value: pending.toDouble(),
                                      color: ArcticTheme.arcticPending,
                                      title: '$pending',
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      radius: 50,
                                    ),
                                    PieChartSectionData(
                                      value: rejected.toDouble(),
                                      color: ArcticTheme.arcticError,
                                      title: '$rejected',
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      radius: 50,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Legend(
                                  color: ArcticTheme.arcticSuccess,
                                  label: AppLocalizations.of(context)!.approved,
                                ),
                                const SizedBox(height: 8),
                                _Legend(
                                  color: ArcticTheme.arcticPending,
                                  label: AppLocalizations.of(context)!.pending,
                                ),
                                const SizedBox(height: 8),
                                _Legend(
                                  color: ArcticTheme.arcticError,
                                  label: AppLocalizations.of(context)!.rejected,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Jobs per Technician Bar Chart
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.jobsPerTechnician,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            barGroups: techJobs.entries
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value.value.toDouble(),
                                        color: ArcticTheme.arcticBlue,
                                        width: 20,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final names = techJobs.keys.toList();
                                    if (value.toInt() < names.length) {
                                      final name = names[value.toInt()];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          name.length > 6
                                              ? '${name.substring(0, 6)}..'
                                              : name,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color:
                                                ArcticTheme.arcticTextSecondary,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),

                // Summary
                ArcticCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalJobs,
                        value: '${scopedJobs.length}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalUnits,
                        value: AppFormatters.units(
                          scopedJobs.fold<int>(0, (s, j) => s + j.totalUnits),
                        ),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalExpenses,
                        value: AppFormatters.currency(totalExpenses),
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.technicians,
                        value: '${techJobs.length}',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: ArcticShimmer(count: 3, height: 120),
          ),
          error: (error, _) => error is AppException
              ? Center(child: ErrorCard(exception: error))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: ArcticTheme.arcticBlue),
        ),
      ],
    );
  }
}
