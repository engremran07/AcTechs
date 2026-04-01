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
