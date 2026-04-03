import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final approvalConfigRepositoryProvider = Provider<ApprovalConfigRepository>((
  ref,
) {
  return ApprovalConfigRepository(firestore: FirebaseFirestore.instance);
});

class ApprovalConfig {
  const ApprovalConfig({
    required this.jobApprovalRequired,
    required this.sharedJobApprovalRequired,
    required this.inOutApprovalRequired,
    required this.enforceMinimumBuild,
    required this.minSupportedBuildNumber,
  });

  final bool jobApprovalRequired;
  final bool sharedJobApprovalRequired;
  final bool inOutApprovalRequired;
  final bool enforceMinimumBuild;
  final int minSupportedBuildNumber;

  factory ApprovalConfig.defaults() => const ApprovalConfig(
    jobApprovalRequired: false,
    sharedJobApprovalRequired: true,
    inOutApprovalRequired: false,
    enforceMinimumBuild: false,
    minSupportedBuildNumber: 1,
  );

  factory ApprovalConfig.fromMap(Map<String, dynamic>? data) {
    return ApprovalConfig(
      jobApprovalRequired: data?['jobApprovalRequired'] is bool
          ? data!['jobApprovalRequired'] as bool
          : false,
      sharedJobApprovalRequired: data?['sharedJobApprovalRequired'] is bool
          ? data!['sharedJobApprovalRequired'] as bool
          : true,
      inOutApprovalRequired: data?['inOutApprovalRequired'] is bool
          ? data!['inOutApprovalRequired'] as bool
          : false,
      enforceMinimumBuild: data?['enforceMinimumBuild'] is bool
          ? data!['enforceMinimumBuild'] as bool
          : false,
      minSupportedBuildNumber: data?['minSupportedBuildNumber'] is int
          ? data!['minSupportedBuildNumber'] as int
          : 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'jobApprovalRequired': jobApprovalRequired,
    'sharedJobApprovalRequired': sharedJobApprovalRequired,
    'inOutApprovalRequired': inOutApprovalRequired,
    'enforceMinimumBuild': enforceMinimumBuild,
    'minSupportedBuildNumber': minSupportedBuildNumber,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class ApprovalConfigRepository {
  ApprovalConfigRepository({required this.firestore});

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get _doc => firestore
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.approvalConfigDocId);

  Stream<ApprovalConfig> watchConfig() {
    return _doc.snapshots().map((doc) {
      if (!doc.exists) return ApprovalConfig.defaults();
      return ApprovalConfig.fromMap(doc.data());
    });
  }

  Future<void> setJobApprovalRequired(bool required) async {
    final current = await _doc.get();
    final existing = current.exists
        ? ApprovalConfig.fromMap(current.data())
        : ApprovalConfig.defaults();
    final next = ApprovalConfig(
      jobApprovalRequired: required,
      sharedJobApprovalRequired: existing.sharedJobApprovalRequired,
      inOutApprovalRequired: existing.inOutApprovalRequired,
      enforceMinimumBuild: existing.enforceMinimumBuild,
      minSupportedBuildNumber: existing.minSupportedBuildNumber,
    );
    await _doc.set(next.toMap(), SetOptions(merge: true));
  }

  Future<void> setSharedJobApprovalRequired(bool required) async {
    final current = await _doc.get();
    final existing = current.exists
        ? ApprovalConfig.fromMap(current.data())
        : ApprovalConfig.defaults();
    final next = ApprovalConfig(
      jobApprovalRequired: existing.jobApprovalRequired,
      sharedJobApprovalRequired: required,
      inOutApprovalRequired: existing.inOutApprovalRequired,
      enforceMinimumBuild: existing.enforceMinimumBuild,
      minSupportedBuildNumber: existing.minSupportedBuildNumber,
    );
    await _doc.set(next.toMap(), SetOptions(merge: true));
  }

  Future<void> setInOutApprovalRequired(bool required) async {
    final current = await _doc.get();
    final existing = current.exists
        ? ApprovalConfig.fromMap(current.data())
        : ApprovalConfig.defaults();
    final next = ApprovalConfig(
      jobApprovalRequired: existing.jobApprovalRequired,
      sharedJobApprovalRequired: existing.sharedJobApprovalRequired,
      inOutApprovalRequired: required,
      enforceMinimumBuild: existing.enforceMinimumBuild,
      minSupportedBuildNumber: existing.minSupportedBuildNumber,
    );
    await _doc.set(next.toMap(), SetOptions(merge: true));
  }

  Future<void> setEnforceMinimumBuild(bool required) async {
    final current = await _doc.get();
    final existing = current.exists
        ? ApprovalConfig.fromMap(current.data())
        : ApprovalConfig.defaults();
    final next = ApprovalConfig(
      jobApprovalRequired: existing.jobApprovalRequired,
      sharedJobApprovalRequired: existing.sharedJobApprovalRequired,
      inOutApprovalRequired: existing.inOutApprovalRequired,
      enforceMinimumBuild: required,
      minSupportedBuildNumber: existing.minSupportedBuildNumber,
    );
    await _doc.set(next.toMap(), SetOptions(merge: true));
  }

  Future<void> setMinimumSupportedBuildNumber(int buildNumber) async {
    final sanitized = buildNumber < 1 ? 1 : buildNumber;
    final current = await _doc.get();
    final existing = current.exists
        ? ApprovalConfig.fromMap(current.data())
        : ApprovalConfig.defaults();
    final next = ApprovalConfig(
      jobApprovalRequired: existing.jobApprovalRequired,
      sharedJobApprovalRequired: existing.sharedJobApprovalRequired,
      inOutApprovalRequired: existing.inOutApprovalRequired,
      enforceMinimumBuild: existing.enforceMinimumBuild,
      minSupportedBuildNumber: sanitized,
    );
    await _doc.set(next.toMap(), SetOptions(merge: true));
  }
}
