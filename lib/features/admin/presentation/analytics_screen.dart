import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/services/pdf_generator.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isExporting = false;

  Future<void> _exportToPdf(List<JobModel> jobs) async {
    final locale = ref.read(appLocaleProvider);
    await PdfGenerator.previewPdf(context, jobs, locale);
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);

      final jobs = await ref
          .read(jobRepositoryProvider)
          .jobsForPeriod(start, end);

      if (jobs.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: AppLocalizations.of(context)!.noJobsForPeriod,
          );
        }
        return;
      }

      final excelFile = excel_pkg.Excel.createExcel();
      final sheet = excelFile['Jobs'];

      // Headers
      sheet.appendRow([
        excel_pkg.TextCellValue('Invoice'),
        excel_pkg.TextCellValue('Technician'),
        excel_pkg.TextCellValue('Client'),
        excel_pkg.TextCellValue('Date'),
        excel_pkg.TextCellValue('Units'),
        excel_pkg.TextCellValue('Expenses (SAR)'),
        excel_pkg.TextCellValue('Status'),
      ]);

      for (final job in jobs) {
        sheet.appendRow([
          excel_pkg.TextCellValue(job.invoiceNumber),
          excel_pkg.TextCellValue(job.techName),
          excel_pkg.TextCellValue(job.clientName),
          excel_pkg.TextCellValue(
            job.date != null
                ? '${job.date!.day}/${job.date!.month}/${job.date!.year}'
                : '',
          ),
          excel_pkg.IntCellValue(job.totalUnits),
          excel_pkg.DoubleCellValue(job.expenses),
          excel_pkg.TextCellValue(job.status.name),
        ]);
      }

      final bytes = excelFile.save();
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ac_techs_${now.month}_${now.year}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);

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

  @override
  Widget build(BuildContext context) {
    final allJobs = ref.watch(allJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.analytics),
        actions: [
          IconButton(
            onPressed: () {
              final jobs = ref.read(allJobsProvider).value;
              if (jobs != null && jobs.isNotEmpty) _exportToPdf(jobs);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: AppLocalizations.of(context)!.exportToPdf,
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
            tooltip: AppLocalizations.of(context)!.exportToExcel,
          ),
        ],
      ),
      body: SafeArea(
        child: allJobs.when(
          data: (jobs) {
            final approved = jobs.where((j) => j.isApproved).length;
            final pending = jobs.where((j) => j.isPending).length;
            final rejected = jobs.where((j) => j.isRejected).length;
            final totalExpenses = jobs.fold<double>(
              0,
              (s, j) => s + j.expenses,
            );

            // Jobs per technician
            final techJobs = <String, int>{};
            for (final job in jobs) {
              techJobs[job.techName] = (techJobs[job.techName] ?? 0) + 1;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                        value: '${jobs.length}',
                      ),
                      const Divider(height: 16),
                      _SummaryRow(
                        label: AppLocalizations.of(context)!.totalUnits,
                        value: AppFormatters.units(
                          jobs.fold<int>(0, (s, j) => s + j.totalUnits),
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
