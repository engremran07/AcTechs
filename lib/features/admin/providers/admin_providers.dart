import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';

final allTechniciansProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).allTechnicians();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).allUsers();
});
