import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  String _search = '';
  final Set<String> _selected = {};
  bool _isBulkProcessing = false;

  List<JobModel> _filter(List<JobModel> jobs) {
    if (_search.isEmpty) return jobs;
    final q = _search.toLowerCase();
    return jobs
        .where(
          (j) =>
              j.clientName.toLowerCase().contains(q) ||
              j.techName.toLowerCase().contains(q) ||
              j.invoiceNumber.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    setState(() => _isBulkProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      final repo = ref.read(jobRepositoryProvider);
      await repo.bulkApproveJobs(_selected.toList(), admin.uid);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(
            context,
          )!.bulkApproveSuccess(_selected.length),
        );
        setState(() => _selected.clear());
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.bulkApproveFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  Future<void> _bulkReject() async {
    if (_selected.isEmpty) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectSelectedJobs),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.rejectAll),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isBulkProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      final repo = ref.read(jobRepositoryProvider);
      for (final id in _selected) {
        await repo.rejectJob(id, admin.uid, reason);
      }
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(
            context,
          )!.bulkRejectSuccess(_selected.length),
        );
        setState(() => _selected.clear());
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.bulkRejectFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkProcessing = false);
    }
  }

  void _refreshApprovals() {
    ref.invalidate(pendingApprovalsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApprovalsProvider);
    final successTone = Theme.of(context).brightness == Brightness.light
        ? ArcticTheme.lightSuccess
        : ArcticTheme.arcticSuccess;

    return AppShortcuts(
      onRefresh: _refreshApprovals,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.approvals)),
        body: SafeArea(
          child: pending.when(
            data: (jobs) {
              final filtered = _filter(jobs);
              _selected.removeWhere((id) => !filtered.any((j) => j.id == id));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: ArcticSearchBar(
                      hint: AppLocalizations.of(
                        context,
                      )!.searchByTechClientInvoice,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    BulkActionBar(
                      selectedCount: _selected.length,
                      isProcessing: _isBulkProcessing,
                      onClear: () => setState(() => _selected.clear()),
                      actions: [
                        BulkAction(
                          label: AppLocalizations.of(context)!.approve,
                          icon: Icons.check_rounded,
                          color: ArcticTheme.arcticSuccess,
                          onPressed: _bulkApprove,
                        ),
                        BulkAction(
                          label: AppLocalizations.of(context)!.reject,
                          icon: Icons.close_rounded,
                          color: ArcticTheme.arcticError,
                          onPressed: _bulkReject,
                        ),
                      ],
                    ),
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 64,
                              color: successTone.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _search.isNotEmpty
                                  ? AppLocalizations.of(
                                      context,
                                    )!.noMatchingApprovals
                                  : AppLocalizations.of(context)!.allCaughtUp,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              AppLocalizations.of(context)!.noApprovals,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ArcticRefreshIndicator(
                        onRefresh: () async => _refreshApprovals(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final job = filtered[index];
                            return SwipeActionCard(
                                  onSwipeRight: () async {
                                    // Approve on swipe right
                                    final approvedMsg = AppLocalizations.of(
                                      context,
                                    )!.jobApproved;
                                    final failMsg = AppLocalizations.of(
                                      context,
                                    )!.couldNotApprove;
                                    try {
                                      await ref
                                          .read(jobRepositoryProvider)
                                          .approveJob(
                                            job.id,
                                            ref
                                                    .read(currentUserProvider)
                                                    .value
                                                    ?.uid ??
                                                '',
                                          );
                                      if (!context.mounted) return;
                                      AppFeedback.success(
                                        context,
                                        message: approvedMsg,
                                      );
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      AppFeedback.error(
                                        context,
                                        message: failMsg,
                                      );
                                    }
                                  },
                                  onSwipeLeft: () => _showRejectDialogFor(job),
                                  rightIcon: Icons.check_rounded,
                                  leftIcon: Icons.close_rounded,
                                  child: _ApprovalCard(
                                    job: job,
                                    isSelected: _selected.contains(job.id),
                                    onSelect: (v) {
                                      setState(() {
                                        if (v) {
                                          _selected.add(job.id);
                                        } else {
                                          _selected.remove(job.id);
                                        }
                                      });
                                    },
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

  Future<void> _showRejectDialogFor(JobModel job) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectJob),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .rejectJob(job.id, admin.uid, reason);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobRejected,
        );
      }
    } catch (_) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotReject,
        );
      }
    }
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  const _ApprovalCard({
    required this.job,
    required this.isSelected,
    required this.onSelect,
  });

  final JobModel job;
  final bool isSelected;
  final ValueChanged<bool> onSelect;

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _isProcessing = false;

  Color get _successTone => Theme.of(context).brightness == Brightness.light
      ? ArcticTheme.lightSuccess
      : ArcticTheme.arcticSuccess;

  Color get _warningTone => Theme.of(context).brightness == Brightness.light
      ? ArcticTheme.lightWarning
      : ArcticTheme.arcticWarning;

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .approveJob(widget.job.id, admin.uid);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobApproved,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotApprove,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectJob),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectReason,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final admin = ref.read(currentUserProvider).value;
      if (admin == null) return;
      await ref
          .read(jobRepositoryProvider)
          .rejectJob(widget.job.id, admin.uid, reason);
      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobRejected,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.couldNotReject,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    final textSecondary =
        Theme.of(context).textTheme.bodySmall?.color ??
        ArcticTheme.arcticTextSecondary;
    final chipBg = Theme.of(context).cardColor;

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.isSelected,
                onChanged: (v) => widget.onSelect(v ?? false),
                activeColor: colorScheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    job.techName.isNotEmpty
                        ? job.techName[0].toUpperCase()
                        : 'T',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.techName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24, color: dividerColor),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  job.clientName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (job.clientContact.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: textSecondary),
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
                  icon: const FaIcon(
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
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.ac_unit_rounded, size: 16, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                AppFormatters.units(job.totalUnits),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (job.expenses > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.payments_outlined, size: 16, color: _warningTone),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppFormatters.currency(job.expenses),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _warningTone),
                  ),
                ),
              ],
            ],
          ),
          if (job.acUnits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: job.acUnits
                  .map(
                    (u) => Chip(
                      label: Text(
                        '${translateCategory(u.type, AppLocalizations.of(context)!)} × ${u.quantity}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: chipBg,
                      side: BorderSide(color: dividerColor),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _showRejectDialog,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.reject),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _approve,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ArcticTheme.arcticDarkBg,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(AppLocalizations.of(context)!.approve),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _successTone,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
