import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

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
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map(SharedInstallAggregate.fromFirestore).toList(),
          );
    });

/// Single aggregate by [groupKey]. Used in submit_job_screen to pre-fill
/// invoice totals and team roster when joining an existing shared install.
final sharedAggregateByGroupKeyProvider = StreamProvider.autoDispose
    .family<SharedInstallAggregate?, String>((ref, groupKey) {
      if (groupKey.isEmpty) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .doc(groupKey)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return null;
            return SharedInstallAggregate.fromFirestore(snap);
          });
    });
