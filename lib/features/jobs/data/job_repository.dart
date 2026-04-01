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

  String _normalizeInvoice(String invoice) {
    final trimmed = invoice.trim();
    if (trimmed.isEmpty) return '';
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('INV-')) {
      return trimmed.substring(4).trim();
    }
    if (upper.startsWith('INV ')) {
      return trimmed.substring(4).trim();
    }
    return trimmed;
  }

  String _safeImportDocId(JobModel job) {
    final invoice = _normalizeInvoice(job.invoiceNumber).toLowerCase();
    final safe = invoice.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final scoped = 'inv_${safe.isEmpty ? DateTime.now().millisecondsSinceEpoch : safe}';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }

  Future<void> submitJob(JobModel job) async {
    try {
      final data = job.toFirestore();
      data['date'] ??= FieldValue.serverTimestamp();
      data['submittedAt'] ??= FieldValue.serverTimestamp();
      await _jobsRef.add(data);
    } on FirebaseException catch (e) {
      debugPrint('submitJob FirebaseException: ${e.code} — ${e.message}');
      if (e.code == 'unauthenticated') {
        throw AuthException.sessionExpired();
      }
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

  Future<void> bulkApproveJobs(List<String> jobIds, String adminUid) async {
    try {
      if (jobIds.isEmpty) return;
      const chunkSize = 400;
      for (var i = 0; i < jobIds.length; i += chunkSize) {
        final end = (i + chunkSize > jobIds.length)
            ? jobIds.length
            : i + chunkSize;
        final chunk = jobIds.sublist(i, end);
        final batch = firestore.batch();
        for (final id in chunk) {
          batch.update(_jobsRef.doc(id), {
            'status': AppConstants.statusApproved,
            'approvedBy': adminUid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      debugPrint('bulkApproveJobs error: ${e.code} — ${e.message}');
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('bulkApproveJobs unknown: $e');
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

  Future<int> importJobs(List<JobModel> jobs) async {
    try {
      if (jobs.isEmpty) return 0;
      final chunks = <List<JobModel>>[];
      const chunkSize = 400;
      for (var i = 0; i < jobs.length; i += chunkSize) {
        final end = (i + chunkSize > jobs.length) ? jobs.length : i + chunkSize;
        chunks.add(jobs.sublist(i, end));
      }

      var imported = 0;
      for (final chunk in chunks) {
        final batch = firestore.batch();
        for (final job in chunk) {
          final normalizedInvoice = _normalizeInvoice(job.invoiceNumber);
          final ref = _jobsRef.doc(_safeImportDocId(job));
          final data = job
              .copyWith(invoiceNumber: normalizedInvoice)
              .toFirestore();
          data['date'] ??= FieldValue.serverTimestamp();
          data['submittedAt'] ??= FieldValue.serverTimestamp();
          batch.set(ref, data, SetOptions(merge: true));
          imported++;
        }
        await batch.commit();
      }
      return imported;
    } on FirebaseException catch (e) {
      debugPrint('importJobs FirebaseException: ${e.code} — ${e.message}');
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('importJobs unknown error: $e');
      throw JobException.saveFailed();
    }
  }
}
