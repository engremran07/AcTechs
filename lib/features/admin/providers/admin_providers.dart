import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

final allTechniciansProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allTechnicians();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allUsers();
});

final flushDatabaseProvider =
    AsyncNotifierProvider<FlushDatabaseNotifier, void>(
      FlushDatabaseNotifier.new,
    );

class FlushDatabaseNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Verifies the admin password then flushes the database.
  Future<void> flush(
    String password, {
    required bool deleteNonAdminUsers,
    String? targetTechnicianId,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.verifyAdminPassword(password);
      if (targetTechnicianId != null && targetTechnicianId.trim().isNotEmpty) {
        await repo.flushTechnicianData(targetTechnicianId);
      } else {
        await repo.flushDatabase(deleteNonAdminUsers: deleteNonAdminUsers);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
