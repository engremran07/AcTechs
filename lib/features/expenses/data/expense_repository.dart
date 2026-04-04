import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(firestore: FirebaseFirestore.instance);
});

class ExpenseRepository {
  ExpenseRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.expensesCollection);

  CollectionReference<Map<String, dynamic>> _historyRef(String expenseId) {
    return _ref.doc(expenseId).collection('history');
  }

  Future<List<ApprovalHistoryEntry>> fetchHistory(
    String expenseId, {
    int limit = 10,
  }) async {
    final snap = await _historyRef(
      expenseId,
    ).orderBy('changedAt', descending: true).limit(limit).get();
    return snap.docs
        .map((doc) => ApprovalHistoryEntry.fromMap(doc.data()))
        .toList(growable: false);
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _ref.add(expense.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('addExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.saveFailed();
    } catch (e) {
      debugPrint('addExpense unknown: $e');
      throw ExpenseException.saveFailed();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _ref.doc(id).delete();
    } on FirebaseException catch (e) {
      debugPrint('deleteExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.deleteFailed();
    } catch (e) {
      debugPrint('deleteExpense unknown: $e');
      throw ExpenseException.deleteFailed();
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _ref.doc(expense.id).update(expense.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('updateExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('updateExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> approveExpense(String id, String adminUid) async {
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
      debugPrint('approveExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('approveExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> rejectExpense(String id, String adminUid, String reason) async {
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
      debugPrint('rejectExpense error: ${e.code} — ${e.message}');
      throw ExpenseException.userSaveFailed();
    } catch (e) {
      debugPrint('rejectExpense unknown: $e');
      throw ExpenseException.userSaveFailed();
    }
  }

  Stream<List<ExpenseModel>> pendingExpenses() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ExpenseModel>> allExpenses() {
    return _ref
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  /// Real-time stream of a tech's expenses, newest first.
  Stream<List<ExpenseModel>> techExpenses(String techId) {
    return _ref
        .where('techId', isEqualTo: techId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  /// Expenses for a specific month.
  Stream<List<ExpenseModel>> monthlyExpenses(String techId, DateTime month) {
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
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  /// Today's expenses for a tech.
  Stream<List<ExpenseModel>> todaysExpenses(String techId) {
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
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ExpenseModel>> todaysWorkExpenses(String techId) {
    return todaysExpenses(techId).map(
      (items) => items
          .where((item) => item.expenseType != AppConstants.expenseTypeHome)
          .toList(),
    );
  }

  Stream<List<ExpenseModel>> todaysHomeExpenses(String techId) {
    return todaysExpenses(techId).map(
      (items) => items
          .where((item) => item.expenseType == AppConstants.expenseTypeHome)
          .toList(),
    );
  }

  Stream<List<ExpenseModel>> monthlyWorkExpenses(
    String techId,
    DateTime month,
  ) {
    return monthlyExpenses(techId, month).map(
      (items) => items
          .where((item) => item.expenseType != AppConstants.expenseTypeHome)
          .toList(),
    );
  }

  Stream<List<ExpenseModel>> monthlyHomeExpenses(
    String techId,
    DateTime month,
  ) {
    return monthlyExpenses(techId, month).map(
      (items) => items
          .where((item) => item.expenseType == AppConstants.expenseTypeHome)
          .toList(),
    );
  }
}
