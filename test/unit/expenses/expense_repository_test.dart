import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ExpenseRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ExpenseRepository(firestore: firestore);
  });

  Future<void> lockBefore(DateTime date) {
    return firestore
        .collection(AppConstants.appSettingsCollection)
        .doc(AppConstants.approvalConfigDocId)
        .set({'lockedBefore': Timestamp.fromDate(date)});
  }

  test(
    'addExpense rejects records dated before the locked period boundary',
    () async {
      await lockBefore(DateTime(2026, 4, 1));

      final expense = ExpenseModel(
        techId: 'tech-1',
        techName: 'Ali',
        category: 'Petrol',
        amount: 100,
        date: DateTime(2026, 3, 31, 22),
      );

      await expectLater(
        () => repository.addExpense(expense),
        throwsA(isA<PeriodException>()),
      );
    },
  );

  test('addExpense allows records on or after the unlocked boundary', () async {
    await lockBefore(DateTime(2026, 4, 1));

    final expense = ExpenseModel(
      techId: 'tech-1',
      techName: 'Ali',
      category: 'Petrol',
      amount: 100,
      date: DateTime(2026, 4, 1, 8),
    );

    await repository.addExpense(expense);

    final snap = await firestore
        .collection(AppConstants.expensesCollection)
        .get();
    expect(snap.docs, hasLength(1));
  });

  test('updateExpense rejects approved records', () async {
    final doc = await firestore
        .collection(AppConstants.expensesCollection)
        .add({
          'techId': 'tech-1',
          'techName': 'Ali',
          'category': 'Petrol',
          'amount': 100.0,
          'note': '',
          'expenseType': 'work',
          'status': 'approved',
          'approvedBy': 'admin-1',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
          'reviewedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 9)),
        });

    final updated = ExpenseModel(
      id: doc.id,
      techId: 'tech-1',
      techName: 'Ali',
      category: 'Petrol',
      amount: 140,
      expenseType: 'work',
      status: ExpenseApprovalStatus.approved,
      approvedBy: 'admin-1',
      date: DateTime(2026, 4, 1, 8),
      createdAt: DateTime(2026, 4, 1, 8),
      reviewedAt: DateTime(2026, 4, 1, 9),
    );

    await expectLater(
      () => repository.updateExpense(updated),
      throwsA(isA<ExpenseException>()),
    );
  });

  test('deleteExpense rejects approved records', () async {
    final doc = await firestore
        .collection(AppConstants.expensesCollection)
        .add({
          'techId': 'tech-1',
          'techName': 'Ali',
          'category': 'Petrol',
          'amount': 100.0,
          'note': '',
          'expenseType': 'work',
          'status': 'approved',
          'approvedBy': 'admin-1',
          'adminNote': '',
          'date': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
          'reviewedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 9)),
        });

    await expectLater(
      () => repository.deleteExpense(doc.id),
      throwsA(isA<ExpenseException>()),
    );
  });
}
