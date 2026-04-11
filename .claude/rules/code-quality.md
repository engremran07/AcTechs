---
applies_to: "lib/**/*.dart,pubspec.yaml"
---

# Code Quality Rules — AC Techs

## ⛔ Dead Code — STRICT PROHIBITION

**Zero-consumer providers are FORBIDDEN.** Before adding a provider, verify at least one call site exists in an actual screen (`ref.watch`, `ref.read`, `ref.listen`). Invalidation-only calls in `auth_providers.dart` sign-out are NOT consumers.

**Orphan widget classes are FORBIDDEN.** A widget class in `lib/core/widgets/` with zero import usages in presentation files must be removed or moved to a commented-out archive branch.

**Detection checklist before every commit:**
```
grep -r "MyNewProvider" lib/ | grep -v "final MyNewProvider"   # must have at least 1 hit outside definition
grep -r "MyNewWidget" lib/ | grep -v "class MyNewWidget"       # must have at least 1 hit outside definition
```

**Examples of confirmed AC Techs dead code patterns (already removed — do NOT re-add):**
- `todaysAcInstallsProvider` — only invalidated, never watched
- `techAcInstallsProvider` — only invalidated, never watched
- `CursorWidget` — defined, never instantiated

---

## ⛔ Hardcoded Collection Strings — STRICT PROHIBITION

ALL Firestore `.collection()` and `.doc()` calls MUST use `AppConstants.*` constants.

```dart
// ❌ FORBIDDEN
_ref.collection('history')
_ref.collection('users')

// ✓ REQUIRED
_ref.collection(AppConstants.historySubCollection)
_ref.collection(AppConstants.usersCollection)
```

Current constants in `AppConstants`:
- `usersCollection` → `'users'`
- `jobsCollection` → `'jobs'`
- `expensesCollection` → `'expenses'`
- `earningsCollection` → `'earnings'`
- `companiesCollection` → `'companies'`
- `appSettingsCollection` → `'app_settings'`
- `acInstallsCollection` → `'ac_installs'`
- `sharedInstallAggregatesCollection` → `'shared_install_aggregates'`
- `invoiceClaimsCollection` → `'invoice_claims'`
- `historySubCollection` → `'history'`

If a new collection is needed, add it to `AppConstants` FIRST. Never inline the string.

---

## ⛔ Unused Dependencies — MANDATORY AUDIT

`pubspec.yaml` must contain ONLY packages that are imported somewhere in `lib/`. Packages removed (do NOT re-add):
- `gap` — use `SizedBox` for fixed spacing
- `path_provider` — no file system path reads needed on free-tier
- `firebase_auth_mocks` (dev) — tests use `fake_cloud_firestore` directly

Before adding a new package:
1. Search `lib/` to confirm there is no existing package that does the same thing
2. If adding, document the specific use case in a code comment in pubspec.yaml

---

## ⛔ Context Collapse — PREVENTION RULES

Context collapse = AI (or developer) forgets what already exists and re-implements it.

**Check before creating anything new:**
- Utility functions → check `lib/core/utils/` first (formatters, validators, etc.)
- Color/spacing values → ALL in `app_colors.dart` / `app_spacing.dart` — NEVER inline
- String formatting → use `AppFormatters.*` — do NOT write `DateFormat(...).format(...)`
- Error display → use `AppFeedback.error(context, message:...)` — NEVER raw `SnackBar` for errors
- Navigation → use `context.go()` or `context.push()` — NEVER `Navigator.push()`
- Repository patterns → check existing expense/earning/job repos before writing new data layer

**If you find a duplicate implementation:**
1. Delete the newer one
2. Update the call site to use the canonical implementation
3. Do NOT keep both "for now"

---

## ⛔ Navigation Misuse — STRICT PROHIBITION

`context.go()` is for shell-level replacement only. `context.push()` is for detail and edit routes.

```dart
// ❌ FORBIDDEN — replaces the back stack for a detail screen
context.go('/admin/settings');
context.go('/tech/summary');

// ✓ REQUIRED
context.push('/admin/settings');
context.push('/tech/summary');
```

Use `context.go()` only for tab changes, auth redirects, and other intentional route replacement.

---

## ⛔ Missing Localization Strings — PROHIBITION

User-visible strings MUST come from ARB files (`lib/l10n/`). This includes:
- Button labels, dialog titles, error messages, status badges, section headers
- Any string a user will read on-screen

```dart
// ❌ FORBIDDEN
Text('No jobs found')
ElevatedButton(child: Text('Submit'))

// ✓ REQUIRED
Text(context.l10n.noJobsFound)
ElevatedButton(child: Text(context.l10n.submit))
```

Exceptions (not user-visible, localization not required):
- Firestore field key strings
- Dev-mode debug labels
- PDF/Excel technical headers (use `l10n` where practical)

---

## ⛔ Missing Error Handling at Domain Boundaries

All `async` repository methods MUST wrap Firestore calls in try/catch and rethrow as `AppException` subclasses. Raw Firebase exceptions must NEVER surface to the UI.

```dart
// ❌ FORBIDDEN — raw exception propagates to widget
await _ref.collection(...).add(data); 

// ✓ REQUIRED
try {
  await _ref.collection(...).add(data);
} on FirebaseException catch (e) {
  throw SomeAppException.fromFirebase(e);
}
```

---

## Redundancy Prevention Checklist

When a PR adds new code, ask:
1. Is this provider replicated from an existing one? (e.g., two providers for same data but different scope)
2. Is this repository method doing the same thing as one already on the same class?
3. Is this screen widget extracting logic that should be in a shared provider?
4. Is this `if` branch duplicating logic from another `if` branch elsewhere in the same method?

If yes to any: refactor before merging.

---

## Technical Debt Signals (Red Flags)

The following patterns indicate vibe-coded technical debt has crept in:

| Signal | Action Required |
|--------|----------------|
| Provider defined but only used in `ref.invalidate()` | Remove provider + invalidation |
| Widget class with 0 usages in `lib/features/` | Remove widget |
| `.collection('literal-string')` anywhere in `lib/` | Replace with `AppConstants.*` |
| `import 'package:XYZ'` but no API of XYZ called | Remove import + consider removing from pubspec |
| `Navigator.push()` in a screen file | Replace with `context.push()` |
| `Color(0xFFxxxxxx)` outside `app_colors.dart` | Replace with `AppColors.*` |
| `TextStyle(...)` inline in a widget | Use `Theme.of(context).textTheme.*` |
| Duplicated model→map serialization inline | Extract to model's `toMap()` |
| Two screens doing same Firestore query independently | Consolidate into shared provider |
