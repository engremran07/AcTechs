import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';
import 'package:ac_techs/features/expenses/providers/ac_install_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';

class AcInstallationsScreen extends ConsumerStatefulWidget {
  const AcInstallationsScreen({super.key});

  @override
  ConsumerState<AcInstallationsScreen> createState() =>
      _AcInstallationsScreenState();
}

class _AcInstallationsScreenState extends ConsumerState<AcInstallationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final installsAsync = ref.watch(todaysAcInstallsProvider);
    final todaysJobsAsync = ref.watch(todaysJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.acInstallations),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: ArcticTheme.arcticBlue,
            tooltip: l.logAcInstallations,
            onPressed: _showAddInstallDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInstallSourceCard(theme, todaysJobsAsync, installsAsync),
            const SizedBox(height: 16),
            _buildAcInstallSection(theme, installsAsync),
          ],
        ),
      ),
    );
  }

  int _countUnits(List<JobModel> jobs, String type) {
    return jobs.fold<int>(
      0,
      (sum, job) =>
          sum +
          job.acUnits
              .where((unit) => unit.type == type)
              .fold<int>(0, (unitSum, unit) => unitSum + unit.quantity),
    );
  }

  Widget _buildInstallSourceCard(
    ThemeData theme,
    AsyncValue<List<JobModel>> todaysJobsAsync,
    AsyncValue<List<AcInstallModel>> installsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final jobs = todaysJobsAsync.value ?? const <JobModel>[];
    final manualLogs = installsAsync.value ?? const <AcInstallModel>[];
    final splitCount = _countUnits(jobs, 'Split AC');
    final windowCount = _countUnits(jobs, 'Window AC');
    final freestandingCount = _countUnits(jobs, 'Freestanding AC');
    final cassetteCount = _countUnits(jobs, 'Cassette AC');

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.jobInstallationsToday, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            l.manualInstallLogDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: ArcticTheme.arcticTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InstallSummaryChip(label: l.splitAcLabel, value: splitCount),
              _InstallSummaryChip(label: l.windowAcLabel, value: windowCount),
              _InstallSummaryChip(
                label: l.freestandingAcLabel,
                value: freestandingCount,
              ),
              _InstallSummaryChip(label: l.cassette, value: cassetteCount),
              _InstallSummaryChip(
                label: l.manualLogsToday,
                value: manualLogs.length,
                color: ArcticTheme.arcticSuccess,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  // ── AC Installations Section ──

  Widget _buildAcInstallSection(
    ThemeData theme,
    AsyncValue<List<AcInstallModel>> installsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final installs = installsAsync.value ?? const <AcInstallModel>[];

    if (installsAsync.isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    if (installs.isEmpty) {
      return ArcticCard(
        child: Column(
          children: [
            const Icon(
              Icons.air_outlined,
              size: 56,
              color: ArcticTheme.arcticTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              l.noManualInstallLogsToday,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.logAcInstallations, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(
          installs.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == installs.length - 1 ? 0 : 12,
            ),
            child: _buildInstallCard(theme, installs[index], l),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInstallCard(
    ThemeData theme,
    AcInstallModel install,
    AppLocalizations l,
  ) {
    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  install.date != null ? AppFormatters.date(install.date!) : '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ),
              StatusBadge(status: install.status.name),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstallTypeRow(
            theme,
            label: l.splitAcLabel,
            total: install.splitTotal,
            share: install.splitShare,
            l: l,
          ),
          if (install.windowTotal > 0 || install.windowShare > 0) ...[
            const SizedBox(height: 4),
            _buildInstallTypeRow(
              theme,
              label: l.windowAcLabel,
              total: install.windowTotal,
              share: install.windowShare,
              l: l,
            ),
          ],
          if (install.freestandingTotal > 0 ||
              install.freestandingShare > 0) ...[
            const SizedBox(height: 4),
            _buildInstallTypeRow(
              theme,
              label: l.freestandingAcLabel,
              total: install.freestandingTotal,
              share: install.freestandingShare,
              l: l,
            ),
          ],
          if (install.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              install.note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
          if (install.adminNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              install.adminNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: ArcticTheme.arcticWarning,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildInstallTypeRow(
    ThemeData theme, {
    required String label,
    required int total,
    required int share,
    required AppLocalizations l,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Text(
          l.invoiceUnitsLabel(total),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ArcticTheme.arcticTextSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l.myShareUnitsLabel(share),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ArcticTheme.arcticBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInstallTypeInputRow({
    required String label,
    required TextEditingController totalCtrl,
    required TextEditingController shareCtrl,
    required String totalHint,
    required String shareHint,
    required AppLocalizations l,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: totalHint, isDense: true),
                validator: (v) {
                  final share = int.tryParse(shareCtrl.text.trim()) ?? 0;
                  final total = int.tryParse(v?.trim() ?? '') ?? 0;
                  if (total < 0) return l.enterValidAmount;
                  if (share > total && total > 0) {
                    return l.shareMustNotExceedTotal;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: shareCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(hintText: shareHint, isDense: true),
                validator: (v) {
                  final share = int.tryParse(v?.trim() ?? '') ?? 0;
                  final total = int.tryParse(totalCtrl.text.trim()) ?? 0;
                  if (share < 0) return l.enterValidAmount;
                  if (total > 0 && share > total) {
                    return l.shareMustNotExceedTotal;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddInstallDialog() async {
    final l = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    final splitTotalCtrl = TextEditingController();
    final splitShareCtrl = TextEditingController();
    final windowTotalCtrl = TextEditingController();
    final windowShareCtrl = TextEditingController();
    final freestandingTotalCtrl = TextEditingController();
    final freestandingShareCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logAcInstallations),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstallTypeInputRow(
                  label: l.splitAcLabel,
                  totalCtrl: splitTotalCtrl,
                  shareCtrl: splitShareCtrl,
                  totalHint: l.totalOnInvoice,
                  shareHint: l.myShare,
                  l: l,
                ),
                const SizedBox(height: 12),
                _buildInstallTypeInputRow(
                  label: l.windowAcLabel,
                  totalCtrl: windowTotalCtrl,
                  shareCtrl: windowShareCtrl,
                  totalHint: l.totalOnInvoice,
                  shareHint: l.myShare,
                  l: l,
                ),
                const SizedBox(height: 12),
                _buildInstallTypeInputRow(
                  label: l.freestandingAcLabel,
                  totalCtrl: freestandingTotalCtrl,
                  shareCtrl: freestandingShareCtrl,
                  totalHint: l.totalOnInvoice,
                  shareHint: l.myShare,
                  l: l,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: l.acInstallNote,
                    prefixIcon: const Icon(
                      Icons.note_outlined,
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(ctx).pop(true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    final controllers = [
      splitTotalCtrl,
      splitShareCtrl,
      windowTotalCtrl,
      windowShareCtrl,
      freestandingTotalCtrl,
      freestandingShareCtrl,
      noteCtrl,
    ];

    if (shouldSave != true) {
      for (final c in controllers) {
        c.dispose();
      }
      return;
    }

    int parseQty(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

    final splitTotal = parseQty(splitTotalCtrl);
    final splitShare = parseQty(splitShareCtrl);
    final windowTotal = parseQty(windowTotalCtrl);
    final windowShare = parseQty(windowShareCtrl);
    final freestandingTotal = parseQty(freestandingTotalCtrl);
    final freestandingShare = parseQty(freestandingShareCtrl);
    final note = noteCtrl.text.trim();

    for (final c in controllers) {
      c.dispose();
    }

    if (splitTotal == 0 && windowTotal == 0 && freestandingTotal == 0) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.enterAtLeastOneUnit,
        );
      }
      return;
    }

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final approvalConfig = ref.read(approvalConfigProvider).value;
      final requiresApproval = approvalConfig?.inOutApprovalRequired ?? true;
      final lockedBeforeDate = approvalConfig?.lockedBeforeDate;
      final now = DateTime.now();

      final install = AcInstallModel(
        techId: user.uid,
        techName: user.name,
        splitTotal: splitTotal,
        splitShare: splitShare,
        windowTotal: windowTotal,
        windowShare: windowShare,
        freestandingTotal: freestandingTotal,
        freestandingShare: freestandingShare,
        note: note,
        status: requiresApproval
            ? AcInstallStatus.pending
            : AcInstallStatus.approved,
        date: now,
        createdAt: now,
        reviewedAt: requiresApproval ? null : now,
      );

      await ref
          .read(acInstallRepositoryProvider)
          .addInstall(install, lockedBeforeDate: lockedBeforeDate);

      if (mounted) {
        HapticFeedback.lightImpact();
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.installationsLogged,
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = ref.read(appLocaleProvider);
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    }
  }
}

class _InstallSummaryChip extends StatelessWidget {
  const _InstallSummaryChip({
    required this.label,
    required this.value,
    this.color = ArcticTheme.arcticBlue,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}
