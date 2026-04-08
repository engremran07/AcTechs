---
description: Firebase and data-layer rules for AC Techs.
paths:
	- lib/features/*/data/**
---

# Firebase & Data Layer Rules — AC Techs

- All Firestore operations go through repository classes
- Use Firestore snapshots (streams) for real-time data, not one-time get()
- Wrap all Firebase calls in try/catch, convert to AppException
- Never expose FirebaseException messages to users
- Denormalize frequently-queried fields (e.g., techName in job docs)
- Use compound indexes for multi-field queries
- Collection paths are constants in `AppConstants`
- All write operations validate data before sending to Firestore
- Offline: Firestore persistence handles caching automatically
- Free tier awareness: minimize reads, use pagination for large lists
- Destructive operations (delete/flush) must be admin-only and triggered from repository methods
- Firestore rules changes must pass `npm run lint:firestore-rules` and `npm test` in `scripts/` before deploy
- Treat Firestore rules compile warnings as release blockers; remove unused functions and reserved-name patterns immediately
- Expression-limit evaluator messages in emulator logs are considered failures and require a rules micro-pass before release

## Domain Collection Boundaries

Three completely separate Firestore collection groups — NEVER query across domains:

| Collection | Owned By | Repository |
|-----------|---------|-----------|
| `jobs/` | JobModel | JobRepository |
| `expenses/` | ExpenseModel | ExpenseRepository |
| `earnings/` | EarningModel | EarningRepository |
| `ac_installations/` | AcInstallModel | AcInstallRepository |
| `shared_install_aggregates/` | SharedInstallAggregate | (inside JobRepository) |

- When adding a new field to `ExpenseModel`/`EarningModel`, update `validExpenseCreatePayload()` / `validEarningCreatePayload()` in `firestore.rules` — NOT `validJobCreatePayload()`
- For single-day expense/earning queries, ALWAYS derive from the existing monthly stream in Dart — do NOT open a day-scoped Firestore listener (would count as an extra free-tier listener)
