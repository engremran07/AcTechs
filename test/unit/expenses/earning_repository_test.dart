import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EarningRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = EarningRepository(firestore: firestore);
  });

  test('updateEarning rejects approved records', () async {
    final doc = await firestore.collection(AppConstants.earningsCollection).add({
      'techId': 'tech-1',
      'techName': 'Ali',
      'category': 'Scrap Sale',
      'amount': 250.0,
      'note': '',
      'paymentType': 'regular',
      'status': 'approved',
      'approvedBy': 'admin-1',
      'adminNote': '',
      'date': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 4, 1, 8)),
      'reviewedAt': Timestamp.fromDate(DateTime(2026, 4, 1, 9)),
    });

    final updated = EarningModel(
      id: doc.id,
      techId: 'tech-1',
      techName: 'Ali',
      category: 'Scrap Sale',
      amount: 300,
      paymentType: PaymentType.regular,
      status: EarningApprovalStatus.approved,
      approvedBy: 'admin-1',
      date: DateTime(2026, 4, 1, 8),
      createdAt: DateTime(2026, 4, 1, 8),
      reviewedAt: DateTime(2026, 4, 1, 9),
    );

    await expectLater(
      () => repository.updateEarning(updated),
      throwsA(isA<EarningException>()),
    );
  });
}