---
name: riverpod-patterns
description: Riverpod 3.x provider patterns and best practices for AC Techs. Activate when creating or modifying providers, working with AsyncValue, or debugging state management issues.
allowed-tools: Read, Grep
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
