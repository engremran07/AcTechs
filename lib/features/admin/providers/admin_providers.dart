import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

final allTechniciansProvider = StreamProvider.autoDispose<List<UserModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allTechnicians();
});

/// All active technicians, without an admin guard.
/// Used by the shared install team selector dropdown so technicians can pick
/// their teammates. Safe because [firestore.rules] restricts the users list
/// to `isActiveUser() || isAdmin()` only — closed employee system.
final activeTechniciansForTeamProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(userRepositoryProvider).allTechnicians();
    });

final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(userRepositoryProvider).allUsers();
});

final flushDatabaseProvider =
    AsyncNotifierProvider<FlushDatabaseNotifier, void>(
      FlushDatabaseNotifier.new,
    );

final invoicePrefixMigrationProvider =
    AsyncNotifierProvider<InvoicePrefixMigrationNotifier, void>(
      InvoicePrefixMigrationNotifier.new,
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

class InvoicePrefixMigrationNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<InvoicePrefixNormalizationResult> run(String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.verifyAdminPassword(password);
      final result = await repo.normalizeStoredInvoicePrefixes();
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
