import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final acInstallRepositoryProvider = Provider<AcInstallRepository>((ref) {
  return AcInstallRepository(firestore: FirebaseFirestore.instance);
});

class AcInstallRepository {
  AcInstallRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.acInstallsCollection);

  /// Stream of today's AC install records for a specific technician.
  Stream<List<AcInstallModel>> watchTodaysInstalls(String techId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _ref
        .where('techId', isEqualTo: techId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AcInstallModel.fromFirestore).toList());
  }

  /// Stream of all AC install records for a technician (for monthly summaries).
  Stream<List<AcInstallModel>> watchTechInstalls(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AcInstallModel.fromFirestore).toList());
  }

  /// Admin: stream of all pending AC install records.
  Stream<List<AcInstallModel>> watchPendingInstalls() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AcInstallModel.fromFirestore).toList());
  }

  Future<void> addInstall(AcInstallModel install) async {
    try {
      await _ref.add(install.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('addInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.saveFailed();
    } catch (e) {
      debugPrint('addInstall unknown: $e');
      throw AcInstallException.saveFailed();
    }
  }

  Future<void> deleteInstall(String id) async {
    try {
      await _ref.doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('deleteInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.deleteFailed();
    } catch (e) {
      debugPrint('deleteInstall unknown: $e');
      throw AcInstallException.deleteFailed();
    }
  }

  Future<void> approveInstall(String id, String adminUid) async {
    try {
      await _ref.doc(id).update({
        'status': 'approved',
        'approvedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('approveInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.updateFailed();
    } catch (e) {
      debugPrint('approveInstall unknown: $e');
      throw AcInstallException.updateFailed();
    }
  }

  Future<void> rejectInstall(String id, String adminUid, String note) async {
    try {
      await _ref.doc(id).update({
        'status': 'rejected',
        'approvedBy': adminUid,
        'adminNote': note,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('rejectInstall error: ${e.code} — ${e.message}');
      throw AcInstallException.updateFailed();
    } catch (e) {
      debugPrint('rejectInstall unknown: $e');
      throw AcInstallException.updateFailed();
    }
  }
}
