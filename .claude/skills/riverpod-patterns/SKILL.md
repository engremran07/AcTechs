---
name: riverpod-patterns
description: Riverpod 3.x provider patterns and best practices for AC Techs. Activate when creating or modifying providers, working with AsyncValue, or debugging state management issues.
---

# Riverpod Patterns — AC Techs (Riverpod 3.x)

## Provider Types and When to Use

### StreamProvider — Real-time Firestore data
```dart
final techJobsProvider = StreamProvider.autoDispose.family<List<JobModel>, String>((ref, techId) {
  return ref.watch(jobRepositoryProvider).getJobsByTech(techId);
});
```

### FutureProvider — One-time computed data
```dart
final monthlyAnalyticsProvider = FutureProvider.autoDispose.family<AnalyticsData, DateRange>((ref, range) {
  return ref.watch(adminRepositoryProvider).getAnalytics(range);
});
```

### FutureProvider with Pull-to-Refresh
For admin screens that fetch heavy data once (settlement candidates, history reports):
```dart
final settlementCandidatesProvider = FutureProvider.autoDispose<List<JobModel>>((ref) async {
  return ref.read(jobRepositoryProvider).fetchSettlementCandidates();
});
```
In widget — trigger refresh via `ref.invalidate`:
```dart
IconButton(
  icon: const Icon(Icons.refresh),
  onPressed: () => ref.invalidate(settlementCandidatesProvider),
)
```
Use `FutureProvider` (not `StreamProvider`) for settlement/history screens — one-time fetch avoids
a persistent stream listener consuming free-tier reads.

### StateNotifierProvider — Local mutable state
```dart
final jobFormProvider = StateNotifierProvider.autoDispose<JobFormNotifier, JobFormState>((ref) {
  return JobFormNotifier();
});
```

### AsyncNotifierProvider — Complex async with methods
```dart
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() => AuthNotifier());
```

## AsyncValue Handling in Widgets
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final jobsAsync = ref.watch(techJobsProvider(userId));
  return jobsAsync.when(
    data: (jobs) => JobListView(jobs: jobs),
    loading: () => const ShimmerJobList(),
    error: (error, stack) => ErrorCard(
      exception: error is AppException ? error : AppException.unknown(error),
    ),
  );
}
```

## Provider Dependencies
```dart
// Repository providers (singleton)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(FirebaseFirestore.instance);
});

// Stream providers (auto-dispose)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
```

## Rules
- Never use ref.read() inside build() — always ref.watch()
- Use .autoDispose unless intentionally caching
- Use .family for parameterized providers
- Handle all three AsyncValue states (loading, error, data)
- Keep providers thin — business logic in repositories
- Keep expensive filtered subsets memoized in providers when reused by multiple screens

## Shared Install Providers Pattern

### pendingSharedInstallAggregatesProvider
Watches all shared install groups the current tech belongs to, using Firestore `arrayContains`:
```dart
final pendingSharedInstallAggregatesProvider =
    StreamProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(sharedInstallRepositoryProvider)
      .watchGroupsForMember(user.uid);
});
```

### Cross-referencing two providers for derived status
To show whether a tech has already submitted their contribution for a shared group:
```dart
final techSharedJobsAsync = ref.watch(techJobsProvider(uid));
final groupsAsync = ref.watch(pendingSharedInstallAggregatesProvider);

// Combine in widget using .when chains or use a derived FutureProvider
final submittedGroupKeys = techJobsAsync.value
    ?.where((j) => j.isShared)
    .map((j) => j.sharedInstallGroupKey)
    .toSet() ?? {};

final pendingGroups = groupsAsync.value
    ?.where((g) => !submittedGroupKeys.contains(g.groupKey))
    .toList() ?? [];
```

### activeTechniciansForTeamProvider
Provider that returns all active technicians — WITHOUT admin guard — so that technicians can use it to populate the team selector dropdown:
```dart
final activeTechniciansForTeamProvider =
    StreamProvider.autoDispose<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  // No isAdmin check — all active users are employees in a closed system
  return ref.watch(userRepositoryProvider).allTechnicians();
});
```
This is safe because `firestore.rules` already limits `/users` list to `isActiveUser() || isAdmin()`.

## Stream Filtering Tradeoffs

### Dart-layer filter (preferred for small datasets)
```dart
// No new Firestore index required
stream.map((snap) => snap.docs
  .where((d) => d.data()['isDeleted'] != true)
  .map((d) => Model.fromFirestore(d))
  .toList())
```
Use when: per-user dataset < ~500 docs, or when adding a Firestore index would exceed free-tier index limits.

### Firestore-layer filter (for large or shared datasets)
```dart
collection.where('isDeleted', isEqualTo: false).snapshots()
```
Use when: dataset grows large, already have a composite index covering the query, or query-layer filtering is needed for pagination.

**AC Techs policy:** Prefer Dart-layer filtering for isDeleted. The per-tech dataset for expenses/earnings is well under 500 docs, so Dart filtering is correct and avoids new index costs.

---

## In/Out Provider Hierarchy (expenses_providers.dart)

### ⚠️ Domain boundary: always use expense_providers — NEVER job_providers for In/Out screens

The `DailyInOutScreen` and `JobHistoryScreen` In/Out tab use ONLY providers from `expense_providers.dart`.
Never watch `technicianJobsProvider` or `todaysJobsProvider` to get earnings/expense data.

### Provider stack (no extra Firestore listeners for sub-day views)
```
Firestore listeners (1 per month per domain, autoDispose):
  monthlyEarningsProvider(DateTime)    → StreamProvider.family
  monthlyExpensesProvider(DateTime)    → StreamProvider.family

Derived (today, zero extra Firestore reads):
  todaysEarningsProvider               → derives from monthlyEarningsProvider(thisMonth)
  todaysExpensesProvider               → derives from monthlyExpensesProvider(thisMonth)

Derived (single historical day, zero extra Firestore reads):
  dailyEarningsProvider(DateTime)      → derives from monthlyEarningsProvider(month of date)
  dailyExpensesProvider(DateTime)      → derives from monthlyExpensesProvider(month of date)

All-time (for history + PDF export):
  techEarningsProvider                 → StreamProvider (all earnings for logged-in tech)
  techExpensesProvider                 → StreamProvider (all expenses for logged-in tech)
```

### dailyEarningsProvider / dailyExpensesProvider pattern
```dart
/// Single day's earnings — derives from monthlyEarningsProvider (no extra Firestore listener).
final dailyEarningsProvider = Provider.autoDispose
    .family<AsyncValue<List<EarningModel>>, DateTime>((ref, date) {
  final month = DateTime(date.year, date.month);
  return ref.watch(monthlyEarningsProvider(month)).whenData(
    (list) => list
        .where((e) =>
            e.date?.year == date.year &&
            e.date?.month == date.month &&
            e.date?.day == date.day)
        .toList(),
  );
});
```
Use this whenever `DailyInOutScreen(selectedDate: someDate)` is shown from history navigation.

---

## Stale Shared Install Aggregates Pattern (job_providers.dart)

### staleSharedAggregatesProvider — Admin-Only FutureProvider
Fetches shared install aggregates with no new contributions in >30 days. Used by the admin dashboard cleanup card.

```dart
final staleSharedAggregatesProvider =
    FutureProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
  return ref.watch(jobRepositoryProvider).fetchStaleSharedAggregates();
});
```

### Usage pattern — fetch, display, archive with invalidation
```dart
// In admin dashboard widget:
final staleAsync = ref.watch(staleSharedAggregatesProvider);

// After admin archives a stale aggregate:
await repo.archiveStaleSharedInstall(agg.groupKey);
ref.invalidate(staleSharedAggregatesProvider); // refresh the list
```

### Key constraints
- **Admin-only**: Never expose stale cleanup to technicians
- **FutureProvider, not StreamProvider**: One-time fetch on demand, avoids persistent listener
- **No counter rollback**: Archiving does NOT decrement aggregate `consumed*` counters (free-tier constraint)
- **Batch operation**: `archiveStaleSharedInstall` soft-deletes both the aggregate doc and associated job docs in a Firestore batch

### DailyInOutScreen provider selection
```dart
// In DailyInOutScreen.build():
final selectedDate = widget.selectedDate;
final earningsAsync = selectedDate != null
    ? ref.watch(dailyEarningsProvider(selectedDate))   // historical date
    : ref.watch(todaysEarningsProvider);               // today
final expensesAsync = selectedDate != null
    ? ref.watch(dailyExpensesProvider(selectedDate))   // historical date
    : ref.watch(todaysExpensesProvider);               // today
```
