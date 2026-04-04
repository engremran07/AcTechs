import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

enum JobAcTypeFilter { split, window, freestanding }

class AdminJobsQuery {
  const AdminJobsQuery({this.start, this.end, this.techId});

  final DateTime? start;
  final DateTime? end;
  final String? techId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminJobsQuery &&
        other.start == start &&
        other.end == end &&
        other.techId == techId;
  }

  @override
  int get hashCode => Object.hash(start, end, techId);
}

String jobAcTypeFilterToPath(JobAcTypeFilter filter) {
  switch (filter) {
    case JobAcTypeFilter.split:
      return 'split';
    case JobAcTypeFilter.window:
      return 'window';
    case JobAcTypeFilter.freestanding:
      return 'freestanding';
  }
}

JobAcTypeFilter? jobAcTypeFilterFromPath(String raw) {
  switch (raw.toLowerCase()) {
    case 'split':
      return JobAcTypeFilter.split;
    case 'window':
      return JobAcTypeFilter.window;
    case 'freestanding':
      return JobAcTypeFilter.freestanding;
    default:
      return null;
  }
}

String _unitTypeForFilter(JobAcTypeFilter filter) {
  switch (filter) {
    case JobAcTypeFilter.split:
      return 'Split AC';
    case JobAcTypeFilter.window:
      return 'Window AC';
    case JobAcTypeFilter.freestanding:
      return 'Freestanding AC';
  }
}

List<JobModel> _jobsByType(List<JobModel> jobs, JobAcTypeFilter filter) {
  final unitType = _unitTypeForFilter(filter);
  return jobs
      .where(
        (job) => job.acUnits.any(
          (unit) => unit.type == unitType && unit.quantity > 0,
        ),
      )
      .toList(growable: false);
}

final technicianJobsProvider = StreamProvider.autoDispose<List<JobModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).technicianJobs(user.uid);
});

final todaysJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).todaysJobs(user.uid);
});

final pendingApprovalsProvider = StreamProvider.autoDispose<List<JobModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).pendingApprovals();
});

final approvedSharedInstallsProvider =
    StreamProvider.autoDispose<List<JobModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return Stream.value([]);
      return ref.watch(jobRepositoryProvider).approvedSharedInstalls();
    });

final allJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).allJobs();
});

final adminJobSummaryProvider = FutureProvider.autoDispose<AdminJobSummary>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) {
    return Future.value(AdminJobSummary.empty());
  }
  return ref.watch(jobRepositoryProvider).fetchAdminJobSummary();
});

final filteredAdminJobsProvider = FutureProvider.autoDispose
    .family<List<JobModel>, AdminJobsQuery>((ref, query) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null || !user.isAdmin) return Future.value(const []);
      return ref
          .watch(jobRepositoryProvider)
          .jobsForAdminFilter(
            start: query.start,
            end: query.end,
            techId: query.techId,
          );
    });

final techJobsByAcTypeProvider = Provider.autoDispose
    .family<List<JobModel>, JobAcTypeFilter>((ref, filter) {
      final jobs =
          ref.watch(technicianJobsProvider).value ?? const <JobModel>[];
      return _jobsByType(jobs, filter);
    });

final adminJobsByAcTypeProvider = Provider.autoDispose
    .family<List<JobModel>, JobAcTypeFilter>((ref, filter) {
      final jobs = ref.watch(allJobsProvider).value ?? const <JobModel>[];
      return _jobsByType(jobs, filter);
    });

/// Monthly jobs for the logged-in tech.
final monthlyJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(jobRepositoryProvider).monthlyJobs(user.uid, month);
    });
