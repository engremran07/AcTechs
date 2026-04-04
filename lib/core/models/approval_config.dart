import 'package:cloud_firestore/cloud_firestore.dart';

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
    sharedJobApprovalRequired: false,
    inOutApprovalRequired: false,
    enforceMinimumBuild: false,
    minSupportedBuildNumber: 1,
  );

  factory ApprovalConfig.fromMap(Map<String, dynamic>? data) {
    final minSupportedBuildNumber = data?['minSupportedBuildNumber'] is int
        ? data!['minSupportedBuildNumber'] as int
        : 1;
    return ApprovalConfig(
      jobApprovalRequired: data?['jobApprovalRequired'] is bool
          ? data!['jobApprovalRequired'] as bool
          : false,
      sharedJobApprovalRequired: data?['sharedJobApprovalRequired'] is bool
          ? data!['sharedJobApprovalRequired'] as bool
          : false,
      inOutApprovalRequired: data?['inOutApprovalRequired'] is bool
          ? data!['inOutApprovalRequired'] as bool
          : false,
      enforceMinimumBuild: data?['enforceMinimumBuild'] is bool
          ? data!['enforceMinimumBuild'] as bool
          : false,
      minSupportedBuildNumber: minSupportedBuildNumber < 1
          ? 1
          : minSupportedBuildNumber,
    );
  }

  ApprovalConfig copyWith({
    bool? jobApprovalRequired,
    bool? sharedJobApprovalRequired,
    bool? inOutApprovalRequired,
    bool? enforceMinimumBuild,
    int? minSupportedBuildNumber,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApprovalConfig &&
        other.jobApprovalRequired == jobApprovalRequired &&
        other.sharedJobApprovalRequired == sharedJobApprovalRequired &&
        other.inOutApprovalRequired == inOutApprovalRequired &&
        other.enforceMinimumBuild == enforceMinimumBuild &&
        other.minSupportedBuildNumber == minSupportedBuildNumber;
  }

  @override
  int get hashCode => Object.hash(
    jobApprovalRequired,
    sharedJobApprovalRequired,
    inOutApprovalRequired,
    enforceMinimumBuild,
    minSupportedBuildNumber,
  );
}
