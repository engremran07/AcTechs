---
name: firestore-patterns
description: Firestore query patterns, security rules, and offline sync strategies for AC Techs. Activate when working with Firestore collections, queries, security rules, or offline behavior.
---

# Firestore Patterns — AC Techs

## Collections
- `users/{userId}` — User profiles (uid, name, role, isActive, createdAt, language)
- `jobs/{jobId}` — Job records (auto-id, all work units, expenses, status, timestamps)

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
