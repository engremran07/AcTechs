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
| `ac_installs/` | AcInstallModel | AcInstallRepository |
| `shared_install_aggregates/` | SharedInstallAggregate | (inside JobRepository) |

- When adding a new field to `ExpenseModel`/`EarningModel`, update `validExpenseCreatePayload()` / `validEarningCreatePayload()` in `firestore.rules` — NOT `validJobCreatePayload()`
- For single-day expense/earning queries, ALWAYS derive from the existing monthly stream in Dart — do NOT open a day-scoped Firestore listener (would count as an extra free-tier listener)

## Free-Tier Budget Rules (50K reads / 20K writes / 20K deletes per day)

### Query Quotas — mandatory on all collection queries
- NEVER open a `StreamProvider` on a collection without a `techId` or date filter — unbounded streams exhaust the read quota
- Settlement candidates: `FutureProvider` only (not stream) — one-time fetch on demand
- Admin analytics screens: `FutureProvider` only (not stream)
- For single-day sub-views: ALWAYS derive from the monthly stream in Dart (see state-management.md) — do NOT open a day-scoped listener

### Budget projection (5 techs + 1 admin, normal usage)
- Each `StreamProvider` on a 200-doc collection = ~200 reads per document change
- 10 changes/day × 200 docs = 2 000 reads from one stream alone
- Normal usage ≈ 300–500 reads/day — well within limits
- Alert threshold: investigate any new stream that could push daily reads above 10 000

### Prohibited Patterns
```dart
// ❌ Unbounded stream on full jobs collection
FirebaseFirestore.instance.collection('jobs').snapshots();

// ❌ isDeleted Firestore filter — creates composite index per collection
_ref.where('isDeleted', isEqualTo: false).snapshots();
// ✓ Filter in Dart instead (see firestore-patterns/SKILL.md Archive Pattern)

// ❌ New listener for single-day view
Stream earningsForDay(DateTime day) => _ref.where('date', ...).snapshots(); // extra listener!
// ✓ Derive from monthlyEarningsProvider in Dart (no new listener)
```
