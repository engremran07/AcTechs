import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

/// Stream of shared_install_aggregates where the current user is a team member.
///
/// Uses the [teamMemberIds] arrayContains index — see firestore.indexes.json.
/// Legacy aggregates (no teamMemberIds field) are NOT returned by this query;
/// they will only appear in the admin view via a full-collection scan.
final pendingSharedInstallAggregatesProvider =
    StreamProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .where('teamMemberIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(SharedInstallAggregate.fromFirestore)
                // Hide aggregates where all unit types have been fully consumed
                // by the team. Once consumed == invoiceTotals for every field,
                // there is nothing left for any team member to contribute.
                .where((agg) => !agg.isFullyConsumed)
                .toList(),
          );
    });

/// Admin view: all non-deleted shared install aggregates that have not been
/// fully consumed by the team. Shows aggregates where contributions are still
/// pending from one or more team members.
///
/// Does NOT filter by teamMemberIds — admin sees all teams' pending installs.
final pendingCollaborationAggregatesProvider =
    StreamProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
      return FirebaseFirestore.instance
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(SharedInstallAggregate.fromFirestore)
                // Hide fully-consumed and soft-deleted aggregates.
                .where((agg) => !agg.isFullyConsumed && !agg.isDeleted)
                .toList(),
          );
    });

/// Whether the current user has already submitted a job for [groupKey].
///
/// Returns true for the creator (teamMemberIds[0]) who submitted atomically
/// during aggregate creation. Dashboard cards use this to show
/// [l.teamJobSubmitted] instead of [l.teamJobPending] for the creator.
final userSharedInstallStatusProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, groupKey) async {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return false;
      return ref
          .watch(jobRepositoryProvider)
          .hasUserSubmittedForGroup(user.uid, groupKey);
    });
