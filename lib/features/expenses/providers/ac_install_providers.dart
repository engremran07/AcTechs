import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/ac_install_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

/// Today's AC installation records for the logged-in technician.
final todaysAcInstallsProvider =
    StreamProvider.autoDispose<List<AcInstallModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(acInstallRepositoryProvider)
          .watchTodaysInstalls(user.uid);
    });

/// All AC installation records for the logged-in technician.
final techAcInstallsProvider = StreamProvider.autoDispose<List<AcInstallModel>>(
  (ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return Stream.value([]);
    return ref.watch(acInstallRepositoryProvider).watchTechInstalls(user.uid);
  },
);

/// Admin: all pending AC installation records awaiting approval.
final pendingAcInstallsProvider =
    StreamProvider.autoDispose<List<AcInstallModel>>((ref) {
      return ref.watch(acInstallRepositoryProvider).watchPendingInstalls();
    });
