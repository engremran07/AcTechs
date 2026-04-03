import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(firestore: FirebaseFirestore.instance);
});

class JobRepository {
  JobRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      firestore.collection(AppConstants.jobsCollection);

  int _unitsForType(JobModel job, String type) => job.acUnits
      .where((unit) => unit.type == type)
      .fold(0, (total, unit) => total + unit.quantity);

  String _safeImportDocId(JobModel job) {
    final invoice = InvoiceUtils.normalize(job.invoiceNumber).toLowerCase();
    final safe = invoice.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final scoped =
        'inv_${safe.isEmpty ? DateTime.now().millisecondsSinceEpoch : safe}';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }

  Future<void> submitJob(JobModel job) async {
    try {
      final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
      final normalizedGroupKey = job.sharedInstallGroupKey.isEmpty
          ? ''
          : InvoiceUtils.normalize(job.sharedInstallGroupKey).toLowerCase();
      final duplicateSnap = await _jobsRef
          .where('techId', isEqualTo: job.techId)
          .where('companyId', isEqualTo: job.companyId)
          .where('invoiceNumber', isEqualTo: normalizedInvoice)
          .limit(1)
          .get();
      if (duplicateSnap.docs.isNotEmpty) {
        throw JobException.duplicateInvoice();
      }

      if (job.isSharedInstall) {
        final splitContribution = _unitsForType(
          job,
          AppConstants.unitTypeSplitAc,
        );
        final windowContribution = _unitsForType(
          job,
          AppConstants.unitTypeWindowAc,
        );
        final freestandingContribution = _unitsForType(
          job,
          AppConstants.unitTypeFreestandingAc,
        );

        final typeLimits = <(String, int, int)>[
          (
            AppConstants.unitTypeSplitAc,
            splitContribution,
            job.sharedInvoiceSplitUnits,
          ),
          (
            AppConstants.unitTypeWindowAc,
            windowContribution,
            job.sharedInvoiceWindowUnits,
          ),
          (
            AppConstants.unitTypeFreestandingAc,
            freestandingContribution,
            job.sharedInvoiceFreestandingUnits,
          ),
        ];

        for (final typeLimit in typeLimits) {
          final contribution = typeLimit.$2;
          final totalAllowed = typeLimit.$3;
          if (contribution <= 0) continue;
          if (totalAllowed <= 0 || contribution > totalAllowed) {
            throw JobException.sharedTypeUnitsExceeded(
              unitType: typeLimit.$1,
              remaining: totalAllowed < 0 ? 0 : totalAllowed,
            );
          }
        }

        final key = normalizedGroupKey.isNotEmpty
            ? normalizedGroupKey
            : '${(job.companyId.isEmpty ? 'no-company' : job.companyId).toLowerCase()}-$normalizedInvoice';
        final sharedSnap = await _jobsRef
            .where('sharedInstallGroupKey', isEqualTo: key)
            .get();
        final existingSharedJobs = sharedSnap.docs
            .map((doc) => JobModel.fromFirestore(doc))
            .where((entry) => entry.status != JobStatus.rejected)
            .toList();

        for (final typeLimit in typeLimits) {
          final typeName = typeLimit.$1;
          final contribution = typeLimit.$2;
          final totalAllowed = typeLimit.$3;
          if (contribution <= 0) continue;
          final consumed = existingSharedJobs.fold<int>(
            0,
            (total, entry) => total + _unitsForType(entry, typeName),
          );
          final remaining = totalAllowed - consumed;
          if (contribution > remaining) {
            throw JobException.sharedTypeUnitsExceeded(
              unitType: typeName,
              remaining: remaining < 0 ? 0 : remaining,
            );
          }
        }

        final invoiceDeliveryAmount = job.sharedInvoiceDeliveryAmount;
        final deliveryShare = job.charges?.deliveryAmount ?? 0;
        if (invoiceDeliveryAmount > 0) {
          if (job.sharedDeliveryTeamCount <= 0) {
            throw JobException.sharedDeliverySplitInvalid();
          }
          final consumedDelivery = existingSharedJobs.fold<double>(
            0,
            (total, entry) => total + (entry.charges?.deliveryAmount ?? 0),
          );
          final remainingDelivery = invoiceDeliveryAmount - consumedDelivery;
          if (deliveryShare - remainingDelivery > 0.01) {
            throw JobException.sharedUnitsExceeded(
              remaining: remainingDelivery <= 0 ? 0 : remainingDelivery.floor(),
            );
          }
        }
      }

      final data = job.toFirestore();
      data['invoiceNumber'] = normalizedInvoice;
      if (job.isSharedInstall) {
        data['sharedInstallGroupKey'] = normalizedGroupKey.isNotEmpty
            ? normalizedGroupKey
            : '${(job.companyId.isEmpty ? 'no-company' : job.companyId).toLowerCase()}-$normalizedInvoice';
      }
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
      if (e.code == 'failed-precondition') {
        throw const JobException(
          'job_backend_sync_in_progress',
          'Backend update is still syncing. Please retry in a minute.',
          'بیک اینڈ اپڈیٹ ابھی سنک ہو رہی ہے۔ ایک منٹ بعد دوبارہ کوشش کریں۔',
          'تحديث الخادم ما زال قيد المزامنة. حاول مرة أخرى بعد دقيقة.',
        );
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw NetworkException.syncFailed();
      }
      throw JobException.saveFailed();
    } on JobException {
      rethrow;
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
          final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
          final ref = _jobsRef.doc(_safeImportDocId(job));
          final data = job
              .copyWith(invoiceNumber: normalizedInvoice)
              .toFirestore();
          data['date'] ??= FieldValue.serverTimestamp();
          data['submittedAt'] ??= FieldValue.serverTimestamp();
          batch.set(ref, data);
          imported++;
        }
        await batch.commit();
      }
      return imported;
    } on FirebaseException catch (e) {
      debugPrint('importJobs FirebaseException: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw const JobException(
          'job_import_permission_denied',
          'You do not have permission to import jobs. Contact your admin.',
          'آپ کو jobs درآمد کرنے کی اجازت نہیں۔ اپنے ایڈمن سے رابطہ کریں۔',
          'ليس لديك إذن لاستيراد الوظائف. تواصل مع المسؤول.',
        );
      }
      if (e.code == 'failed-precondition') {
        throw const JobException(
          'job_backend_sync_in_progress',
          'Backend update is still syncing. Please retry in a minute.',
          'بیک اینڈ اپڈیٹ ابھی سنک ہو رہی ہے۔ ایک منٹ بعد دوبارہ کوشش کریں۔',
          'تحديث الخادم ما زال قيد المزامنة. حاول مرة أخرى بعد دقيقة.',
        );
      }
      throw JobException.saveFailed();
    } catch (e) {
      debugPrint('importJobs unknown error: $e');
      throw JobException.saveFailed();
    }
  }
}
