---
name: firestore-patterns
description: Firestore query patterns, security rules, and offline sync strategies for AC Techs. Activate when working with Firestore collections, queries, security rules, or offline behavior.
---

# Firestore Patterns — AC Techs

## Collections
- `users/{userId}` — User profiles (uid, name, role, isActive, createdAt, language)
- `jobs/{jobId}` — Job records (auto-id, all work units, expenses, status, timestamps)
- `expenses/{expenseId}` — Tech personal expenses (food, petrol, tools etc.) — **separate from jobs**
- `earnings/{earningId}` — Tech additional earnings (bracket sold, scrap, old AC) — **separate from jobs**
- `ac_installations/{installId}` — AC unit install logs — **separate from jobs**
- `shared_install_aggregates/{groupKey}` — Shared team install counter docs

## Query Patterns

### Technician's jobs (real-time)
```dart
FirebaseFirestore.instance
  .collection('jobs')
  .where('techId', isEqualTo: userId)
  .orderBy('submittedAt', descending: true)
  .snapshots()
```

### Today's jobs for tech
```dart
final startOfDay = DateTime(now.year, now.month, now.day);
FirebaseFirestore.instance
  .collection('jobs')
  .where('techId', isEqualTo: userId)
  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
  .orderBy('date', descending: true)
  .snapshots()
```

### Pending approvals (admin)
```dart
FirebaseFirestore.instance
  .collection('jobs')
  .where('status', isEqualTo: 'pending')
  .orderBy('submittedAt', descending: false) // oldest first
  .snapshots()
```

### Monthly analytics (admin)
```dart
FirebaseFirestore.instance
  .collection('jobs')
  .where('status', isEqualTo: 'approved')
  .where('date', isGreaterThanOrEqualTo: monthStart)
  .where('date', isLessThan: monthEnd)
  .get()
```

## Required Composite Indexes
1. `jobs`: techId ASC, submittedAt DESC
2. `jobs`: techId ASC, date DESC
3. `jobs`: status ASC, submittedAt ASC
4. `jobs`: status ASC, date ASC
5. `expenses`: techId ASC, date DESC
6. `earnings`: techId ASC, date DESC
7. `shared_install_aggregates`: teamMemberIds ASC, createdAt DESC

## In/Out Firestore Patterns (Expenses & Earnings)

### ⚠️ Domain separation — expenses/earnings are NOT jobs
`/expenses` and `/earnings` collections are completely separate from `/jobs`.
Never query expenses from a job provider, and never add expense fields to a job document.

### Monthly expenses/earnings for a tech
```dart
// In ExpenseRepository / EarningRepository
final startOfMonth = DateTime(month.year, month.month);
final endOfMonth = DateTime(month.year, month.month + 1);
_ref
  .where('techId', isEqualTo: techId)
  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
  .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
  .orderBy('date', descending: true)
  .snapshots()
  .map((snap) => snap.docs
    .where((d) => d.data()['isDeleted'] != true)  // Dart-layer soft-delete filter
    .map((d) => ExpenseModel.fromFirestore(d))
    .toList())
```
Required composite index: `techId ASC, date DESC`.

### Today's expenses (used by todaysExpensesProvider)
```dart
final startOfDay = DateTime(now.year, now.month, now.day);
final endOfDay = startOfDay.add(const Duration(days: 1));
_ref
  .where('techId', isEqualTo: techId)
  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
  .where('date', isLessThan: Timestamp.fromDate(endOfDay))
  .orderBy('date', descending: true)
  .snapshots()
```

### Single-day view WITHOUT a new Firestore listener
For viewing entries on a historical date (e.g., from history screen):
```dart
// WRONG — creates an extra Firestore listener
Stream<List<EarningModel>> earningsForDay(String techId, DateTime day); // do NOT do this

// CORRECT — derive from existing monthly listener in Riverpod
final dailyEarningsProvider = Provider.autoDispose
    .family<AsyncValue<List<EarningModel>>, DateTime>((ref, date) {
  final month = DateTime(date.year, date.month);
  return ref.watch(monthlyEarningsProvider(month)).whenData(
    (list) => list.where((e) =>
      e.date?.year == date.year &&
      e.date?.month == date.month &&
      e.date?.day == date.day).toList(),
  );
});
```
This reuses the already-open monthly listener — zero extra Firestore reads.

## Offline Sync
Firestore local persistence is enabled by default in Flutter. When offline:
- Reads return cached data
- Writes queue locally and sync when reconnected
- Listeners fire with cached data + `metadata.isFromCache`

## Security Rules Summary
- Technicians: create own jobs, read own jobs, cannot update status
- Admins: full read/write on all jobs and users
- Admin-only deletes are allowed for controlled maintenance flows (e.g., flush)
- UI must never call raw delete logic directly; route through repository/service methods

## Strict Rules Hygiene
- Treat warnings as failures: rules changes are not release-ready if compile/lint warnings exist.
- Always run `npm run lint:firestore-rules` and `npm test` from `scripts/` before deploying Firestore rules.
- Consider Firestore evaluator `maximum of 1000 expressions` messages as hard failures even when tests pass.
- When expression-limit messages appear, perform a micro-pass: reorder predicates for cheaper short-circuiting, split heavy branches, and remove duplicate high-cost checks.

## Team Roster Pattern (shared_install_aggregates)

### arrayContains membership query
```dart
// Tech watches all shared groups they belong to — zero client-side filtering
FirebaseFirestore.instance
  .collection('shared_install_aggregates')
  .where('teamMemberIds', arrayContains: uid)
  .orderBy('createdAt', descending: true)
  .snapshots()
```
Required composite index: `teamMemberIds ASC, createdAt DESC`.

### teamMemberIds contract
- `teamMemberIds[0]` is ALWAYS the createdBy uid (first submitter)
- `teamMemberNames` is a parallel array (same index order as `teamMemberIds`)
- Max size: 10 — enforced in rules as `request.resource.data.teamMemberIds.size() <= 10`
- On aggregate CREATE: `teamMemberIds` must contain `request.auth.uid`
- On aggregate UPDATE (tech): `authUidOrEmpty() in resource.data.teamMemberIds` (any team member, not just creator)

### Legacy doc fallback
Docs created before `teamMemberIds` was added may lack the field. In rules, use:
```
resource.data.get('teamMemberIds', []).hasAll([authUidOrEmpty()])
```
Never dereference `resource.data.teamMemberIds` directly on docs that may predate the field.

### Deactivated team member behaviour
If a tech is deactivated/archived while in a `teamMemberIds` array:
- Their UID stays in the array (historical accuracy preserved)
- Remaining active teammates can still submit their contributions
- No cleanup of `teamMemberIds` is needed — the slot simply has no future submissions

## Archive (Soft-Delete) Pattern

### Never use doc.delete() for tech-owned records
```dart
// WRONG — permanent, unrecoverable
await _ref.doc(id).delete();

// CORRECT — soft archive
// NOTE: archiving a shared install job does NOT roll back aggregate consumed* counters.
// Admin flush + rebuild is the reconciliation path if discrepancy detected.
await _ref.doc(id).update({
  'isDeleted': true,
  'deletedAt': FieldValue.serverTimestamp(),
});
```

### Stream-layer filter (Dart side, no new indexes needed)
```dart
// In repository stream mapper — filter before mapping to model
.where((snap) => snap.data()?['isDeleted'] != true)
.map((snap) => Model.fromFirestore(snap))
```
Prefer Dart-layer filtering when the dataset per user is small (< 1000 docs). Only add a Firestore `where('isDeleted', isEqualTo: false)` query filter when scaling requires it — that would need a new composite index per query.

### Restore
```dart
await _ref.doc(id).update({
  'isDeleted': false,
  'deletedAt': FieldValue.delete(),
});
```

### Aggregate counter reconciliation
Archiving a shared install job does NOT decrement aggregate `consumed*` counters on `shared_install_aggregates`. This is intentional:
- Decrement would require a cross-collection transaction that exceeds free-tier read budget
- Admin can flush + rebuild aggregates if discrepancy is detected
- Document this in code comments at the archive call site
