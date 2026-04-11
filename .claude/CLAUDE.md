# AC Techs — AC Technician Management System

## Project Overview

Multi-role mobile + web app for AC installation company in Saudi Arabia. Technicians submit daily job records (AC installations, expenses). Admins approve/reject, view analytics, manage team, export to Excel. Tri-lingual: English, Urdu (RTL), Arabic (RTL).

## Stack

- **Framework**: Flutter 3.x (Android APK + Web)
- **Backend**: Firebase (Spark/free tier only) — Auth + Firestore
- **State**: Riverpod 3.x (AsyncNotifier, StateNotifier, StreamProvider)
- **Navigation**: GoRouter with auth redirect guards
- **Theme**: Material 3 Dark, arctic blue seed (#00D4FF)
- **Fonts**: Syne (headings) + DM Sans (body) for English via google_fonts; NotoNastaliqUrdu (Urdu RTL) + NotoNaskhArabic (Arabic RTL) bundled offline in assets/fonts/. AppFonts handles locale-aware selection.
- **Charts**: fl_chart
- **Animations**: flutter_animate, shimmer
- **Export**: excel + share_plus
- **i18n**: flutter_localizations + ARB files (en, ur, ar)
- **Models**: freezed + json_serializable
- **Package**: com.actechs.pk
- **Firebase Project**: actechs-d415e

## Commands

- `flutter run` → run on connected device
- `flutter run -d chrome` → run on web
- `flutter build apk --release` → release APK
- `flutter build web --release` → release web
- `dart run build_runner build --delete-conflicting-outputs` → generate freezed/json code
- `flutter gen-l10n` → generate localization files
- `flutter analyze` → lint check
- `flutter test` → run tests

## Architecture

- **Clean Architecture**: features/ with data/domain/presentation/providers layers
- **Feature folders**: auth, technician, admin, settings, **expenses** (earnings/expenses In/Out domain)
- **Core**: shared theme, widgets, errors, extensions, utils, constants
- **Routing**: GoRouter with shell routes for bottom nav, auth redirect guard
- **Models**: Freezed immutable classes with JSON serialization
- **Errors**: Custom sealed exception hierarchy — NEVER show raw Firebase/Flutter errors
- **Offline**: Firestore local persistence enabled, connectivity_plus for detection

## Domain Model Boundaries — CRITICAL

AC Techs has **three completely separate data domains**. NEVER mix them:

| Domain | Firestore | Model | Feature Folder |
|--------|----------|-------|---------------|
| **Jobs** | `jobs/` | `JobModel` | `features/jobs/` + `features/technician/` |
| **In/Out** | `expenses/` + `earnings/` | `ExpenseModel` + `EarningModel` | `features/expenses/` |
| **AC Installs** | `ac_installs/` | `AcInstallModel` | `features/expenses/` |

- **Jobs** = AC installation job records submitted by techs for client invoices (admin-approved)
- **In/Out** = tech's daily personal earnings/expenses (food, petrol, bracket installs, scrap sales)
- These are independent — a Job doc contains NO expense/earning sub-documents

### In/Out Navigation Rules
- Bottom nav In/Out → `/tech/inout` (no extra) → `DailyInOutScreen(selectedDate: null)` → today, form visible
- History card tap → `/tech/inout` with `extra: DateTime` → `DailyInOutScreen(selectedDate: date)` → form hidden
- Monthly overview → `/tech/summary` → `MonthlySummaryScreen` → read-only
- **NEVER** navigate history In/Out cards to `/tech/summary` — it's read-only and confusing

## Code Style

- Prefer const constructors everywhere possible
- Use trailing commas for multi-line parameter lists
- Riverpod providers: use code generation (@riverpod annotation) where possible
- All colors in app_colors.dart, all spacing in app_spacing.dart
- Business logic in repositories, never in widgets
- Widgets are stateless unless managing local animation/form state only
- Use context.l10n for all user-facing strings (never hardcode)
- Enums for status values: JobStatus.pending, JobStatus.approved, JobStatus.rejected
- Enums for roles: UserRole.technician, UserRole.admin

## Workflow

- Always run `flutter analyze` after making code changes
- Run `dart run build_runner build --delete-conflicting-outputs` after editing freezed models
- Run `flutter gen-l10n` after editing ARB files
- Test on both Android and Chrome
- Never commit google-services.json or firebase_options.dart to public repos
- Deploy Firestore rules/indexes after security changes: `firebase deploy --only firestore --project actechs-d415e`

## Navigation Rules

- `context.go()` is for shell-level replacement only: bottom-nav tab changes and auth redirects.
- `context.push()` is required for detail and edit flows such as `/admin/settings`, `/admin/companies`, `/admin/settlements`, `/admin/import`, `/tech/summary`, `/tech/settlements`, and job-detail routes.
- Never use `Navigator.push()` in presentation code.

## Back Navigation — ShellBackNavigationScope

- All shell-root scaffolds MUST use `ShellBackNavigationScope`.
- `isHome` is true only on the actual shell root (`/admin` or `/tech`).
- Non-home shell routes navigate back to `homeRoute` on back press instead of exiting.
- Home routes use the two-second double-back confirmation before exit.
- Do not add ad-hoc shell back handling with standalone `PopScope` unless the flow is intentionally different.

## SwipeActionCard Rules

- Always provide a stable key at call sites: `key: ValueKey(item.id)`.
- Never use `UniqueKey()` for swipe cards.
- `confirmDismiss` is spring-back behavior by default; callbacks handle the action without removing the row automatically.

## Refresh Pattern

- Use `ArcticRefreshIndicator` instead of raw `RefreshIndicator` so styling and haptics stay consistent.

## Version Policy

- versionCode (number after `+` in pubspec version) must ALWAYS increase across releases
- Never reset build number
- Current minimum next versionCode: 16

## Shared Install Team System Rules

1. `teamMemberIds[0]` is ALWAYS the createdBy uid (first submitter)
2. `teamMemberNames` is a parallel array — same index order as `teamMemberIds`
3. Max team size: 10 — enforced in both Firestore rules (`teamMemberIds.size() <= 10`) and UI
4. New contributions require caller uid to be in aggregate's existing `teamMemberIds` list
5. Invoice totals (`sharedInvoice*` fields) are immutable after first submission — only admin can change via `validSharedAggregateAdminUpdatePayload()`
6. **Aggregate counter reconciliation:** Archiving a shared install job does NOT decrement aggregate `consumed*` counters. If aggregate discrepancy is detected, admin must flush + rebuild. Never attempt counter rollback in app layer — it requires a cross-collection transaction that breaks free-tier read budget. Document this constraint in code comments at the archive call site.
7. **Deactivated team member:** If a tech is archived/deactivated while listed in a `teamMemberIds` array, their UID remains in the array (historical accuracy). Remaining active teammates can still submit their contributions. The deactivated tech's slot simply has no future submissions. No cleanup of `teamMemberIds` is needed or desired.

## Expense/Earning Archive Rules

1. **Never call `doc.delete()` for technician-owned records** (expenses, earnings, AC installs)
2. Always use `archiveExpense()`, `archiveEarning()`, `archiveInstall()` repository methods instead
3. Restoration requires admin action OR in-session undo SnackBar (4-second window for techs)
4. `isDeleted: bool` (default false) and `deletedAt: DateTime?` must be present on all archivable models
5. Stream mappers must filter out `isDeleted == true` docs in Dart before mapping to model objects

## Settlement System Rules

1. Never hardcode settlement status strings in Dart; use `JobSettlementStatus.*.firestoreValue`
2. Any new field added to `JobModel` must be evaluated for:
	- `technicianMutableJobUpdate()` affected keys in `firestore.rules`
	- `settlementFieldsOnlyChanged()` and `settlementFieldsUnchanged()` in `firestore.rules`
	- `validJobCreatePayload()` where relevant
3. Maximum settlement batch size: 200 jobs
4. `confirmSettlementBatch` and `rejectSettlementBatch` must remain transactional
5. Settlement transition chain must remain:
	- unpaid -> awaiting_technician -> confirmed
	- unpaid -> awaiting_technician -> correction_required -> awaiting_technician -> disputed_final

## Error Philosophy

Every user-facing message is custom-written, contextual, and tri-lingual. No raw exception strings, no "Error: PERMISSION_DENIED", no default SnackBars. Custom error cards with icon, title, description, action button.

## Breakage Chain Reference

When changing any of these, ALL downstream items must be updated in the same commit:

**Chain 1 — Settlement status string** (e.g. `'awaiting_technician'`):
  → Update `JobSettlementStatus.*.firestoreValue` in the enum
  → Update `firestore.rules`: `validAdminSettlementTransition`, `validTechSettlementTransition`
  → Update seeded data in `scripts/tests/`
  → NEVER use string literals in Dart — always use `.firestoreValue`

**Chain 2 — New field added to `JobModel`**:
  1. Run `dart run build_runner build --delete-conflicting-outputs`
  2. Evaluate for `technicianMutableJobUpdate()` affected keys in `firestore.rules`
  3. Evaluate for `settlementFieldsOnlyChanged()` if settlement-only field
  4. Evaluate for `validJobCreatePayload()` if required at creation
  5. Evaluate for `settlementFieldsUnchanged()` if must be immutable during settlement

**Chain 3 — Change `InvoiceUtils.normalize()`**:
  → WARNING: All `invoice_claims` doc IDs are built from normalized invoice numbers
  → Any normalization change invalidates ALL existing claim docs — requires data migration
  → Invoice normalization is FROZEN without a migration plan

**Chain 4 — Add/remove team member slots in shared install**:
  → Max 10 — enforce in UI: Submit button disabled when `_selectedTeamMembers.length >= 9`
  → `teamMemberIds[0]` must ALWAYS be the createdBy uid (first submitter)
  → `teamMemberNames` is a parallel array (same index order as `teamMemberIds`)
  → Aggregate's `teamMemberIds` is immutable after create — only admin override via `validSharedAggregateAdminUpdatePayload()`

## Documentation Sync Rule

When you change `AppConstants` collection names, update ALL of these in the same commit:
1. `.claude/CLAUDE.md` — Domain Model Boundaries table
2. `.claude/rules/firebase.md` — Domain Collection Boundaries table
3. `.claude/rules/in-out-model.md` — Three Completely Separate Domains table
4. `.claude/skills/firestore-patterns/SKILL.md` — Collections section
5. `.github/instructions/models.instructions.md` — Domain Separation table
6. `firestore.rules` — `match /collection_name/{docId}` paths

## Bottom Navigation — Authoritative Reference

```
TechShell:  5 tabs — Home / Submit / In-Out / History / Settings
AdminShell: 4 tabs — Dashboard / Approvals / Analytics / Team
```
Settlement and shared-install screens are accessed from dashboard cards or history badges.
They are NOT bottom-nav tabs. Never write "4 tabs" for tech in any documentation.

## Recent Product Behaviors To Preserve

- Invoice display is normalized (no forced `INV-` prefix in UI)
- Historical import supports sheet-aware period naming and metadata notes
- Shared AC-type filtered job list route is used by both technician and admin dashboards
- Database flush has optional non-admin user deletion with explicit destructive warning UI

## Technical Debt Prevention — Clean-as-You-Go

This codebase runs on Firebase free tier (Spark plan). Every unused provider = one extra Firestore listener when active. Every unused dependency = APK bloat. Every hardcoded collection string = a rename liability.

### Five Non-Negotiable Pre-Commit Checks

1. **Zero dead providers**: Any new provider must have at least one `ref.watch/read/listen` call site. `ref.invalidate()` in sign-out does NOT count as a consumer.
2. **Zero hardcoded collection strings**: ALL `.collection()` and `.doc()` calls in `lib/` must use `AppConstants.*` names. Add the constant FIRST, then use it.
3. **Zero unused dependencies**: Every package in `pubspec.yaml` must be imported somewhere in `lib/`. Verify with `grep -r "package:X" lib/` before adding.
4. **Zero orphan widgets in core**: Any widget class in `lib/core/widgets/` must be instantiated in at least one screen in `lib/features/`.
5. **`flutter analyze` must be clean**: "No issues found!" — zero warnings, zero infos, zero hints. Any lint issue is a hard stop.

### Context Collapse Prevention

Context collapse occurs when AI (or developer) forgets what already exists and duplicates it. Before writing anything new:
- **Utility function** → check `lib/core/utils/` (formatters, validators, invoice utils)
- **UI pattern** → check `lib/core/widgets/` (cards, dialogs, form fields, swipe actions)
- **Repository method** → check existing repo class before adding a nearly-identical query
- **Localization string** → check all 3 ARB files; never add a new key for something that already exists
- **Firestore pattern** → check `firestore.rules` functions before duplicating validation logic

### Vibe-Coded Debt Signals — Red Flags

| Signal | Action |
|--------|--------|
| Provider only in `ref.invalidate()` | Remove provider + invalidation |
| Widget class with 0 screen usages | Remove widget |
| `.collection('literal')` in `lib/` | Replace with `AppConstants.*` |
| Imported package with 0 API calls | Remove import + remove from pubspec |
| `Navigator.push()` in a screen | Replace with `context.push()` |
| Inline `Color(0xFFxxxxxx)` | Replace with `ArcticTheme.*` constant |
| Inline `TextStyle(...)` | Use `Theme.of(context).textTheme.*` |
| Two providers reading same Firestore path | Consolidate into one |

