import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final earningRepositoryProvider = Provider<EarningRepository>((ref) {
  return EarningRepository(firestore: FirebaseFirestore.instance);
});

class EarningRepository {
  EarningRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.earningsCollection);

  CollectionReference<Map<String, dynamic>> _historyRef(String earningId) {
    return _ref.doc(earningId).collection('history');
  }

  Future<List<ApprovalHistoryEntry>> fetchHistory(
    String earningId, {
    int limit = 10,
  }) async {
    final snap = await _historyRef(
      earningId,
    ).orderBy('changedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addEarning(EarningModel earning) async {
    try {
      await _ref.add(earning.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('addEarning error: ${e.code} — ${e.message}');
      throw EarningException.saveFailed();
    } catch (e) {
      debugPrint('addEarning unknown: $e');
      throw EarningException.saveFailed();
    }
  }

  Future<void> deleteEarning(String id) async {
    try {
      await _ref.doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('deleteEarning error: ${e.code} — ${e.message}');
      throw EarningException.deleteFailed();
    } catch (e) {
      debugPrint('deleteEarning unknown: $e');
      throw EarningException.deleteFailed();
    }
  }

  Future<void> updateEarning(EarningModel earning) async {
    try {
      await _ref.doc(earning.id).update(earning.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('updateEarning error: ${e.code} — ${e.message}');
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('updateEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Future<void> approveEarning(String id, String adminUid) async {
    try {
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        tx.update(docRef, {
          'status': 'approved',
          'approvedBy': adminUid,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'approved',
        });
      });
    } on FirebaseException catch (e) {
      debugPrint('approveEarning error: ${e.code} — ${e.message}');
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('approveEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Future<void> rejectEarning(String id, String adminUid, String reason) async {
    try {
      await firestore.runTransaction((tx) async {
        final docRef = _ref.doc(id);
        final snap = await tx.get(docRef);
        final prevStatus = snap.data()?['status'] as String? ?? 'pending';
        tx.update(docRef, {
          'status': 'rejected',
          'approvedBy': adminUid,
          'adminNote': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_historyRef(id).doc(), {
          'changedBy': adminUid,
          'changedAt': FieldValue.serverTimestamp(),
          'previousStatus': prevStatus,
          'newStatus': 'rejected',
          'reason': reason,
        });
      });
    } on FirebaseException catch (e) {
      debugPrint('rejectEarning error: ${e.code} — ${e.message}');
      throw EarningException.updateFailed();
    } catch (e) {
      debugPrint('rejectEarning unknown: $e');
      throw EarningException.updateFailed();
    }
  }

  Stream<List<EarningModel>> pendingEarnings() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => EarningModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<EarningModel>> allEarnings() {
    return _ref
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => EarningModel.fromFirestore(d)).toList(),
        );
  }

  /// Real-time stream of a tech's earnings, newest first.
  Stream<List<EarningModel>> techEarnings(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => EarningModel.fromFirestore(d)).toList(),
        );
  }

  /// Earnings for a specific month.
  Stream<List<EarningModel>> monthlyEarnings(String techId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _ref
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => EarningModel.fromFirestore(d)).toList(),
        );
  }

  /// Today's earnings for a tech.
  Stream<List<EarningModel>> todaysEarnings(String techId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _ref
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => EarningModel.fromFirestore(d)).toList(),
        );
  }
}
