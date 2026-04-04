import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';
import 'package:ac_techs/features/settings/data/period_lock_guard.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(firestore: FirebaseFirestore.instance);
});

class JobRepository {
  JobRepository({required this.firestore});

  final FirebaseFirestore firestore;
  static const String _sharedBracketType = 'Bracket';

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      firestore.collection(AppConstants.jobsCollection);

  CollectionReference<Map<String, dynamic>> get _sharedAggregatesRef =>
      firestore.collection(AppConstants.sharedInstallAggregatesCollection);

  PeriodLockGuard get _periodLockGuard => PeriodLockGuard(firestore: firestore);

  Future<
    ({
      List<JobModel> jobs,
      DocumentSnapshot<Map<String, dynamic>>? cursor,
      bool hasMore,
    })
  >
  fetchAdminJobsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _jobsRef
        .orderBy('submittedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    return (
      jobs: snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
      cursor: snap.docs.isEmpty ? startAfter : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  Future<List<JobModel>> fetchAllAdminJobs() async {
    final snap = await _jobsRef.orderBy('date', descending: true).get();
    return snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
  }

  Future<AdminJobSummary> fetchAdminJobSummary() async {
    final jobs = await fetchAllAdminJobs();
    return AdminJobSummary.fromJobs(jobs);
  }

  Future<List<ApprovalHistoryEntry>> fetchJobHistory(
    String jobId, {
    int limit = 10,
  }) async {
    final snap = await _jobsRef
        .doc(jobId)
        .collection('history')
        .orderBy('changedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  int _unitsForType(JobModel job, String type) => job.acUnits
      .where((unit) => unit.type == type)
      .fold(0, (total, unit) => total + unit.quantity);

  int _bracketCount(JobModel job) => job.charges?.bracketCount ?? 0;

  String _safeImportDocId(JobModel job) {
    final techId = job.techId.trim().toLowerCase();
    final companyId = job.companyId.trim().toLowerCase();
    final invoice = InvoiceUtils.normalize(job.invoiceNumber).toLowerCase();
    final safeInvoice = invoice.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final safeTechId = techId.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final safeCompanyId = companyId.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final invoiceToken = safeInvoice.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : safeInvoice;
    final scoped = 'inv_${safeTechId}_${safeCompanyId}_$invoiceToken';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }

  String _sharedAggregateDocId(String groupKey) {
    final safe = groupKey.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final scoped =
        'shared_${safe.isEmpty ? DateTime.now().millisecondsSinceEpoch : safe}';
    return scoped.length > 140 ? scoped.substring(0, 140) : scoped;
  }

  int _readAggregateInt(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toInt() ?? 0;
  }

  void _ensureMutableJobStatus(String status) {
    if (status == JobStatus.approved.name) {
      throw JobException.approvedRecordLocked();
    }
  }

  double _readAggregateDouble(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toDouble() ?? 0;
  }

  void _validateSharedAggregateTotals(
    Map<String, dynamic> aggregate,
    JobModel job,
    String groupKey,
  ) {
    if (aggregate['groupKey'] != groupKey ||
        _readAggregateInt(aggregate, 'sharedInvoiceSplitUnits') !=
            job.sharedInvoiceSplitUnits ||
        _readAggregateInt(aggregate, 'sharedInvoiceWindowUnits') !=
            job.sharedInvoiceWindowUnits ||
        _readAggregateInt(aggregate, 'sharedInvoiceFreestandingUnits') !=
            job.sharedInvoiceFreestandingUnits ||
        _readAggregateInt(aggregate, 'sharedInvoiceBracketCount') !=
            job.sharedInvoiceBracketCount ||
        _readAggregateInt(aggregate, 'sharedDeliveryTeamCount') !=
            job.sharedDeliveryTeamCount ||
        (_readAggregateDouble(aggregate, 'sharedInvoiceDeliveryAmount') -
                    job.sharedInvoiceDeliveryAmount)
                .abs() >
            0.01) {
      throw JobException.sharedGroupMismatch();
    }
  }

  Map<String, dynamic> _sharedAggregateCreateData(
    JobModel job,
    String groupKey,
    int splitContribution,
    int windowContribution,
    int freestandingContribution,
    int bracketContribution,
    double deliveryContribution,
  ) {
    return {
      'groupKey': groupKey,
      'sharedInvoiceSplitUnits': job.sharedInvoiceSplitUnits,
      'sharedInvoiceWindowUnits': job.sharedInvoiceWindowUnits,
      'sharedInvoiceFreestandingUnits': job.sharedInvoiceFreestandingUnits,
      'sharedInvoiceBracketCount': job.sharedInvoiceBracketCount,
      'sharedDeliveryTeamCount': job.sharedDeliveryTeamCount,
      'sharedInvoiceDeliveryAmount': job.sharedInvoiceDeliveryAmount,
      'consumedSplitUnits': splitContribution,
      'consumedWindowUnits': windowContribution,
      'consumedFreestandingUnits': freestandingContribution,
      'consumedBracketCount': bracketContribution,
      'consumedDeliveryAmount': deliveryContribution,
      'createdBy': job.techId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _releaseSharedAggregateReservation(
    Transaction tx,
    JobModel job,
  ) async {
    if (!job.isSharedInstall || job.sharedInstallGroupKey.isEmpty) return;

    final aggregateRef = _sharedAggregatesRef.doc(
      _sharedAggregateDocId(job.sharedInstallGroupKey),
    );
    final aggregateSnap = await tx.get(aggregateRef);
    if (!aggregateSnap.exists) return;

    final aggregate = aggregateSnap.data() ?? <String, dynamic>{};
    final nextConsumedSplitUnits =
        (_readAggregateInt(aggregate, 'consumedSplitUnits') -
                _unitsForType(job, AppConstants.unitTypeSplitAc))
            .clamp(0, 1 << 31);
    final nextConsumedWindowUnits =
        (_readAggregateInt(aggregate, 'consumedWindowUnits') -
                _unitsForType(job, AppConstants.unitTypeWindowAc))
            .clamp(0, 1 << 31);
    final nextConsumedFreestandingUnits =
        (_readAggregateInt(aggregate, 'consumedFreestandingUnits') -
                _unitsForType(job, AppConstants.unitTypeFreestandingAc))
            .clamp(0, 1 << 31);
    final nextConsumedBracketCount =
        (_readAggregateInt(aggregate, 'consumedBracketCount') -
                _bracketCount(job))
            .clamp(0, 1 << 31);
    final nextConsumedDeliveryAmount =
        (_readAggregateDouble(aggregate, 'consumedDeliveryAmount') -
                (job.charges?.deliveryAmount ?? 0))
            .clamp(0, double.infinity);

    tx.update(aggregateRef, {
      'consumedSplitUnits': nextConsumedSplitUnits,
      'consumedWindowUnits': nextConsumedWindowUnits,
      'consumedFreestandingUnits': nextConsumedFreestandingUnits,
      'consumedBracketCount': nextConsumedBracketCount,
      'consumedDeliveryAmount': nextConsumedDeliveryAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitJob(JobModel job) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(job.date ?? DateTime.now());
      final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
      final duplicateSnap = await _jobsRef
          .where('techId', isEqualTo: job.techId)
          .where('companyId', isEqualTo: job.companyId)
          .where('invoiceNumber', isEqualTo: normalizedInvoice)
          .limit(1)
          .get();
      if (duplicateSnap.docs.isNotEmpty) {
        throw JobException.duplicateInvoice();
      }

      final normalizedGroupKey = job.sharedInstallGroupKey.isEmpty
          ? ''
          : InvoiceUtils.normalize(job.sharedInstallGroupKey).toLowerCase();
      final normalizedInvoiceKey = normalizedInvoice.toLowerCase();
      final resolvedGroupKey = normalizedGroupKey.isNotEmpty
          ? normalizedGroupKey
          : '${(job.companyId.isEmpty ? 'no-company' : job.companyId).toLowerCase()}-$normalizedInvoiceKey';

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
          (
            _sharedBracketType,
            _bracketCount(job),
            job.sharedInvoiceBracketCount,
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
        final invoiceDeliveryAmount = job.sharedInvoiceDeliveryAmount;
        final deliveryShare = job.charges?.deliveryAmount ?? 0;
        if (deliveryShare > 0 && invoiceDeliveryAmount <= 0) {
          throw JobException.sharedUnitsExceeded(remaining: 0);
        }
        if (invoiceDeliveryAmount > 0) {
          if (job.sharedDeliveryTeamCount <= 0) {
            throw JobException.sharedDeliverySplitInvalid();
          }
        }

        final data = job.toFirestore();
        data['invoiceNumber'] = normalizedInvoice;
        data['sharedInstallGroupKey'] = resolvedGroupKey;
        data['date'] ??= FieldValue.serverTimestamp();
        data['submittedAt'] ??= FieldValue.serverTimestamp();

        final newJobRef = _jobsRef.doc();
        final aggregateRef = _sharedAggregatesRef.doc(
          _sharedAggregateDocId(resolvedGroupKey),
        );

        await firestore.runTransaction((tx) async {
          final aggregateSnap = await tx.get(aggregateRef);
          var consumedSplitUnits = 0;
          var consumedWindowUnits = 0;
          var consumedFreestandingUnits = 0;
          var consumedBracketCount = 0;
          var consumedDeliveryAmount = 0.0;

          if (aggregateSnap.exists) {
            final aggregate = aggregateSnap.data() ?? <String, dynamic>{};
            _validateSharedAggregateTotals(aggregate, job, resolvedGroupKey);
            consumedSplitUnits = _readAggregateInt(
              aggregate,
              'consumedSplitUnits',
            );
            consumedWindowUnits = _readAggregateInt(
              aggregate,
              'consumedWindowUnits',
            );
            consumedFreestandingUnits = _readAggregateInt(
              aggregate,
              'consumedFreestandingUnits',
            );
            consumedBracketCount = _readAggregateInt(
              aggregate,
              'consumedBracketCount',
            );
            consumedDeliveryAmount = _readAggregateDouble(
              aggregate,
              'consumedDeliveryAmount',
            );
          }

          for (final typeLimit in typeLimits) {
            final typeName = typeLimit.$1;
            final contribution = typeLimit.$2;
            final totalAllowed = typeLimit.$3;
            if (contribution <= 0) continue;
            final consumed = switch (typeName) {
              AppConstants.unitTypeSplitAc => consumedSplitUnits,
              AppConstants.unitTypeWindowAc => consumedWindowUnits,
              AppConstants.unitTypeFreestandingAc => consumedFreestandingUnits,
              _sharedBracketType => consumedBracketCount,
              _ => 0,
            };
            final remaining = totalAllowed - consumed;
            if (contribution > remaining) {
              throw JobException.sharedTypeUnitsExceeded(
                unitType: typeName,
                remaining: remaining < 0 ? 0 : remaining,
              );
            }
          }

          if (invoiceDeliveryAmount > 0) {
            final remainingDelivery =
                invoiceDeliveryAmount - consumedDeliveryAmount;
            if (deliveryShare - remainingDelivery > 0.01) {
              throw JobException.sharedUnitsExceeded(
                remaining: remainingDelivery <= 0
                    ? 0
                    : remainingDelivery.floor(),
              );
            }
          }

          final nextConsumedSplitUnits = consumedSplitUnits + splitContribution;
          final nextConsumedWindowUnits =
              consumedWindowUnits + windowContribution;
          final nextConsumedFreestandingUnits =
              consumedFreestandingUnits + freestandingContribution;
          final nextConsumedBracketCount =
              consumedBracketCount + _bracketCount(job);
          final nextConsumedDeliveryAmount =
              consumedDeliveryAmount + deliveryShare;

          if (aggregateSnap.exists) {
            tx.update(aggregateRef, {
              'consumedSplitUnits': nextConsumedSplitUnits,
              'consumedWindowUnits': nextConsumedWindowUnits,
              'consumedFreestandingUnits': nextConsumedFreestandingUnits,
              'consumedBracketCount': nextConsumedBracketCount,
              'consumedDeliveryAmount': nextConsumedDeliveryAmount,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            tx.set(
              aggregateRef,
              _sharedAggregateCreateData(
                job,
                resolvedGroupKey,
                splitContribution,
                windowContribution,
                freestandingContribution,
                _bracketCount(job),
                deliveryShare,
              ),
            );
          }

          tx.set(newJobRef, data);
        });
        return;
      }

      final data = job.toFirestore();
      data['invoiceNumber'] = normalizedInvoice;
      if (job.isSharedInstall) {
        data['sharedInstallGroupKey'] = resolvedGroupKey;
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
        throw JobException.permissionDenied();
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
      await _periodLockGuard.ensureUnlockedDocument(_jobsRef.doc(jobId));
      await firestore.runTransaction((tx) async {
        final snap = await tx.get(_jobsRef.doc(jobId));
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        _ensureMutableJobStatus(prevStatus);
        tx.update(_jobsRef.doc(jobId), {
          'status': 'approved',
          'approvedBy': adminUid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_jobsRef.doc(jobId).collection('history').doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'approved',
        });
      });
    } on JobException {
      rethrow;
    } on PeriodException {
      rethrow;
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
      await _periodLockGuard.ensureUnlockedDocument(_jobsRef.doc(jobId));
      await firestore.runTransaction((tx) async {
        final snap = await tx.get(_jobsRef.doc(jobId));
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        _ensureMutableJobStatus(prevStatus);
        final job = JobModel.fromFirestore(snap);

        if (job.isSharedInstall && prevStatus != 'rejected') {
          await _releaseSharedAggregateReservation(tx, job);
        }

        tx.update(_jobsRef.doc(jobId), {
          'status': 'rejected',
          'approvedBy': adminUid,
          'adminNote': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_jobsRef.doc(jobId).collection('history').doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'rejected',
          'reason': reason,
        });
      });
    } on JobException {
      rethrow;
    } on PeriodException {
      rethrow;
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
      for (final id in jobIds) {
        await firestore.runTransaction((tx) async {
          final jobRef = _jobsRef.doc(id);
          final snap = await tx.get(jobRef);
          if (!snap.exists) return;

          final prevStatus = snap.data()?['status'] as String? ?? 'pending';
          _ensureMutableJobStatus(prevStatus);
          tx.update(jobRef, {
            'status': 'approved',
            'approvedBy': adminUid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });
          tx.set(jobRef.collection('history').doc(), {
            'changedBy': adminUid,
            'changedAt': FieldValue.serverTimestamp(),
            'previousStatus': prevStatus,
            'newStatus': 'approved',
          });
        });
      }
    } on JobException {
      rethrow;
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

  Stream<List<JobModel>> approvedSharedInstalls() {
    return _jobsRef
        .where('status', isEqualTo: 'approved')
        .where('isSharedInstall', isEqualTo: true)
        .orderBy('submittedAt', descending: true)
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

  Future<List<JobModel>> jobsForAdminFilter({
    DateTime? start,
    DateTime? end,
    String? techId,
  }) async {
    Query<Map<String, dynamic>> query = _jobsRef;

    if (techId != null && techId.trim().isNotEmpty) {
      query = query.where('techId', isEqualTo: techId.trim());
    }
    if (start != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }
    if (end != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    final snap = await query.orderBy('date', descending: true).get();
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
