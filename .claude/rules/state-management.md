---
description: State management rules for provider-layer files.
paths:
	- lib/features/*/providers/**
---

# State Management Rules — AC Techs (Riverpod 3.x)

- Use StreamProvider for real-time Firestore data
- Use FutureProvider for one-time computed data (analytics, exports)
- Use StateNotifierProvider for local mutable state (form state, filters)
- Use AsyncNotifierProvider for complex async state with methods
- Always handle AsyncValue states: loading, error, data in widgets
- Provider naming: <noun>Provider (e.g., techJobsProvider, pendingApprovalsProvider)
- Keep providers thin: business logic lives in repositories
- Dispose: StreamProviders auto-dispose on last listener removal
- AutoDispose: use ref.keepAlive() only when caching is intentional
- Never use ref.read() in build methods — use ref.watch()
- Use family providers for parameterized filtered views (e.g., AC-type scoped job lists)

## Domain Provider Boundaries — CRITICAL

The three data domains each have their own provider file. NEVER cross them:
- `job_providers.dart` — for `JobModel` only (`technicianJobsProvider`, `todaysJobsProvider`, etc.)
- `expense_providers.dart` — for `ExpenseModel` + `EarningModel` only
- `DailyInOutScreen` and expense screens ONLY watch providers from `expense_providers.dart`

## In/Out Provider Hierarchy (no extra Firestore listeners for sub-day views)

```
monthlyEarningsProvider(DateTime)   → StreamProvider.family  ← REAL Firestore listener
monthlyExpensesProvider(DateTime)   → StreamProvider.family  ← REAL Firestore listener

todaysEarningsProvider              → derived from monthly  ← no extra listener
todaysExpensesProvider              → derived from monthly  ← no extra listener

dailyEarningsProvider(DateTime)     → derived from monthly  ← no extra listener
dailyExpensesProvider(DateTime)     → derived from monthly  ← no extra listener
```

When adding a new In/Out sub-view (e.g., single-day history), always derive from the monthly provider using a `Provider.autoDispose.family`. Never create a new `StreamProvider` scoped to a single day — it would open an extra Firestore listener.
