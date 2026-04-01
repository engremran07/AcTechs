import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

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

/// Monthly jobs for the logged-in tech.
final monthlyJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(jobRepositoryProvider).monthlyJobs(user.uid, month);
    });
