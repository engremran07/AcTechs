import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

enum JobAcTypeFilter { split, window, freestanding }

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

final allJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(jobRepositoryProvider).allJobs();
});

final techJobsByAcTypeProvider = Provider.autoDispose
    .family<List<JobModel>, JobAcTypeFilter>((ref, filter) {
      final jobs = ref.watch(technicianJobsProvider).value ?? const <JobModel>[];
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
