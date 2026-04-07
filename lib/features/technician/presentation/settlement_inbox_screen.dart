import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class SettlementInboxScreen extends ConsumerWidget {
  const SettlementInboxScreen({super.key});

  Future<String?> _promptComment(BuildContext context) async {
    final controller = TextEditingController();
    final l = AppLocalizations.of(context)!;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.rejectPayment),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: l.settlementTechnicianComment),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final inboxAsync = ref.watch(technicianSettlementInboxProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentInbox)),
      body: SafeArea(
        child: inboxAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Text(
                  l.allCaughtUp,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            final byBatch = <String, List<JobModel>>{};
            for (final job in jobs) {
              byBatch.putIfAbsent(job.settlementBatchId, () => <JobModel>[]).add(job);
            }
            final entries = byBatch.entries.toList(growable: false);

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final batchId = entries[index].key;
                final items = entries[index].value;
                final first = items.first;
                return ArcticCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.settlementBatch}: ${batchId.substring(0, batchId.length > 12 ? 12 : batchId.length)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${items.length} ${l.jobs} • ${AppFormatters.date(first.settlementRequestedAt ?? first.date)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                      ),
                      if (first.settlementAdminNote.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(first.settlementAdminNote),
                      ],
                      const SizedBox(height: 10),
                      ...items.map(
                        (job) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(job.invoiceNumber)),
                              Text(AppFormatters.date(job.date)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final comment = await _promptComment(context);
                                if (comment == null || comment.isEmpty) return;
                                final user = ref.read(currentUserProvider).value;
                                if (user == null) return;
                                await ref.read(jobRepositoryProvider).rejectSettlementBatch(
                                      batchId,
                                      user.uid,
                                      comment,
                                    );
                                if (context.mounted) {
                                  AppFeedback.success(
                                    context,
                                    message: l.paymentRejectedForCorrection,
                                  );
                                }
                              },
                              icon: const Icon(Icons.close_rounded),
                              label: Text(l.rejectPayment),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                final user = ref.read(currentUserProvider).value;
                                if (user == null) return;
                                await ref.read(jobRepositoryProvider).confirmSettlementBatch(
                                      batchId,
                                      user.uid,
                                    );
                                if (context.mounted) {
                                  AppFeedback.success(
                                    context,
                                    message: l.paymentConfirmedSuccess,
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l.confirmPaymentReceived),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
    );
  }
}
