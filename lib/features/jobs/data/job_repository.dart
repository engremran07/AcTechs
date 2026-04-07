import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:collection';
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
  static const String _invoiceReuseModeShared = 'shared';
  static const String _invoiceReuseModeSolo = 'solo';
  static const Set<String> _unsupportedSharedUnitTypes = {
    AppConstants.unitTypeCassetteAc,
    AppConstants.unitTypeUninstallOld,
  };

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      firestore.collection(AppConstants.jobsCollection);

  CollectionReference<Map<String, dynamic>> get _sharedAggregatesRef =>
      firestore.collection(AppConstants.sharedInstallAggregatesCollection);

  CollectionReference<Map<String, dynamic>> get _invoiceClaimsRef =>
      firestore.collection(AppConstants.invoiceClaimsCollection);

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

  Future<List<JobModel>> _fetchAdminJobsPaged({int pageSize = 200}) async {
    final jobs = <JobModel>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var hasMore = true;

    while (hasMore) {
      final page = await fetchAdminJobsPage(
        startAfter: cursor,
        limit: pageSize,
      );
      jobs.addAll(page.jobs);
      cursor = page.cursor;
      hasMore = page.hasMore && page.jobs.isNotEmpty;
    }

    return jobs;
  }

  Future<List<JobModel>> fetchAllAdminJobs() async {
    return _fetchAdminJobsPaged();
  }

  Future<AdminJobSummary> fetchAdminJobSummary() async {
    final jobs = await _fetchAdminJobsPaged();
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

  Future<Map<String, List<String>>> fetchSharedInstallerNamesByGroup(
    Iterable<String> groupKeys,
  ) async {
    final normalizedKeys = groupKeys
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedKeys.isEmpty) {
      return const <String, List<String>>{};
    }

    try {
      final namesByGroup = <String, LinkedHashSet<String>>{};

      for (var start = 0; start < normalizedKeys.length; start += 10) {
        final end = (start + 10 < normalizedKeys.length)
            ? start + 10
            : normalizedKeys.length;
        final chunk = normalizedKeys.sublist(start, end);
        final snap = await _jobsRef
            .where('sharedInstallGroupKey', whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          final job = JobModel.fromFirestore(doc);
          final groupKey = job.sharedInstallGroupKey.trim();
          final techName = job.techName.trim();
          if (groupKey.isEmpty || techName.isEmpty) {
            continue;
          }
          (namesByGroup[groupKey] ??= LinkedHashSet<String>()).add(techName);
        }
      }

      return namesByGroup.map(
        (groupKey, names) => MapEntry(groupKey, names.toList(growable: false)),
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'fetchSharedInstallerNamesByGroup failed: ${error.code} ${error.message}',
      );
      Error.throwWithStackTrace(
        error.code == 'permission-denied'
            ? JobException.permissionDenied()
            : JobException.saveFailed(),
        stackTrace,
      );
    }
  }

  int _unitsForType(JobModel job, String type) => job.acUnits
      .where((unit) => unit.type == type)
      .fold(0, (total, unit) => total + unit.quantity);

  void _validateSupportedSharedInstallUnits(JobModel job) {
    if (!job.isSharedInstall) return;

    for (final unit in job.acUnits) {
      if (unit.quantity <= 0) continue;
      if (_unsupportedSharedUnitTypes.contains(unit.type)) {
        throw JobException.sharedUnsupportedUnitType(unitType: unit.type);
      }
    }
  }

  int _bracketCount(JobModel job) => job.isSharedInstall
      ? (job.techBracketShare > 0
            ? job.techBracketShare
            : job.effectiveBracketCount)
      : job.effectiveBracketCount;

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

  String _invoiceClaimDocId(String normalizedInvoice) {
    return InvoiceUtils.invoiceClaimDocumentId(normalizedInvoice);
  }

  String _invoiceReuseModeFor(JobModel job) =>
      job.isSharedInstall ? _invoiceReuseModeShared : _invoiceReuseModeSolo;

  Future<Map<String, dynamic>?> _fetchInvoiceClaim(
    String normalizedInvoice,
  ) async {
    final claimSnap = await _invoiceClaimsRef.doc(
      _invoiceClaimDocId(normalizedInvoice),
    ).get();
    return claimSnap.data();
  }

  void _validateInvoiceClaimReuse(
    JobModel submittedJob,
    Map<String, dynamic>? existingClaim,
  ) {
    if (existingClaim == null) {
      return;
    }

    final claimedCompanyId =
        (existingClaim['companyId'] as String? ?? '').trim();
    final reuseMode = (existingClaim['reuseMode'] as String? ?? '').trim();

    if (claimedCompanyId.isNotEmpty &&
        claimedCompanyId != submittedJob.companyId) {
      throw JobException.duplicateInvoice();
    }

    if (!submittedJob.isSharedInstall || reuseMode != _invoiceReuseModeShared) {
      throw JobException.duplicateInvoice();
    }
  }

  int _readInvoiceClaimCount(Map<String, dynamic> data) {
    return (data['activeJobCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> _reserveInvoiceClaim(
    Transaction tx,
    JobModel job,
    String normalizedInvoice,
  ) async {
    final claimRef = _invoiceClaimsRef.doc(
      _invoiceClaimDocId(normalizedInvoice),
    );
    final claimSnap = await tx.get(claimRef);
    final requestedMode = _invoiceReuseModeFor(job);

    if (!claimSnap.exists) {
      tx.set(claimRef, {
        'invoiceNumber': normalizedInvoice,
        'companyId': job.companyId,
        'companyName': job.companyName,
        'reuseMode': requestedMode,
        'activeJobCount': 1,
        'createdBy': job.techId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final claim = claimSnap.data() ?? <String, dynamic>{};
    final claimedCompanyId = (claim['companyId'] as String? ?? '').trim();
    final reuseMode = (claim['reuseMode'] as String? ?? '').trim();

    if (claimedCompanyId != job.companyId) {
      throw JobException.duplicateInvoice();
    }
    if (requestedMode != _invoiceReuseModeShared ||
        reuseMode != _invoiceReuseModeShared) {
      throw JobException.duplicateInvoice();
    }

    tx.update(claimRef, {
      'activeJobCount': _readInvoiceClaimCount(claim) + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _releaseInvoiceClaimFromSnapshot(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> claimRef,
    DocumentSnapshot<Map<String, dynamic>> claimSnap,
  ) {
    if (!claimSnap.exists) return;

    final claim = claimSnap.data() ?? <String, dynamic>{};
    final nextCount = _readInvoiceClaimCount(claim) - 1;
    if (nextCount <= 0) {
      tx.delete(claimRef);
      return;
    }

    tx.update(claimRef, {
      'activeJobCount': nextCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
        _readAggregateInt(aggregate, 'sharedInvoiceUninstallSplitUnits') !=
            job.sharedInvoiceUninstallSplitUnits ||
        _readAggregateInt(aggregate, 'sharedInvoiceUninstallWindowUnits') !=
            job.sharedInvoiceUninstallWindowUnits ||
        _readAggregateInt(
              aggregate,
              'sharedInvoiceUninstallFreestandingUnits',
            ) !=
            job.sharedInvoiceUninstallFreestandingUnits ||
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
    int uninstallSplitContribution,
    int uninstallWindowContribution,
    int uninstallFreestandingContribution,
    int bracketContribution,
    double deliveryContribution,
  ) {
    return {
      'groupKey': groupKey,
      'sharedInvoiceSplitUnits': job.sharedInvoiceSplitUnits,
      'sharedInvoiceWindowUnits': job.sharedInvoiceWindowUnits,
      'sharedInvoiceFreestandingUnits': job.sharedInvoiceFreestandingUnits,
      'sharedInvoiceUninstallSplitUnits': job.sharedInvoiceUninstallSplitUnits,
      'sharedInvoiceUninstallWindowUnits':
          job.sharedInvoiceUninstallWindowUnits,
      'sharedInvoiceUninstallFreestandingUnits':
          job.sharedInvoiceUninstallFreestandingUnits,
      'sharedInvoiceBracketCount': job.sharedInvoiceBracketCount,
      'sharedDeliveryTeamCount': job.sharedDeliveryTeamCount,
      'sharedInvoiceDeliveryAmount': job.sharedInvoiceDeliveryAmount,
      'consumedSplitUnits': splitContribution,
      'consumedWindowUnits': windowContribution,
      'consumedFreestandingUnits': freestandingContribution,
      'consumedUninstallSplitUnits': uninstallSplitContribution,
      'consumedUninstallWindowUnits': uninstallWindowContribution,
      'consumedUninstallFreestandingUnits': uninstallFreestandingContribution,
      'consumedBracketCount': bracketContribution,
      'consumedDeliveryAmount': deliveryContribution,
      'createdBy': job.techId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _releaseSharedAggregateReservation(
    Transaction tx,
    JobModel job, {
    DocumentSnapshot<Map<String, dynamic>>? aggregateSnap,
  }) async {
    if (!job.isSharedInstall || job.sharedInstallGroupKey.isEmpty) return;

    final aggregateRef = _sharedAggregatesRef.doc(
      _sharedAggregateDocId(job.sharedInstallGroupKey),
    );
    final resolvedAggregateSnap = aggregateSnap ?? await tx.get(aggregateRef);
    if (!resolvedAggregateSnap.exists) return;

    final aggregate = resolvedAggregateSnap.data() ?? <String, dynamic>{};
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
    final nextConsumedUninstallSplitUnits =
        (_readAggregateInt(aggregate, 'consumedUninstallSplitUnits') -
                _unitsForType(job, AppConstants.unitTypeUninstallSplit))
            .clamp(0, 1 << 31);
    final nextConsumedUninstallWindowUnits =
        (_readAggregateInt(aggregate, 'consumedUninstallWindowUnits') -
                _unitsForType(job, AppConstants.unitTypeUninstallWindow))
            .clamp(0, 1 << 31);
    final nextConsumedUninstallFreestandingUnits =
        (_readAggregateInt(aggregate, 'consumedUninstallFreestandingUnits') -
                _unitsForType(job, AppConstants.unitTypeUninstallFreestanding))
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
      'consumedUninstallSplitUnits': nextConsumedUninstallSplitUnits,
      'consumedUninstallWindowUnits': nextConsumedUninstallWindowUnits,
      'consumedUninstallFreestandingUnits':
          nextConsumedUninstallFreestandingUnits,
      'consumedBracketCount': nextConsumedBracketCount,
      'consumedDeliveryAmount': nextConsumedDeliveryAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<JobStatus> submitJob(
    JobModel job, {
    DateTime? lockedBeforeDate,
  }) async {
    try {
      await _periodLockGuard.ensureUnlockedDate(
        job.date ?? DateTime.now(),
        cachedLockedBefore: lockedBeforeDate,
      );
      final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
      final existingClaim = await _fetchInvoiceClaim(normalizedInvoice);
      _validateInvoiceClaimReuse(job, existingClaim);

      final resolvedStatus = job.status;

      final normalizedGroupKey = job.sharedInstallGroupKey.isEmpty
          ? ''
          : InvoiceUtils.normalize(job.sharedInstallGroupKey).toLowerCase();
      final resolvedGroupKey = normalizedGroupKey.isNotEmpty
          ? normalizedGroupKey
          : InvoiceUtils.sharedInstallGroupKey(
              companyId: job.companyId,
              invoiceNumber: normalizedInvoice,
            );

      if (job.isSharedInstall) {
        _validateSupportedSharedInstallUnits(job);

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
        final uninstallSplitContribution = _unitsForType(
          job,
          AppConstants.unitTypeUninstallSplit,
        );
        final uninstallWindowContribution = _unitsForType(
          job,
          AppConstants.unitTypeUninstallWindow,
        );
        final uninstallFreestandingContribution = _unitsForType(
          job,
          AppConstants.unitTypeUninstallFreestanding,
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
            AppConstants.unitTypeUninstallSplit,
            uninstallSplitContribution,
            job.sharedInvoiceUninstallSplitUnits,
          ),
          (
            AppConstants.unitTypeUninstallWindow,
            uninstallWindowContribution,
            job.sharedInvoiceUninstallWindowUnits,
          ),
          (
            AppConstants.unitTypeUninstallFreestanding,
            uninstallFreestandingContribution,
            job.sharedInvoiceUninstallFreestandingUnits,
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
        data['status'] = resolvedStatus.name;
        data['date'] ??= FieldValue.serverTimestamp();
        data['submittedAt'] ??= FieldValue.serverTimestamp();

        final newJobRef = _jobsRef.doc();
        final aggregateRef = _sharedAggregatesRef.doc(
          _sharedAggregateDocId(resolvedGroupKey),
        );

        await firestore.runTransaction((tx) async {
          final aggregateSnap = await tx.get(aggregateRef);
          await _reserveInvoiceClaim(tx, job, normalizedInvoice);
          var consumedSplitUnits = 0;
          var consumedWindowUnits = 0;
          var consumedFreestandingUnits = 0;
          var consumedUninstallSplitUnits = 0;
          var consumedUninstallWindowUnits = 0;
          var consumedUninstallFreestandingUnits = 0;
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
            consumedUninstallSplitUnits = _readAggregateInt(
              aggregate,
              'consumedUninstallSplitUnits',
            );
            consumedUninstallWindowUnits = _readAggregateInt(
              aggregate,
              'consumedUninstallWindowUnits',
            );
            consumedUninstallFreestandingUnits = _readAggregateInt(
              aggregate,
              'consumedUninstallFreestandingUnits',
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
              AppConstants.unitTypeUninstallSplit =>
                consumedUninstallSplitUnits,
              AppConstants.unitTypeUninstallWindow =>
                consumedUninstallWindowUnits,
              AppConstants.unitTypeUninstallFreestanding =>
                consumedUninstallFreestandingUnits,
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
          final nextConsumedUninstallSplitUnits =
              consumedUninstallSplitUnits + uninstallSplitContribution;
          final nextConsumedUninstallWindowUnits =
              consumedUninstallWindowUnits + uninstallWindowContribution;
          final nextConsumedUninstallFreestandingUnits =
              consumedUninstallFreestandingUnits +
              uninstallFreestandingContribution;
          final nextConsumedBracketCount =
              consumedBracketCount + _bracketCount(job);
          final nextConsumedDeliveryAmount =
              consumedDeliveryAmount + deliveryShare;

          if (aggregateSnap.exists) {
            tx.update(aggregateRef, {
              'consumedSplitUnits': nextConsumedSplitUnits,
              'consumedWindowUnits': nextConsumedWindowUnits,
              'consumedFreestandingUnits': nextConsumedFreestandingUnits,
              'consumedUninstallSplitUnits': nextConsumedUninstallSplitUnits,
              'consumedUninstallWindowUnits': nextConsumedUninstallWindowUnits,
              'consumedUninstallFreestandingUnits':
                  nextConsumedUninstallFreestandingUnits,
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
                uninstallSplitContribution,
                uninstallWindowContribution,
                uninstallFreestandingContribution,
                _bracketCount(job),
                deliveryShare,
              ),
            );
          }

          tx.set(newJobRef, data);
        });
        return resolvedStatus;
      }

      final data = job.toFirestore();
      data['invoiceNumber'] = normalizedInvoice;
      data['status'] = resolvedStatus.name;
      if (job.isSharedInstall) {
        data['sharedInstallGroupKey'] = resolvedGroupKey;
      }
      data['date'] ??= FieldValue.serverTimestamp();
      data['submittedAt'] ??= FieldValue.serverTimestamp();

      await firestore.runTransaction((tx) async {
        final newJobRef = _jobsRef.doc();
        await _reserveInvoiceClaim(tx, job, normalizedInvoice);
        tx.set(newJobRef, data);
      });
      return resolvedStatus;
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

  Future<JobStatus> updateTechnicianJob(
    JobModel job, {
    required ApprovalConfig? approvalConfig,
  }) async {
    if (job.id.trim().isEmpty) {
      throw JobException.saveFailed();
    }

    try {
      final jobRef = _jobsRef.doc(job.id);
      final existingSnap = await jobRef.get();
      if (!existingSnap.exists) {
        throw JobException.saveFailed();
      }

      final existing = JobModel.fromFirestore(existingSnap);
      await _periodLockGuard.ensureUnlockedDate(
        existing.date ?? DateTime.now(),
        cachedLockedBefore: approvalConfig?.lockedBeforeDate,
      );
      await _periodLockGuard.ensureUnlockedDate(
        job.date ?? DateTime.now(),
        cachedLockedBefore: approvalConfig?.lockedBeforeDate,
      );

      if (existing.techId != job.techId) {
        throw JobException.permissionDenied();
      }
      if (existing.isSettlementAwaitingTechnician ||
          existing.isSettlementLocked) {
        throw JobException.settlementLocked();
      }

      final requiresApproval =
          ((job.isSharedInstall
              ? approvalConfig?.sharedJobApprovalRequired
              : approvalConfig?.jobApprovalRequired) ??
          true);
      final nextStatus = requiresApproval ? JobStatus.pending : JobStatus.approved;

      final canEditDirectApproved =
          existing.isApproved &&
          !requiresApproval &&
          existing.isUnpaid &&
          !existing.isSharedInstall &&
          !job.isSharedInstall;
      final canEditPending = existing.isPending;
      final canResubmitRejected = existing.isRejected;

      if (!canEditDirectApproved && !canEditPending && !canResubmitRejected) {
        throw JobException.jobNotEditable();
      }

      final updated = job.copyWith(
        status: nextStatus,
        adminNote: '',
        approvedBy: null,
        reviewedAt: null,
        settlementStatus: JobSettlementStatus.unpaid,
        settlementBatchId: '',
        settlementAdminNote: '',
        settlementTechnicianComment: '',
        settlementRequestedBy: '',
        settlementRequestedAt: null,
        settlementRespondedAt: null,
        settlementCorrectedAt: null,
        settlementRound: 0,
      );

      final normalizedInvoice = InvoiceUtils.normalize(updated.invoiceNumber);
      final resolvedGroupKey = updated.isSharedInstall
          ? (updated.sharedInstallGroupKey.trim().isEmpty
                ? InvoiceUtils.sharedInstallGroupKey(
                    companyId: updated.companyId,
                    invoiceNumber: normalizedInvoice,
                  )
                : InvoiceUtils.normalize(updated.sharedInstallGroupKey)
                      .toLowerCase())
          : '';

      final data = updated.toFirestore();
      data['invoiceNumber'] = normalizedInvoice;
      data['status'] = nextStatus.name;
      data['sharedInstallGroupKey'] = resolvedGroupKey;

      if (canEditDirectApproved || canEditPending) {
        await jobRef.update(data);
        await jobRef.collection('history').add({
          'changedBy': updated.techId,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': existing.status.name,
          'newStatus': nextStatus.name,
          'flow': 'approval',
          'action': 'technician_edit',
        });
        return nextStatus;
      }

      final existingClaim = await _fetchInvoiceClaim(normalizedInvoice);
      _validateInvoiceClaimReuse(updated, existingClaim);

      if (!updated.isSharedInstall) {
        await firestore.runTransaction((tx) async {
          await _reserveInvoiceClaim(tx, updated, normalizedInvoice);
          tx.update(jobRef, data);
          tx.set(jobRef.collection('history').doc(), {
            'changedBy': updated.techId,
            'changedAt': FieldValue.serverTimestamp(),
            'previousStatus': existing.status.name,
            'newStatus': nextStatus.name,
            'flow': 'approval',
            'action': 'technician_resubmit',
          });
        });
        return nextStatus;
      }

      _validateSupportedSharedInstallUnits(updated);
      final splitContribution = _unitsForType(updated, AppConstants.unitTypeSplitAc);
      final windowContribution = _unitsForType(updated, AppConstants.unitTypeWindowAc);
      final freestandingContribution = _unitsForType(
        updated,
        AppConstants.unitTypeFreestandingAc,
      );
      final uninstallSplitContribution = _unitsForType(
        updated,
        AppConstants.unitTypeUninstallSplit,
      );
      final uninstallWindowContribution = _unitsForType(
        updated,
        AppConstants.unitTypeUninstallWindow,
      );
      final uninstallFreestandingContribution = _unitsForType(
        updated,
        AppConstants.unitTypeUninstallFreestanding,
      );
      final deliveryShare = updated.charges?.deliveryAmount ?? 0;

      final typeLimits = <(String, int, int)>[
        (
          AppConstants.unitTypeSplitAc,
          splitContribution,
          updated.sharedInvoiceSplitUnits,
        ),
        (
          AppConstants.unitTypeWindowAc,
          windowContribution,
          updated.sharedInvoiceWindowUnits,
        ),
        (
          AppConstants.unitTypeFreestandingAc,
          freestandingContribution,
          updated.sharedInvoiceFreestandingUnits,
        ),
        (
          AppConstants.unitTypeUninstallSplit,
          uninstallSplitContribution,
          updated.sharedInvoiceUninstallSplitUnits,
        ),
        (
          AppConstants.unitTypeUninstallWindow,
          uninstallWindowContribution,
          updated.sharedInvoiceUninstallWindowUnits,
        ),
        (
          AppConstants.unitTypeUninstallFreestanding,
          uninstallFreestandingContribution,
          updated.sharedInvoiceUninstallFreestandingUnits,
        ),
        (_sharedBracketType, _bracketCount(updated), updated.sharedInvoiceBracketCount),
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

      await firestore.runTransaction((tx) async {
        final aggregateRef = _sharedAggregatesRef.doc(_sharedAggregateDocId(resolvedGroupKey));
        final aggregateSnap = await tx.get(aggregateRef);
        await _reserveInvoiceClaim(tx, updated, normalizedInvoice);

        var consumedSplitUnits = 0;
        var consumedWindowUnits = 0;
        var consumedFreestandingUnits = 0;
        var consumedUninstallSplitUnits = 0;
        var consumedUninstallWindowUnits = 0;
        var consumedUninstallFreestandingUnits = 0;
        var consumedBracketCount = 0;
        var consumedDeliveryAmount = 0.0;

        if (aggregateSnap.exists) {
          final aggregate = aggregateSnap.data() ?? <String, dynamic>{};
          _validateSharedAggregateTotals(aggregate, updated, resolvedGroupKey);
          consumedSplitUnits = _readAggregateInt(aggregate, 'consumedSplitUnits');
          consumedWindowUnits = _readAggregateInt(aggregate, 'consumedWindowUnits');
          consumedFreestandingUnits = _readAggregateInt(
            aggregate,
            'consumedFreestandingUnits',
          );
          consumedUninstallSplitUnits = _readAggregateInt(
            aggregate,
            'consumedUninstallSplitUnits',
          );
          consumedUninstallWindowUnits = _readAggregateInt(
            aggregate,
            'consumedUninstallWindowUnits',
          );
          consumedUninstallFreestandingUnits = _readAggregateInt(
            aggregate,
            'consumedUninstallFreestandingUnits',
          );
          consumedBracketCount = _readAggregateInt(aggregate, 'consumedBracketCount');
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
            AppConstants.unitTypeUninstallSplit => consumedUninstallSplitUnits,
            AppConstants.unitTypeUninstallWindow => consumedUninstallWindowUnits,
            AppConstants.unitTypeUninstallFreestanding =>
              consumedUninstallFreestandingUnits,
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

        if (updated.sharedInvoiceDeliveryAmount > 0) {
          final remainingDelivery = updated.sharedInvoiceDeliveryAmount - consumedDeliveryAmount;
          if (deliveryShare - remainingDelivery > 0.01) {
            throw JobException.sharedUnitsExceeded(
              remaining: remainingDelivery <= 0 ? 0 : remainingDelivery.floor(),
            );
          }
        }

        if (aggregateSnap.exists) {
          tx.update(aggregateRef, {
            'consumedSplitUnits': consumedSplitUnits + splitContribution,
            'consumedWindowUnits': consumedWindowUnits + windowContribution,
            'consumedFreestandingUnits':
                consumedFreestandingUnits + freestandingContribution,
            'consumedUninstallSplitUnits':
                consumedUninstallSplitUnits + uninstallSplitContribution,
            'consumedUninstallWindowUnits':
                consumedUninstallWindowUnits + uninstallWindowContribution,
            'consumedUninstallFreestandingUnits':
                consumedUninstallFreestandingUnits + uninstallFreestandingContribution,
            'consumedBracketCount': consumedBracketCount + _bracketCount(updated),
            'consumedDeliveryAmount': consumedDeliveryAmount + deliveryShare,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(
            aggregateRef,
            _sharedAggregateCreateData(
              updated,
              resolvedGroupKey,
              splitContribution,
              windowContribution,
              freestandingContribution,
              uninstallSplitContribution,
              uninstallWindowContribution,
              uninstallFreestandingContribution,
              _bracketCount(updated),
              deliveryShare,
            ),
          );
        }

        tx.update(jobRef, data);
        tx.set(jobRef.collection('history').doc(), {
          'changedBy': updated.techId,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': existing.status.name,
          'newStatus': nextStatus.name,
          'flow': 'approval',
          'action': 'technician_resubmit',
        });
      });

      return nextStatus;
    } on FirebaseException catch (e) {
      debugPrint('updateTechnicianJob FirebaseException: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw JobException.permissionDenied();
      }
      throw JobException.saveFailed();
    } on JobException {
      rethrow;
    } catch (e) {
      debugPrint('updateTechnicianJob unknown error: $e');
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
        final jobRef = _jobsRef.doc(jobId);
        final snap = await tx.get(jobRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        _ensureMutableJobStatus(prevStatus);
        final job = JobModel.fromFirestore(snap);

        final normalizedInvoice = InvoiceUtils.normalize(job.invoiceNumber);
        final claimRef = _invoiceClaimsRef.doc(
          _invoiceClaimDocId(normalizedInvoice),
        );
        final claimSnap = prevStatus != 'rejected'
            ? await tx.get(claimRef)
            : null;
        final aggregateRef = job.isSharedInstall && prevStatus != 'rejected'
            ? _sharedAggregatesRef.doc(
                _sharedAggregateDocId(job.sharedInstallGroupKey),
              )
            : null;
        final aggregateSnap = aggregateRef != null
            ? await tx.get(aggregateRef)
            : null;

        if (prevStatus != 'rejected' && claimSnap != null) {
          _releaseInvoiceClaimFromSnapshot(tx, claimRef, claimSnap);
        }
        if (job.isSharedInstall &&
            prevStatus != 'rejected' &&
            aggregateSnap != null) {
          await _releaseSharedAggregateReservation(
            tx,
            job,
            aggregateSnap: aggregateSnap,
          );
        }

        tx.update(jobRef, {
          'status': 'rejected',
          'approvedBy': adminUid,
          'adminNote': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(jobRef.collection('history').doc(), {
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

  Stream<List<JobModel>> settlementCandidates() {
    return _jobsRef
        .where('status', isEqualTo: JobStatus.approved.name)
        .where(
          'settlementStatus',
          whereIn: [
            JobSettlementStatus.unpaid.firestoreValue,
            JobSettlementStatus.correctionRequired.firestoreValue,
          ],
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<JobModel>> technicianSettlementInbox(String techId) {
    return _jobsRef
        .where('techId', isEqualTo: techId)
        .where(
          'settlementStatus',
          isEqualTo: JobSettlementStatus.awaitingTechnician.firestoreValue,
        )
        .orderBy('settlementRequestedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<JobModel>> settlementBatchJobs(String batchId) {
    return _jobsRef
        .where('settlementBatchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => JobModel.fromFirestore(doc)).toList(),
        );
  }

  Future<String> markJobsAsPaid(
    List<String> jobIds,
    String adminUid, {
    String adminNote = '',
  }) async {
    if (jobIds.isEmpty) {
      throw JobException.settlementBatchNotFound();
    }

    final batchId =
        'pay_${DateTime.now().millisecondsSinceEpoch}_${adminUid.substring(0, adminUid.length < 6 ? adminUid.length : 6)}';
    final snaps = await Future.wait(jobIds.map((id) => _jobsRef.doc(id).get()));
    final jobs = snaps.where((snap) => snap.exists).map(JobModel.fromFirestore).toList();
    if (jobs.isEmpty) {
      throw JobException.settlementBatchNotFound();
    }

    final techIds = jobs.map((job) => job.techId).toSet();
    if (techIds.length != 1) {
      throw JobException.saveFailed();
    }

    final batch = firestore.batch();
    for (final job in jobs) {
      if (!job.isApproved) {
        throw JobException.jobNotEditable();
      }
      if (!job.isUnpaid) {
        throw JobException.settlementAlreadyFinalized();
      }
      final ref = _jobsRef.doc(job.id);
      batch.update(ref, {
        'settlementStatus': JobSettlementStatus.awaitingTechnician.firestoreValue,
        'settlementBatchId': batchId,
        'settlementRound': 1,
        'settlementAdminNote': adminNote,
        'settlementTechnicianComment': '',
        'settlementRequestedBy': adminUid,
        'settlementRequestedAt': FieldValue.serverTimestamp(),
        'settlementRespondedAt': null,
        'settlementCorrectedAt': null,
      });
      batch.set(ref.collection('history').doc(), {
        'changedBy': adminUid,
        'changedAt': FieldValue.serverTimestamp(),
        'previousStatus': job.settlementStatus.firestoreValue,
        'newStatus': JobSettlementStatus.awaitingTechnician.firestoreValue,
        'flow': 'settlement',
        'action': 'mark_paid',
        'reason': adminNote,
      });
    }
    await batch.commit();
    return batchId;
  }

  Future<void> confirmSettlementBatch(String batchId, String techId) async {
    final snap = await _jobsRef.where('settlementBatchId', isEqualTo: batchId).get();
    final jobs = snap.docs.map(JobModel.fromFirestore).toList(growable: false);
    if (jobs.isEmpty) {
      throw JobException.settlementBatchNotFound();
    }

    final batch = firestore.batch();
    for (final job in jobs) {
      if (job.techId != techId) {
        throw JobException.permissionDenied();
      }
      if (!job.isSettlementAwaitingTechnician) {
        throw JobException.settlementAlreadyFinalized();
      }
      final ref = _jobsRef.doc(job.id);
      batch.update(ref, {
        'settlementStatus': JobSettlementStatus.confirmed.firestoreValue,
        'settlementRespondedAt': FieldValue.serverTimestamp(),
      });
      batch.set(ref.collection('history').doc(), {
        'changedBy': techId,
        'changedAt': FieldValue.serverTimestamp(),
        'previousStatus': job.settlementStatus.firestoreValue,
        'newStatus': JobSettlementStatus.confirmed.firestoreValue,
        'flow': 'settlement',
        'action': 'confirm_received',
      });
    }
    await batch.commit();
  }

  Future<void> rejectSettlementBatch(
    String batchId,
    String techId,
    String comment,
  ) async {
    final snap = await _jobsRef.where('settlementBatchId', isEqualTo: batchId).get();
    final jobs = snap.docs.map(JobModel.fromFirestore).toList(growable: false);
    if (jobs.isEmpty) {
      throw JobException.settlementBatchNotFound();
    }

    final currentRound = jobs.first.settlementRound;
    final nextStatus = currentRound >= 2
        ? JobSettlementStatus.disputedFinal
        : JobSettlementStatus.correctionRequired;

    final batch = firestore.batch();
    for (final job in jobs) {
      if (job.techId != techId) {
        throw JobException.permissionDenied();
      }
      if (!job.isSettlementAwaitingTechnician) {
        throw JobException.settlementAlreadyFinalized();
      }
      final ref = _jobsRef.doc(job.id);
      batch.update(ref, {
        'settlementStatus': nextStatus.firestoreValue,
        'settlementTechnicianComment': comment,
        'settlementRespondedAt': FieldValue.serverTimestamp(),
      });
      batch.set(ref.collection('history').doc(), {
        'changedBy': techId,
        'changedAt': FieldValue.serverTimestamp(),
        'previousStatus': job.settlementStatus.firestoreValue,
        'newStatus': nextStatus.firestoreValue,
        'flow': 'settlement',
        'action': 'reject_payment',
        'reason': comment,
      });
    }
    await batch.commit();
  }

  Future<void> resubmitSettlementBatch(
    String batchId,
    String adminUid, {
    String adminNote = '',
  }) async {
    final snap = await _jobsRef.where('settlementBatchId', isEqualTo: batchId).get();
    final jobs = snap.docs.map(JobModel.fromFirestore).toList(growable: false);
    if (jobs.isEmpty) {
      throw JobException.settlementBatchNotFound();
    }
    if (!jobs.every((job) => job.isSettlementCorrectionRequired)) {
      throw JobException.settlementAlreadyFinalized();
    }
    if (jobs.any((job) => job.settlementRound >= 2)) {
      throw JobException.settlementCorrectionCycleExceeded();
    }

    final batch = firestore.batch();
    for (final job in jobs) {
      final ref = _jobsRef.doc(job.id);
      batch.update(ref, {
        'settlementStatus': JobSettlementStatus.awaitingTechnician.firestoreValue,
        'settlementRound': 2,
        'settlementAdminNote': adminNote,
        'settlementRequestedBy': adminUid,
        'settlementRequestedAt': FieldValue.serverTimestamp(),
        'settlementCorrectedAt': FieldValue.serverTimestamp(),
      });
      batch.set(ref.collection('history').doc(), {
        'changedBy': adminUid,
        'changedAt': FieldValue.serverTimestamp(),
        'previousStatus': job.settlementStatus.firestoreValue,
        'newStatus': JobSettlementStatus.awaitingTechnician.firestoreValue,
        'flow': 'settlement',
        'action': 'resubmit_payment',
        'reason': adminNote,
      });
    }
    await batch.commit();
  }

  Future<void> bulkApproveJobs(List<String> jobIds, String adminUid) async {
    try {
      if (jobIds.isEmpty) return;
      const chunkSize = 100;
      for (var start = 0; start < jobIds.length; start += chunkSize) {
        final end = (start + chunkSize > jobIds.length)
            ? jobIds.length
            : start + chunkSize;
        final chunk = jobIds.sublist(start, end);
        final snaps = await Future.wait(
          chunk.map((id) => _jobsRef.doc(id).get()),
        );

        final batch = firestore.batch();
        for (final snap in snaps) {
          if (!snap.exists) continue;

          final prevStatus = snap.data()?['status'] as String? ?? 'pending';
          if (prevStatus == JobStatus.approved.name) continue;

          batch.update(snap.reference, {
            'status': 'approved',
            'approvedBy': adminUid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });
          batch.set(snap.reference.collection('history').doc(), {
            'changedBy': adminUid,
            'changedAt': FieldValue.serverTimestamp(),
            'previousStatus': prevStatus,
            'newStatus': 'approved',
          });
        }

        await batch.commit();
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
        final normalizedChunk = chunk
            .map(
              (job) => job.copyWith(
                invoiceNumber: InvoiceUtils.normalize(job.invoiceNumber),
              ),
            )
            .toList(growable: false);
        final refs = normalizedChunk
            .map((job) => _jobsRef.doc(_safeImportDocId(job)))
            .toList(growable: false);
        final existingJobDocs = await Future.wait(refs.map((ref) => ref.get()));

        final jobsToCreate =
            <({JobModel job, DocumentReference<Map<String, dynamic>> ref})>[];
        for (var i = 0; i < normalizedChunk.length; i++) {
          if (existingJobDocs[i].exists) {
            continue;
          }
          jobsToCreate.add((job: normalizedChunk[i], ref: refs[i]));
        }

        if (jobsToCreate.isEmpty) {
          continue;
        }

        final claimBumps = <String, Map<String, dynamic>>{};
        for (final item in jobsToCreate) {
          final claimId = _invoiceClaimDocId(item.job.invoiceNumber);
          final entry = claimBumps.putIfAbsent(
            claimId,
            () => {
              'invoiceNumber': item.job.invoiceNumber,
              'companyId': item.job.companyId,
              'companyName': item.job.companyName,
              'reuseMode': _invoiceReuseModeFor(item.job),
              'activeJobCount': 0,
              'createdBy': item.job.techId,
            },
          );
          entry['activeJobCount'] =
              ((entry['activeJobCount'] as int?) ?? 0) + 1;
        }

        final existingClaimDocs = await Future.wait(
          claimBumps.keys.map(
            (claimId) => _invoiceClaimsRef.doc(claimId).get(),
          ),
        );

        final batch = firestore.batch();
        for (final item in jobsToCreate) {
          final data = item.job.toFirestore();
          data['date'] ??= FieldValue.serverTimestamp();
          data['submittedAt'] ??= FieldValue.serverTimestamp();
          batch.set(item.ref, data);
          imported++;
        }

        for (final existingClaimDoc in existingClaimDocs) {
          final claimRef = existingClaimDoc.reference;
          final bump = claimBumps[claimRef.id]!;
          final increment = bump['activeJobCount'] as int? ?? 0;
          if (existingClaimDoc.exists) {
            final existingData = existingClaimDoc.data() ?? <String, dynamic>{};
            batch.set(claimRef, {
              'invoiceNumber':
                  existingData['invoiceNumber'] ?? bump['invoiceNumber'],
              'companyId': existingData['companyId'] ?? bump['companyId'],
              'companyName': existingData['companyName'] ?? bump['companyName'],
              'reuseMode': existingData['reuseMode'] ?? bump['reuseMode'],
              'activeJobCount':
                  ((existingData['activeJobCount'] as num?)?.toInt() ?? 0) +
                  increment,
              'createdBy': existingData['createdBy'] ?? bump['createdBy'],
              'createdAt':
                  existingData['createdAt'] ?? FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            batch.set(claimRef, {
              'invoiceNumber': bump['invoiceNumber'],
              'companyId': bump['companyId'],
              'companyName': bump['companyName'],
              'reuseMode': bump['reuseMode'],
              'activeJobCount': increment,
              'createdBy': bump['createdBy'],
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
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
