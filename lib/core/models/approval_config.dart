import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalConfig {
  const ApprovalConfig({
    required this.jobApprovalRequired,
    required this.sharedJobApprovalRequired,
    required this.inOutApprovalRequired,
    required this.enforceMinimumBuild,
    required this.minSupportedBuildNumber,
    required this.lockedBeforeDate,
    required this.techTransferAllowed,
    required this.techTransferRequiresApproval,
  });

  final bool jobApprovalRequired;
  final bool sharedJobApprovalRequired;
  final bool inOutApprovalRequired;
  final bool enforceMinimumBuild;
  final int minSupportedBuildNumber;
  final DateTime? lockedBeforeDate;

  /// Whether technicians are allowed to initiate job transfers to other techs.
  final bool techTransferAllowed;

  /// When [techTransferAllowed] is true, whether tech-initiated transfers
  /// require admin approval before taking effect.
  final bool techTransferRequiresApproval;

  factory ApprovalConfig.defaults() => const ApprovalConfig(
    jobApprovalRequired: true,
    sharedJobApprovalRequired: true,
    inOutApprovalRequired: true,
    enforceMinimumBuild: false,
    minSupportedBuildNumber: 1,
    lockedBeforeDate: null,
    techTransferAllowed: false,
    techTransferRequiresApproval: true,
  );

  factory ApprovalConfig.fromMap(Map<String, dynamic>? data) {
    final minSupportedBuildNumber = data?['minSupportedBuildNumber'] is int
        ? data!['minSupportedBuildNumber'] as int
        : 1;
    return ApprovalConfig(
      jobApprovalRequired: data?['jobApprovalRequired'] is bool
          ? data!['jobApprovalRequired'] as bool
          : true,
      sharedJobApprovalRequired: data?['sharedJobApprovalRequired'] is bool
          ? data!['sharedJobApprovalRequired'] as bool
          : true,
      inOutApprovalRequired: data?['inOutApprovalRequired'] is bool
          ? data!['inOutApprovalRequired'] as bool
          : true,
      enforceMinimumBuild: data?['enforceMinimumBuild'] is bool
          ? data!['enforceMinimumBuild'] as bool
          : false,
      minSupportedBuildNumber: minSupportedBuildNumber < 1
          ? 1
          : minSupportedBuildNumber,
      lockedBeforeDate: _timestampFromConfig(data?['lockedBefore']),
      techTransferAllowed: data?['techTransferAllowed'] is bool
          ? data!['techTransferAllowed'] as bool
          : false,
      techTransferRequiresApproval:
          data?['techTransferRequiresApproval'] is bool
          ? data!['techTransferRequiresApproval'] as bool
          : true,
    );
  }

  static DateTime? _timestampFromConfig(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  ApprovalConfig copyWith({
    bool? jobApprovalRequired,
    bool? sharedJobApprovalRequired,
    bool? inOutApprovalRequired,
    bool? enforceMinimumBuild,
    int? minSupportedBuildNumber,
    DateTime? lockedBeforeDate,
    bool clearLockedBeforeDate = false,
    bool? techTransferAllowed,
    bool? techTransferRequiresApproval,
  }) {
    return ApprovalConfig(
      jobApprovalRequired: jobApprovalRequired ?? this.jobApprovalRequired,
      sharedJobApprovalRequired:
          sharedJobApprovalRequired ?? this.sharedJobApprovalRequired,
      inOutApprovalRequired:
          inOutApprovalRequired ?? this.inOutApprovalRequired,
      enforceMinimumBuild: enforceMinimumBuild ?? this.enforceMinimumBuild,
      minSupportedBuildNumber:
          minSupportedBuildNumber ?? this.minSupportedBuildNumber,
      lockedBeforeDate: clearLockedBeforeDate
          ? null
          : lockedBeforeDate ?? this.lockedBeforeDate,
      techTransferAllowed: techTransferAllowed ?? this.techTransferAllowed,
      techTransferRequiresApproval:
          techTransferRequiresApproval ?? this.techTransferRequiresApproval,
    );
  }

  Map<String, dynamic> toMap() => {
    'jobApprovalRequired': jobApprovalRequired,
    'sharedJobApprovalRequired': sharedJobApprovalRequired,
    'inOutApprovalRequired': inOutApprovalRequired,
    'enforceMinimumBuild': enforceMinimumBuild,
    'minSupportedBuildNumber': minSupportedBuildNumber,
    'lockedBefore': lockedBeforeDate == null
        ? null
        : Timestamp.fromDate(lockedBeforeDate!),
    'techTransferAllowed': techTransferAllowed,
    'techTransferRequiresApproval': techTransferRequiresApproval,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  bool locksDate(DateTime value) {
    final lockDate = lockedBeforeDate;
    return lockDate != null && value.isBefore(lockDate);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalConfig &&
        other.jobApprovalRequired == jobApprovalRequired &&
        other.sharedJobApprovalRequired == sharedJobApprovalRequired &&
        other.inOutApprovalRequired == inOutApprovalRequired &&
        other.enforceMinimumBuild == enforceMinimumBuild &&
        other.minSupportedBuildNumber == minSupportedBuildNumber &&
        other.lockedBeforeDate == lockedBeforeDate &&
        other.techTransferAllowed == techTransferAllowed &&
        other.techTransferRequiresApproval == techTransferRequiresApproval;
  }

  @override
  int get hashCode => Object.hash(
    jobApprovalRequired,
    sharedJobApprovalRequired,
    inOutApprovalRequired,
    enforceMinimumBuild,
    minSupportedBuildNumber,
    lockedBeforeDate,
    techTransferAllowed,
    techTransferRequiresApproval,
  );
}
