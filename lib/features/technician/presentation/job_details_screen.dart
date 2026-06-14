import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/core/utils/secure_screen.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  const JobDetailsScreen({required this.jobId, this.initialJob, super.key});

  final String jobId;
  final JobModel? initialJob;

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  Future<List<String>> _sharedTechnicianNames(JobModel job) async {
    if (!job.isSharedInstall || job.sharedInstallGroupKey.trim().isEmpty) {
      return const <String>[];
    }

    try {
      final namesByGroup = await ref.read(
        sharedInstallerNamesProvider(
          SharedInstallerNamesQuery.fromKeys([job.sharedInstallGroupKey]),
        ).future,
      );
      return (namesByGroup[job.sharedInstallGroupKey] ?? const <String>[])
          .where((name) => name.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final jobsAsync = ref.watch(technicianJobsProvider);
    final approvalConfig = ref.watch(approvalConfigProvider).value;
    final currentUser = ref.watch(currentUserProvider).value;
    final activeCompanies =
        ref.watch(activeCompaniesProvider).value ?? const <CompanyModel>[];
    final resolvedJob = jobsAsync.maybeWhen(
      data: (jobs) => widget.initialJob ?? _findJob(jobs, widget.jobId),
      orElse: () => widget.initialJob,
    );
    final title = (resolvedJob?.invoiceNumber.trim().isNotEmpty ?? false)
        ? resolvedJob!.invoiceNumber.trim()
        : l.jobDetails;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(title)),
      body: SafeArea(
        child: jobsAsync.when(
          data: (jobs) {
            final job = widget.initialJob ?? _findJob(jobs, widget.jobId);
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
                      if (job.canTechnicianEdit(
                        approvalRequired:
                            approvalConfig?.jobApprovalRequired ?? true,
                        sharedApprovalRequired:
                            approvalConfig?.sharedJobApprovalRequired ?? true,
                      )) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/tech/submit', extra: job),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l.save),
                          ),
                        ),
                      ],
                      if (job.isApproved &&
                          job.isUnpaid &&
                          !job.isSharedInstall &&
                          job.editRequestedAt == null &&
                          (approvalConfig?.jobApprovalRequired ?? true)) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dlg) => AlertDialog(
                                  title: Text(l.requestEditConfirmTitle),
                                  content: Text(l.requestEditConfirmBody),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dlg).pop(false),
                                      child: Text(l.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dlg).pop(true),
                                      child: Text(l.confirm),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              if (!context.mounted) return;
                              try {
                                await ref
                                    .read(jobRepositoryProvider)
                                    .resubmitForApproval(job.id);
                                if (!context.mounted) return;
                                AppFeedback.success(
                                  context,
                                  message: l.jobEditRequested,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                AppFeedback.error(
                                  context,
                                  message: l.genericError,
                                );
                              }
                            },
                            icon: const Icon(Icons.edit_off_outlined),
                            label: Text(l.requestEditJob),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ArcticTheme.arcticPending,
                              side: const BorderSide(
                                color: ArcticTheme.arcticPending,
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Admin edit button: admin can correct approved+unpaid jobs
                      if ((currentUser?.isAdmin ?? false) &&
                          job.isApproved &&
                          job.isUnpaid) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/admin/submit', extra: job),
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: Text(l.adminEditJob),
                          ),
                        ),
                      ],
                      // Admin-edited badge
                      if (job.adminEditedAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note_outlined,
                              size: 14,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.adminEditedBadge,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      // Transferred badge
                      if (job.transferredFromTechId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l.transferredFrom(
                                  job.transferredFromTechName.isNotEmpty
                                      ? job.transferredFromTechName
                                      : job.transferredFromTechId,
                                ),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: ArcticTheme.arcticTextSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (job.transferredAt != null) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 18,
                            ),
                            child: Text(
                              AppFormatters.date(job.transferredAt!),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ],
                      // ── Tech transfer request UI ────────────────────────
                      if ((approvalConfig?.techTransferAllowed ?? false) &&
                          !job.isSettlementLocked &&
                          job.isPending &&
                          // UX-002: hide when job is in a locked period
                          !(approvalConfig?.locksDate(
                                job.date ?? DateTime.now(),
                              ) ??
                              false)) ...[
                        const SizedBox(height: 12),
                        if (job.isTransferPending) ...[
                          // Show pending badge + cancel button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: ArcticTheme.arcticWarning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l.transferPendingBadge,
                                  style: const TextStyle(
                                    color: ArcticTheme.arcticWarning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.transferTargetTechName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dlg) => AlertDialog(
                                    title: Text(l.cancelTransferRequest),
                                    content: Text(l.cancelTransferConfirm),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dlg).pop(false),
                                        child: Text(l.cancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(dlg).pop(true),
                                        child: Text(l.confirm),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                if (!context.mounted) return;
                                try {
                                  await ref
                                      .read(jobRepositoryProvider)
                                      .cancelJobTransferRequest(job.id);
                                  if (!context.mounted) return;
                                  AppFeedback.success(
                                    context,
                                    message: l.transferRequestCancelled,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  AppFeedback.error(
                                    context,
                                    message: l.genericError,
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: Text(l.cancelTransferRequest),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ArcticTheme.arcticWarning,
                                side: const BorderSide(
                                  color: ArcticTheme.arcticWarning,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Request transfer button
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRequestTransferDialog(
                                context,
                                ref,
                                job,
                                approvalConfig,
                              ),
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: Text(
                                (approvalConfig?.techTransferRequiresApproval ??
                                        true)
                                    ? l.requestTransfer
                                    : l.transferJob,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: l.company,
                        value: job.companyName,
                      ),
                      if (job.companyId.trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: l.invoicePeriod,
                          value: (() {
                            final company = activeCompanies
                                .where((c) => c.id == job.companyId.trim())
                                .toList();
                            if (company.isEmpty || job.date == null) {
                              return '-';
                            }
                            final period = company.first.invoicePeriodForDate(
                              job.date!,
                            );
                            return '${AppFormatters.date(period.start)} - ${AppFormatters.date(period.end)}';
                          })(),
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
                                onPressed: () => WhatsAppLauncher.showChooser(
                                  context,
                                  job.clientContact,
                                ),
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
                        icon: Icons.person_outline_rounded,
                        label: l.technician,
                        value: job.techName,
                      ),
                      // Expenses belong to the daily In/Out system — not displayed here.
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
                        FutureBuilder<List<String>>(
                          future: _sharedTechnicianNames(job),
                          builder: (context, snapshot) {
                            final names = snapshot.data ?? const <String>[];
                            if (names.isEmpty) return const SizedBox.shrink();
                            return _DetailRow(
                              icon: Icons.groups_rounded,
                              label: l.technicians,
                              value: names.join(', '),
                            );
                          },
                        ),
                        const Divider(height: 16),
                        // ── Per-type breakdown: Invoice total vs. tech share ──
                        if (job.sharedInvoiceSplitUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.ac_unit_rounded,
                            label: l.splitAcLabel,
                            invoiceValue: '${job.sharedInvoiceSplitUnits}',
                            myShareValue: '${job.techSplitShare}',
                          ),
                        if (job.sharedInvoiceWindowUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.window_outlined,
                            label: l.windowAcLabel,
                            invoiceValue: '${job.sharedInvoiceWindowUnits}',
                            myShareValue: '${job.techWindowShare}',
                          ),
                        if (job.sharedInvoiceFreestandingUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.vertical_align_bottom_rounded,
                            label: l.freestandingAcLabel,
                            invoiceValue:
                                '${job.sharedInvoiceFreestandingUnits}',
                            myShareValue: '${job.techFreestandingShare}',
                          ),
                        if (job.sharedInvoiceBracketCount > 0)
                          _SharedTypeRow(
                            icon: Icons.hardware_outlined,
                            label: l.acOutdoorBracket,
                            invoiceValue: '${job.sharedInvoiceBracketCount}',
                            myShareValue: '${job.techBracketShare}',
                          ),
                        if (job.sharedInvoiceUninstallSplitUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallSplit,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallSplitUnits}',
                            myShareValue: '${job.techUninstallSplitShare}',
                          ),
                        if (job.sharedInvoiceUninstallWindowUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallWindow,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallWindowUnits}',
                            myShareValue: '${job.techUninstallWindowShare}',
                          ),
                        if (job.sharedInvoiceUninstallFreestandingUnits > 0)
                          _SharedTypeRow(
                            icon: Icons.build_circle_outlined,
                            label: l.uninstallStanding,
                            invoiceValue:
                                '${job.sharedInvoiceUninstallFreestandingUnits}',
                            myShareValue:
                                '${job.techUninstallFreestandingShare}',
                          ),
                        if (job.sharedInvoiceDeliveryAmount > 0) ...[
                          const Divider(height: 16),
                          _SharedTypeRow(
                            icon: Icons.local_shipping_outlined,
                            label: l.sharedInvoiceDeliveryAmount,
                            invoiceValue: AppFormatters.currency(
                              job.sharedInvoiceDeliveryAmount,
                            ),
                            myShareValue: AppFormatters.currency(
                              job.charges?.deliveryAmount ??
                                  (job.sharedDeliveryTeamCount > 0
                                      ? job.sharedInvoiceDeliveryAmount /
                                            job.sharedDeliveryTeamCount
                                      : 0),
                            ),
                          ),
                        ],
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

  Future<void> _showRequestTransferDialog(
    BuildContext context,
    WidgetRef ref,
    JobModel job,
    ApprovalConfig? approvalConfig,
  ) async {
    final l = AppLocalizations.of(context)!;
    final techs = ref.read(activeTechniciansForTeamProvider).value ?? const [];
    final available = techs
        .where((t) => t.isActive && t.uid != job.techId)
        .toList();

    if (available.isEmpty) {
      AppFeedback.error(context, message: l.noActiveTechnicians);
      return;
    }

    UserModel? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlg) => StatefulBuilder(
        builder: (dlg, setS) => AlertDialog(
          title: Text(
            (approvalConfig?.techTransferRequiresApproval ?? true)
                ? l.requestTransfer
                : l.transferJob,
          ),
          content: DropdownButton<UserModel>(
            isExpanded: true,
            value: selected,
            hint: Text(l.transferToTechnician),
            items: available
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setS(() => selected = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlg).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(dlg).pop(true),
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selected == null) return;
    if (!context.mounted) return;

    try {
      final repo = ref.read(jobRepositoryProvider);
      if (approvalConfig?.techTransferRequiresApproval ?? true) {
        await repo.requestJobTransfer(
          jobId: job.id,
          targetTechId: selected!.uid,
          targetTechName: selected!.name,
        );
        if (!context.mounted) return;
        AppFeedback.success(context, message: l.transferRequestSent);
      } else {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;
        await repo.transferJobAsTech(
          jobId: job.id,
          newTechId: selected!.uid,
          newTechName: selected!.name,
          techId: currentUser.uid,
        );
        if (!context.mounted) return;
        AppFeedback.success(context, message: l.jobTransferred);
      }
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.error(context, message: l.genericError);
    }
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

/// Two-column breakdown row for shared install types.
/// Shows [Invoice total] on the left and [Your share] highlighted on the right.
class _SharedTypeRow extends StatelessWidget {
  const _SharedTypeRow({
    required this.icon,
    required this.label,
    required this.invoiceValue,
    required this.myShareValue,
  });

  final IconData icon;
  final String label;
  final String invoiceValue;
  final String myShareValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
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
                  style: textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.invoice,
                            style: textTheme.labelSmall?.copyWith(
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                          ),
                          Text(invoiceValue, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.yourShare,
                            style: textTheme.labelSmall?.copyWith(
                              color: ArcticTheme.arcticBlue,
                            ),
                          ),
                          Text(
                            myShareValue,
                            style: textTheme.bodyMedium?.copyWith(
                              color: ArcticTheme.arcticBlue,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
