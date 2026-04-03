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
        child: _buildAcInstallSection(theme, installsAsync),
      ),
    );
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.air_outlined,
              size: 64,
              color: ArcticTheme.arcticTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l.noInstallationsToday,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: installs.length,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildInstallCard(theme, installs[index], l),
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
              if (install.isPending) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _confirmDeleteInstall(install),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: ArcticTheme.arcticError,
                    ),
                  ),
                ),
              ],
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
      final requiresApproval = approvalConfig?.inOutApprovalRequired ?? false;
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

      await ref.read(acInstallRepositoryProvider).addInstall(install);

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

  Future<void> _confirmDeleteInstall(AcInstallModel install) async {
    final l = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.deleteInstallRecord),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ArcticTheme.arcticError,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    try {
      await ref.read(acInstallRepositoryProvider).deleteInstall(install.id);
      if (mounted) HapticFeedback.mediumImpact();
    } on AppException catch (e) {
      if (mounted) {
        final locale = ref.read(appLocaleProvider);
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    }
  }
}
