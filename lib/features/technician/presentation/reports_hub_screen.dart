import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/services/excel_export.dart';
import 'package:ac_techs/core/services/pdf_export_service.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/services/report_branding.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class ReportsHubScreen extends ConsumerStatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  ConsumerState<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends ConsumerState<ReportsHubScreen> {
  bool _isGenerating = false;
  String? _activeReport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reports),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => ZoomDrawerScope.of(context).toggle(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Header ──
            Text(
              l.reportsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),

            // ── Daily In/Out ──
            _ReportCard(
              icon: Icons.today_rounded,
              color: ArcticTheme.arcticSuccess,
              title: l.dailyInOutReport,
              subtitle: l.dailyInOutReportDesc,
              isLoading: _activeReport == 'dailyInOut',
              isExcelLoading: _activeReport == 'dailyInOut_excel',
              onTap: _isGenerating ? null : () => _generateDailyInOut(l),
              onExcelTap: _isGenerating
                  ? null
                  : () => _exportDailyInOutToExcel(l),
            ),

            // ── Monthly In/Out ──
            _ReportCard(
              icon: Icons.calendar_month_rounded,
              color: ArcticTheme.arcticBlue,
              title: l.monthlyInOutReport,
              subtitle: l.monthlyInOutReportDesc,
              isLoading: _activeReport == 'monthlyInOut',
              isExcelLoading: _activeReport == 'monthlyInOut_excel',
              onTap: _isGenerating ? null : () => _generateMonthlyInOut(l),
              onExcelTap: _isGenerating
                  ? null
                  : () => _exportMonthlyInOutToExcel(l),
            ),

            // ── AC Installs ──
            _ReportCard(
              icon: Icons.ac_unit_rounded,
              color: ArcticTheme.arcticPurple,
              title: l.acInstallsReport,
              subtitle: l.acInstallsReportDesc,
              isLoading: _activeReport == 'acInstalls',
              isExcelLoading: _activeReport == 'acInstalls_excel',
              onTap: _isGenerating ? null : () => _generateAcInstalls(l),
              onExcelTap: _isGenerating
                  ? null
                  : () => _exportAcInstallsToExcel(l),
            ),

            // ── Jobs Report ──
            _ReportCard(
              icon: Icons.work_rounded,
              color: ArcticTheme.arcticWarning,
              title: l.jobsReport,
              subtitle: l.jobsReportDesc,
              isLoading: _activeReport == 'jobs',
              isExcelLoading: _activeReport == 'jobs_excel',
              onTap: _isGenerating ? null : () => _generateJobsReport(l),
              onExcelTap: _isGenerating ? null : () => _exportJobsToExcel(l),
            ),

            // ── Shared Install ──
            _ReportCard(
              icon: Icons.group_work_rounded,
              color: ArcticTheme.arcticBlueDark,
              title: l.sharedInstallReport,
              subtitle: l.sharedInstallReportDesc,
              isLoading: _activeReport == 'sharedInstall',
              isExcelLoading: _activeReport == 'sharedInstall_excel',
              onTap: _isGenerating ? null : () => _generateSharedInstalls(l),
              onExcelTap: _isGenerating
                  ? null
                  : () => _exportSharedInstallsToExcel(l),
            ),

            // ── Payment Settlement ──
            _ReportCard(
              icon: Icons.payments_rounded,
              color: ArcticTheme.arcticSuccess,
              title: l.paymentSettlementReport,
              subtitle: l.paymentSettlementReportDesc,
              isLoading: _activeReport == 'settlement',
              isExcelLoading: _activeReport == 'settlement_excel',
              onTap: _isGenerating ? null : () => _generateSettlementReport(l),
              onExcelTap: _isGenerating
                  ? null
                  : () => _exportSettlementToExcel(l),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Report generation helpers ──────────────────────────────────────────

  ReportBrandingContext? _buildBranding() {
    final appBranding =
        ref.read(appBrandingProvider).value ?? AppBrandingConfig.defaults();
    return ReportBrandingContext.fromAppBranding(
      appBranding: appBranding,
      fallbackServiceName: 'AC Techs',
    );
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  String get _techName =>
      ref.read(currentUserProvider).value?.name ?? 'Technician';

  String get _techUid => ref.read(currentUserProvider).value!.uid;

  Future<void> _generateDailyInOut(AppLocalizations l) async {
    _setActive('dailyInOut');
    try {
      final today = DateTime.now();
      final month = DateTime(today.year, today.month);
      final uid = _techUid;
      final earningRepo = ref.read(earningRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final earnings = await earningRepo.fetchMonthlyEarnings(uid, month);
      final expenses = await expenseRepo.fetchMonthlyExpenses(uid, month);

      final todayEarnings = earnings
          .where((e) => _isSameDay(e.date, today))
          .toList();
      final todayExpenses = expenses
          .where((e) => _isSameDay(e.date, today))
          .toList();

      if (todayEarnings.isEmpty && todayExpenses.isEmpty) {
        _showEmpty(l);
        return;
      }

      await PdfExportService.shareInOutReport(
        earnings: todayEarnings,
        expenses: todayExpenses,
        fileName:
            'daily_inout_${AppFormatters.date(today).replaceAll('/', '-')}.pdf',
        locale: _locale,
        technicianName: _techName,
        reportTitle: l.dailyInOutReport,
        reportDate: today,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateMonthlyInOut(AppLocalizations l) async {
    final picked = await _pickMonth();
    if (picked == null) return;

    _setActive('monthlyInOut');
    try {
      final month = DateTime(picked.year, picked.month);
      final uid = _techUid;
      final earningRepo = ref.read(earningRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final earnings = await earningRepo.fetchMonthlyEarnings(uid, month);
      final expenses = await expenseRepo.fetchMonthlyExpenses(uid, month);

      if (earnings.isEmpty && expenses.isEmpty) {
        _showEmpty(l);
        return;
      }

      await PdfExportService.shareInOutReport(
        earnings: earnings,
        expenses: expenses,
        fileName:
            'monthly_inout_${picked.year}_${picked.month.toString().padLeft(2, '0')}.pdf',
        locale: _locale,
        technicianName: _techName,
        reportTitle: l.monthlyInOutReport,
        reportDate: month,
        monthlyMode: true,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateAcInstalls(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('acInstalls');
    try {
      final start = range.start;
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final filtered = await jobRepo.fetchTechJobsForPeriod(uid, start, end);

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: filtered,
        title: l.acInstallsReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'ac_installs_${AppFormatters.date(range.start).replaceAll('/', '-')}_${AppFormatters.date(range.end).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateJobsReport(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('jobs');
    try {
      final start = range.start;
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final filtered = await jobRepo.fetchTechJobsForPeriod(uid, start, end);

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: filtered,
        title: l.jobsReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'jobs_report_${AppFormatters.date(range.start).replaceAll('/', '-')}_${AppFormatters.date(range.end).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateSharedInstalls(AppLocalizations l) async {
    _setActive('sharedInstall');
    try {
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final allJobs = await jobRepo.fetchAllTechJobs(uid);
      final shared = allJobs.where((j) => j.isSharedInstall).toList();

      if (shared.isEmpty) {
        _showEmpty(l);
        return;
      }

      final sharedNames = await ref.read(
        sharedInstallerNamesProvider(
          SharedInstallerNamesQuery.fromJobs(shared),
        ).future,
      );

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: shared,
        title: l.sharedInstallReport,
        locale: _locale,
        sharedInstallerNamesByGroup: sharedNames,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'shared_installs_${AppFormatters.date(DateTime.now()).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _generateSettlementReport(AppLocalizations l) async {
    _setActive('settlement');
    try {
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final allJobs = await jobRepo.fetchAllTechJobs(uid);
      final settled = allJobs
          .where((j) => j.settlementStatus != JobSettlementStatus.unpaid)
          .toList();

      if (settled.isEmpty) {
        _showEmpty(l);
        return;
      }

      final bytes = await PdfGenerator.generateJobsDetailsReport(
        jobs: settled,
        title: l.paymentSettlementReport,
        locale: _locale,
        reportBranding: _buildBranding(),
      );
      await PdfGenerator.sharePdfBytes(
        bytes,
        'settlement_report_${AppFormatters.date(DateTime.now()).replaceAll('/', '-')}.pdf',
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  // ── Excel export handlers ──────────────────────────────────────────────

  Future<void> _exportDailyInOutToExcel(AppLocalizations l) async {
    _setActive('dailyInOut_excel');
    try {
      final today = DateTime.now();
      final month = DateTime(today.year, today.month);
      final uid = _techUid;
      final earningRepo = ref.read(earningRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final earnings = await earningRepo.fetchMonthlyEarnings(uid, month);
      final expenses = await expenseRepo.fetchMonthlyExpenses(uid, month);
      final todayEarnings = earnings
          .where((e) => _isSameDay(e.date, today))
          .toList();
      final todayExpenses = expenses
          .where((e) => _isSameDay(e.date, today))
          .toList();

      if (todayEarnings.isEmpty && todayExpenses.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportInOutToExcel(
        earnings: todayEarnings,
        expenses: todayExpenses,
        reportDate: today,
        dailyMode: true,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _exportMonthlyInOutToExcel(AppLocalizations l) async {
    final picked = await _pickMonth();
    if (picked == null) return;

    _setActive('monthlyInOut_excel');
    try {
      final month = DateTime(picked.year, picked.month);
      final uid = _techUid;
      final earningRepo = ref.read(earningRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final earnings = await earningRepo.fetchMonthlyEarnings(uid, month);
      final expenses = await expenseRepo.fetchMonthlyExpenses(uid, month);

      if (earnings.isEmpty && expenses.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportInOutToExcel(
        earnings: earnings,
        expenses: expenses,
        reportDate: month,
        dailyMode: false,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _exportAcInstallsToExcel(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('acInstalls_excel');
    try {
      final start = range.start;
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final filtered = await jobRepo.fetchTechJobsForPeriod(uid, start, end);

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportJobsToExcel(
        jobs: filtered,
        technicianName: _techName,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _exportJobsToExcel(AppLocalizations l) async {
    final range = await _pickDateRange();
    if (range == null) return;

    _setActive('jobs_excel');
    try {
      final start = range.start;
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final filtered = await jobRepo.fetchTechJobsForPeriod(uid, start, end);

      if (filtered.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportJobsToExcel(
        jobs: filtered,
        technicianName: _techName,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _exportSharedInstallsToExcel(AppLocalizations l) async {
    _setActive('sharedInstall_excel');
    try {
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final allJobs = await jobRepo.fetchAllTechJobs(uid);
      final shared = allJobs.where((j) => j.isSharedInstall).toList();

      if (shared.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportJobsToExcel(
        jobs: shared,
        technicianName: _techName,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  Future<void> _exportSettlementToExcel(AppLocalizations l) async {
    _setActive('settlement_excel');
    try {
      final uid = _techUid;
      final jobRepo = ref.read(jobRepositoryProvider);
      final allJobs = await jobRepo.fetchAllTechJobs(uid);
      final settled = allJobs
          .where((j) => j.settlementStatus != JobSettlementStatus.unpaid)
          .toList();

      if (settled.isEmpty) {
        _showEmpty(l);
        return;
      }
      await ExcelExport.exportSettlementToExcel(
        jobs: settled,
        reportBranding: _buildBranding(),
      );
    } catch (e) {
      _reportError(e);
    } finally {
      _clearActive();
    }
  }

  // ── Pickers ────────────────────────────────────────────────────────────

  Future<DateTime?> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.selectMonth,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    return picked;
  }

  Future<DateTimeRange?> _pickDateRange() async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: AppLocalizations.of(context)!.selectDateRange,
    );
  }

  // ── State helpers ──────────────────────────────────────────────────────

  void _setActive(String key) {
    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _activeReport = key;
    });
    HapticFeedback.mediumImpact();
  }

  void _clearActive() {
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _activeReport = null;
    });
  }

  void _showEmpty(AppLocalizations l) {
    if (mounted) AppFeedback.info(context, message: l.noDataForPeriod);
    _clearActive();
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _reportError(Object e) {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    AppFeedback.error(
      context,
      message: e is AppException ? e.message(l.localeName) : l.genericError,
    );
  }
}

// ── Reusable report card widget ──────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onExcelTap,
    this.isLoading = false,
    this.isExcelLoading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onExcelTap;
  final bool isLoading;
  final bool isExcelLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasExcel = onExcelTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row (non-tappable when Excel buttons are shown) ──
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, hasExcel ? 8 : 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasExcel)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),

            // ── Export action buttons (shown when Excel is available) ──
            if (hasExcel) ...[
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _ExportActionButton(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'PDF',
                        color: color,
                        isLoading: isLoading,
                        onTap: onTap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ExportActionButton(
                        icon: Icons.table_chart_rounded,
                        label: 'Excel',
                        color: ArcticTheme.arcticSuccess,
                        isLoading: isExcelLoading,
                        onTap: onExcelTap,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              // Full-card tap area when no Excel button is shown
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Compact export action button ─────────────────────────────────────────

class _ExportActionButton extends StatelessWidget {
  const _ExportActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: isLoading
          ? SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 15, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
