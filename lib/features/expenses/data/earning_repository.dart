import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addEarning(EarningModel earning) async {
    try {
      await _ref.add(earning.toFirestore());
    } catch (_) {
      throw ExpenseException.saveFailed();
    }
  }

  Future<void> deleteEarning(String id) async {
    try {
      await _ref.doc(id).delete();
    } catch (_) {
      throw ExpenseException.deleteFailed();
    }
  }

  Future<void> updateEarning(EarningModel earning) async {
    try {
      await _ref.doc(earning.id).update(earning.toFirestore());
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
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
