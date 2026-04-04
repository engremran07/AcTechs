import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late JobRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = JobRepository(firestore: firestore);
  });

  JobModel buildSharedJob({
    required String techId,
    required String techName,
    required String invoiceNumber,
    required int splitShare,
  }) {
    final now = DateTime(2024, 1, 10, 9);
    return JobModel(
      techId: techId,
      techName: techName,
      companyId: 'company-1',
      companyName: 'Company',
      invoiceNumber: invoiceNumber,
      clientName: 'Client',
      acUnits: [
        AcUnit(type: AppConstants.unitTypeSplitAc, quantity: splitShare),
      ],
      status: JobStatus.pending,
      expenses: 0,
      isSharedInstall: true,
      sharedInstallGroupKey: 'company-1-${invoiceNumber.toLowerCase()}',
      sharedInvoiceTotalUnits: 4,
      sharedContributionUnits: splitShare,
      sharedInvoiceSplitUnits: 4,
      sharedInvoiceWindowUnits: 0,
      sharedInvoiceFreestandingUnits: 0,
      sharedInvoiceBracketCount: 0,
      sharedDeliveryTeamCount: 0,
      sharedInvoiceDeliveryAmount: 0,
      techSplitShare: splitShare,
      date: now,
      submittedAt: now,
    );
  }

  test(
    'shared job submission creates and updates aggregate reservations',
    () async {
      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-1',
          techName: 'Tech One',
          invoiceNumber: 'INV-100',
          splitShare: 2,
        ),
      );
      await repository.submitJob(
        buildSharedJob(
          techId: 'tech-2',
          techName: 'Tech Two',
          invoiceNumber: 'INV-100',
          splitShare: 1,
        ),
      );

      final aggregateSnap = await firestore
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .get();

      expect(aggregateSnap.docs, hasLength(1));
      expect(aggregateSnap.docs.single.data()['consumedSplitUnits'], 3);
      expect(aggregateSnap.docs.single.data()['groupKey'], 'company-1-inv-100');
    },
  );

  test('rejecting a shared job releases only that job reservation', () async {
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-1',
        techName: 'Tech One',
        invoiceNumber: 'INV-200',
        splitShare: 2,
      ),
    );
    await repository.submitJob(
      buildSharedJob(
        techId: 'tech-2',
        techName: 'Tech Two',
        invoiceNumber: 'INV-200',
        splitShare: 1,
      ),
    );

    final jobsSnap = await firestore
        .collection(AppConstants.jobsCollection)
        .orderBy('techId')
        .get();
    final firstJobId = jobsSnap.docs.first.id;

    await repository.rejectJob(firstJobId, 'admin-1', 'Mismatch');

    final aggregateSnap = await firestore
        .collection(AppConstants.sharedInstallAggregatesCollection)
        .get();
    final jobHistorySnap = await firestore
        .collection(AppConstants.jobsCollection)
        .doc(firstJobId)
        .collection('history')
        .get();

    expect(aggregateSnap.docs.single.data()['consumedSplitUnits'], 1);
    expect(jobHistorySnap.docs, hasLength(1));
    expect(jobHistorySnap.docs.single.data()['newStatus'], 'rejected');
    expect(jobHistorySnap.docs.single.data()['reason'], 'Mismatch');
  });
}
