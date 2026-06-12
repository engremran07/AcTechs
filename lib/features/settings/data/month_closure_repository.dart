import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/settings/data/approval_config_repository.dart';

final monthClosureRepositoryProvider = Provider<MonthClosureRepository>((ref) {
  return MonthClosureRepository(
    firestore: FirebaseFirestore.instance,
    approvalConfigRepository: ref.watch(approvalConfigRepositoryProvider),
  );
});

class MonthClosureRepository {
  MonthClosureRepository({
    required this.firestore,
    required this.approvalConfigRepository,
  });

  final FirebaseFirestore firestore;
  final ApprovalConfigRepository approvalConfigRepository;

  CollectionReference<Map<String, dynamic>> get _appSettingsRef =>
      firestore.collection(AppConstants.appSettingsCollection);

  DocumentReference<Map<String, dynamic>> get _monthClosuresDoc =>
      _appSettingsRef.doc('month_closures');

  Stream<List<MonthClosureEvent>> watchMonthClosures() {
    return _monthClosuresDoc.snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      final entries = (data['entries'] as List?) ?? const [];
      final parsed = entries
          .whereType<Map>()
          .map((entry) => MonthClosureEvent.fromMap(
                entry.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList(growable: false)
        ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
      return parsed;
    });
  }

  Future<void> closeCompanyMonth({
    required CompanyModel company,
    required DateTime month,
    required String adminUid,
  }) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final period = company.invoicePeriodForDate(
      DateTime(normalizedMonth.year, normalizedMonth.month, 15),
    );
    final lockedBefore = DateTime(
      period.end.year,
      period.end.month,
      period.end.day + 1,
    );

    final event = MonthClosureEvent(
      companyId: company.id,
      companyName: company.name,
      month: normalizedMonth,
      closedBy: adminUid,
      closedAt: DateTime.now(),
      lockedBefore: lockedBefore,
    );

    await _monthClosuresDoc.set(
      {
        'entries': FieldValue.arrayUnion([event.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Move global lock so old records cannot be edited post close.
    await approvalConfigRepository.setLockedBeforeDate(lockedBefore);
  }
}
