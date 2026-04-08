import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
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

/// Today's work expenses — derived from todaysExpensesProvider (no extra Firestore listener).
final todaysWorkExpensesProvider =
    Provider.autoDispose<AsyncValue<List<ExpenseModel>>>((ref) {
      return ref
          .watch(todaysExpensesProvider)
          .whenData(
            (list) => list
                .where((e) => e.expenseType != AppConstants.expenseTypeHome)
                .toList(),
          );
    });

/// Today's home expenses — derived from todaysExpensesProvider (no extra Firestore listener).
final todaysHomeExpensesProvider =
    Provider.autoDispose<AsyncValue<List<ExpenseModel>>>((ref) {
      return ref
          .watch(todaysExpensesProvider)
          .whenData(
            (list) => list
                .where((e) => e.expenseType == AppConstants.expenseTypeHome)
                .toList(),
          );
    });

/// Monthly expenses for the logged-in tech.
/// DateTime key is normalised to the first of the month to prevent duplicate listeners.
final monthlyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseModel>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(expenseRepositoryProvider)
          .monthlyExpenses(user.uid, normalized);
    });

/// Monthly work expenses — derived from monthlyExpensesProvider (no extra Firestore listener).
final monthlyWorkExpensesProvider = Provider.autoDispose
    .family<AsyncValue<List<ExpenseModel>>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      return ref
          .watch(monthlyExpensesProvider(normalized))
          .whenData(
            (list) => list
                .where((e) => e.expenseType != AppConstants.expenseTypeHome)
                .toList(),
          );
    });

/// Monthly home expenses — derived from monthlyExpensesProvider (no extra Firestore listener).
final monthlyHomeExpensesProvider = Provider.autoDispose
    .family<AsyncValue<List<ExpenseModel>>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      return ref
          .watch(monthlyExpensesProvider(normalized))
          .whenData(
            (list) => list
                .where((e) => e.expenseType == AppConstants.expenseTypeHome)
                .toList(),
          );
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

/// Single day's earnings — derived from monthlyEarningsProvider (no extra Firestore listener).
final dailyEarningsProvider = Provider.autoDispose
    .family<AsyncValue<List<EarningModel>>, DateTime>((ref, date) {
      final month = DateTime(date.year, date.month);
      return ref
          .watch(monthlyEarningsProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == date.year &&
                      e.date?.month == date.month &&
                      e.date?.day == date.day,
                )
                .toList(),
          );
    });

/// Single day's expenses — derived from monthlyExpensesProvider (no extra Firestore listener).
final dailyExpensesProvider = Provider.autoDispose
    .family<AsyncValue<List<ExpenseModel>>, DateTime>((ref, date) {
      final month = DateTime(date.year, date.month);
      return ref
          .watch(monthlyExpensesProvider(month))
          .whenData(
            (list) => list
                .where(
                  (e) =>
                      e.date?.year == date.year &&
                      e.date?.month == date.month &&
                      e.date?.day == date.day,
                )
                .toList(),
          );
    });

/// Monthly earnings for the logged-in tech.
final monthlyEarningsProvider = StreamProvider.autoDispose
    .family<List<EarningModel>, DateTime>((ref, month) {
      final normalized = DateTime(month.year, month.month);
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);
      return ref
          .watch(earningRepositoryProvider)
          .monthlyEarnings(user.uid, normalized);
    });

final pendingExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).pendingExpenses();
});

final pendingEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).pendingEarnings();
});

final allExpensesProvider = StreamProvider.autoDispose<List<ExpenseModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(expenseRepositoryProvider).allExpenses();
});

final allEarningsProvider = StreamProvider.autoDispose<List<EarningModel>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || !user.isAdmin) return Stream.value([]);
  return ref.watch(earningRepositoryProvider).allEarnings();
});
