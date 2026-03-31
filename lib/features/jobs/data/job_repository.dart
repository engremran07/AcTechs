import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(firestore: FirebaseFirestore.instance);
});

class JobRepository {
  JobRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      firestore.collection(AppConstants.jobsCollection);

  Future<void> submitJob(JobModel job) async {
    try {
      final data = job.toFirestore();
      data['date'] ??= FieldValue.serverTimestamp();
      data['submittedAt'] ??= FieldValue.serverTimestamp();
      await _jobsRef.add(data);
    } on FirebaseException catch (e) {
      debugPrint('submitJob FirebaseException: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw const JobException(
          'job_permission_denied',
          'Permission denied. Please contact your admin.',
          'اجازت نہیں۔ براہ کرم ایڈمن سے رابطہ کریں۔',
          'ليس لديك إذن. تواصل مع المسؤول.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw NetworkException.syncFailed();
      }
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('submitJob unknown error: $e');
      throw JobException.saveFailed();
    }
  }

  Future<void> approveJob(String jobId, String adminUid) async {
    try {
      await _jobsRef.doc(jobId).update({
        'status': 'approved',
        'approvedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('approveJob error: ${e.code} — ${e.message}');
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('approveJob unknown: $e');
      throw JobException.saveFailed();
    }
  }

  Future<void> rejectJob(String jobId, String adminUid, String reason) async {
    try {
      await _jobsRef.doc(jobId).update({
        'status': 'rejected',
        'approvedBy': adminUid,
        'adminNote': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('rejectJob error: ${e.code} — ${e.message}');
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('rejectJob unknown: $e');
      throw JobException.saveFailed();
    }
  }

  Stream<List<JobModel>> technicianJobs(String techId) {
    return _jobsRef
        .where('techId', isEqualTo: techId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<JobModel>> todaysJobs(String techId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _jobsRef
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<JobModel>> pendingApprovals() {
    return _jobsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<JobModel>> allJobs() {
    return _jobsRef
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  /// Monthly jobs for a tech — used by summary screen.
  Stream<List<JobModel>> monthlyJobs(String techId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _jobsRef
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Future<List<JobModel>> jobsForPeriod(DateTime start, DateTime end) async {
    final snap = await _jobsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
  }
}
