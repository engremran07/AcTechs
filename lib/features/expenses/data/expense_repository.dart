import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _ref.add(expense.toFirestore());
    } catch (_) {
      throw ExpenseException.saveFailed();
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _ref.doc(id).delete();
    } catch (_) {
      throw ExpenseException.deleteFailed();
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _ref.doc(expense.id).update(expense.toFirestore());
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> approveExpense(String id, String adminUid) async {
    try {
      await _ref.doc(id).update({
        'status': AppConstants.statusApproved,
        'approvedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> rejectExpense(String id, String adminUid, String reason) async {
    try {
      await _ref.doc(id).update({
        'status': AppConstants.statusRejected,
        'approvedBy': adminUid,
        'adminNote': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }

  Stream<List<ExpenseModel>> pendingExpenses() {
    return _ref
        .where('status', isEqualTo: AppConstants.statusPending)
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
