import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

/// All expenses for the logged-in tech (newest first).
final techExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).techExpenses(user.uid);
});

/// Today's expenses for the logged-in tech.
final todaysExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).todaysExpenses(user.uid);
});

final todaysWorkExpensesProvider =
    StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(expenseRepositoryProvider).todaysWorkExpenses(user.uid);
    });

final todaysHomeExpensesProvider =
    StreamProvider.autoDispose<List<ExpenseModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref.watch(expenseRepositoryProvider).todaysHomeExpenses(user.uid);
    });

/// Monthly expenses for the logged-in tech.
final monthlyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(expenseRepositoryProvider)
          .monthlyExpenses(user.uid, month);
    });

final monthlyWorkExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(expenseRepositoryProvider)
          .monthlyWorkExpenses(user.uid, month);
    });

final monthlyHomeExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(expenseRepositoryProvider)
          .monthlyHomeExpenses(user.uid, month);
    });

/// All earnings for the logged-in tech (newest first).
final techEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).techEarnings(user.uid);
});

/// Today's earnings for the logged-in tech.
final todaysEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).todaysEarnings(user.uid);
});

/// Monthly earnings for the logged-in tech.
final monthlyEarningsProvider = StreamProvider.autoDispose
    .family<List<EarningModel>, DateTime>((ref, month) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(earningRepositoryProvider)
          .monthlyEarnings(user.uid, month);
    });
