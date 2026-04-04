import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({required this.jobId, this.initialJob, super.key});

  final String jobId;
  final JobModel? initialJob;

  int _displayUnits(JobModel job) {
    if (!job.isSharedInstall) return job.totalUnits;
    return job.sharedContributionUnits > 0
        ? job.sharedContributionUnits
        : job.totalUnits;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(technicianJobsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.jobHistory)),
      body: SafeArea(
        child: jobsAsync.when(
          data: (jobs) {
            final job = initialJob ?? _findJob(jobs, jobId);
            if (job == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.noMatchingJobs,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              job.clientName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusBadge(status: job.status.name),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: l.company,
                        value: job.companyName,
                      ),
                      _DetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: l.invoiceNumber,
                        value: job.invoiceNumber,
                      ),
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: l.clientName,
                        value: job.clientName,
                      ),
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: l.clientPhone,
                        value: job.clientContact,
                        trailing: job.clientContact.trim().isEmpty
                            ? null
                            : IconButton(
                                onPressed: () async {
                                  await WhatsAppLauncher.openChat(
                                    job.clientContact,
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: ArcticTheme.arcticSuccess,
                                  size: 16,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: l.date,
                        value: AppFormatters.date(job.date),
                      ),
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: l.technicianUidLabel,
                        value: job.techId,
                      ),
                      _DetailRow(
                        icon: Icons.calculate_outlined,
                        label: l.expenses,
                        value: AppFormatters.currency(job.expenses),
                      ),
                      if ((job.approvedBy ?? '').trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.verified_user_outlined,
                          label: l.approverUidLabel,
                          value: job.approvedBy!.trim(),
                        ),
                      if (job.expenseNote.trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.note_alt_outlined,
                          label: l.expenseNote,
                          value: job.expenseNote,
                        ),
                      if (job.adminNote.trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.info_outline_rounded,
                          label: l.adminNote,
                          value: job.adminNote,
                          valueColor: job.isRejected
                              ? ArcticTheme.arcticError
                              : ArcticTheme.arcticTextPrimary,
                        ),
                    ],
                  ),
                ),
                if (job.isSharedInstall) ...[
                  const SizedBox(height: 12),
                  ArcticCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.sharedInstall,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.tag_rounded,
                          label: l.sharedGroup,
                          value: job.sharedInstallGroupKey,
                        ),
                        _DetailRow(
                          icon: Icons.receipt_long_outlined,
                          label: l.totalOnInvoice,
                          value: AppFormatters.units(
                            job.sharedInvoiceTotalUnits,
                          ),
                        ),
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: l.myShare,
                          value: AppFormatters.units(_displayUnits(job)),
                        ),
                        if (job.sharedInvoiceUninstallSplitUnits > 0)
                          _DetailRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallSplit,
                            value:
                                '${job.techUninstallSplitShare}/${job.sharedInvoiceUninstallSplitUnits}',
                          ),
                        if (job.sharedInvoiceUninstallWindowUnits > 0)
                          _DetailRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallWindow,
                            value:
                                '${job.techUninstallWindowShare}/${job.sharedInvoiceUninstallWindowUnits}',
                          ),
                        if (job.sharedInvoiceUninstallFreestandingUnits > 0)
                          _DetailRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallStanding,
                            value:
                                '${job.techUninstallFreestandingShare}/${job.sharedInvoiceUninstallFreestandingUnits}',
                          ),
                        if (job.sharedInvoiceBracketCount > 0)
                          _DetailRow(
                            icon: Icons.hardware_outlined,
                            label: l.acOutdoorBracket,
                            value:
                                '${job.techBracketShare}/${job.sharedInvoiceBracketCount}',
                          ),
                        if (job.sharedDeliveryTeamCount > 0)
                          _DetailRow(
                            icon: Icons.groups_rounded,
                            label: l.sharedTeamSize,
                            value: '${job.sharedDeliveryTeamCount}',
                          ),
                        if (job.sharedInvoiceDeliveryAmount > 0)
                          _DetailRow(
                            icon: Icons.local_shipping_outlined,
                            label: l.sharedInvoiceDeliveryAmount,
                            value: AppFormatters.currency(
                              job.sharedInvoiceDeliveryAmount,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ArcticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.acUnits,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (job.acUnits.isEmpty)
                        Text('-', style: Theme.of(context).textTheme.bodyMedium)
                      else
                        ...job.acUnits.map(
                          (unit) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    unit.type,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  'x${unit.quantity}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const ArcticShimmer(count: 3),
          error: (error, _) => error is AppException
              ? ErrorCard(exception: error)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  JobModel? _findJob(List<JobModel> jobs, String id) {
    for (final job in jobs) {
      if (job.id == id) {
        return job;
      }
    }
    return null;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ArcticTheme.arcticTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: valueColor),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}
