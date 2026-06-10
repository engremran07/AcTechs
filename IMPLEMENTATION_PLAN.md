# IMPLEMENTATION PLAN

> **Governance note**: All multi-session plans MUST be in committed repo files (like this file).
> They MUST NOT be stored in `/memories/session/` — session memory is ephemeral and is wiped when the conversation ends or is compacted.

## Purpose

This file is the persistent, version-controlled record of the implementation plan for AC Techs.
It is updated at the end of every session that produces meaningful code changes.

---

## Current Status — version 2.2.10+99 (as of 2026-06-09)

The codebase is **production-clean** for Android internal distribution.
The v9–v12 audit series has addressed every P0/P1 critical finding.
Current focus: web surface quality + remaining test coverage gaps.

### Architecture (current)
- Flutter 3.44.0 (CI) / local still on 3.41.6 (upgrade pending)
- Dart SDK: ^3.11.0 (CI uses 3.12.1; local constraint upgrade pending local Flutter upgrade)
- Firebase Spark tier — Auth + Firestore + Hosting + App Check
- Riverpod 3.x (StreamProvider.autoDispose + derived Providers)
- GoRouter 17.x (shell routes, role-based redirects)
- Freezed 3.x (immutable models with @Default for Firestore field migration)
- MethodChannel 'com.actechs.pk/packages' — WhatsApp package detection, SecureScreen
- 3 independent domains: Jobs / In-Out (expenses+earnings) / AC Installs

### What was implemented (v2.2.9+98 and prior sessions)
- WhatsApp chooser: MethodChannel (PackageManager.getPackageInfo) — REG-013
- Bulk transfer: parallel Future.wait — REG-014
- Settlement cap UI warning — REG-015
- SecureScreen (FLAG_SECURE) on: invoice_settlements, admin_all_jobs, analytics, flush_database, reports_hub
- PhoneInputField with country picker (KSA default, E.164 normalization)
- JobSearchFilter / UserSearchFilter (phone + job ID search)
- Tech transfer UI on job_details_screen
- What's New dialog (once per version, locale-aware)
- CI: 80% coverage gate, version-drift gate, _changelog gate, Colors.white gate, App Check gate
- Pre-commit hook: skips version bump on docs-only commits
- docs/PRD.md + docs/ADR.md (10 architecture decisions)
- 7 new Dart lint rules in analysis_options.yaml

### Known Limitations (accepted — documented in MASTER_BLUEPRINT.md)
- Settlement view capped at 200 records (.limit(200))
- Settlement summary capped at 500 records (.limit(500))
- allJobs() capped at 150 documents
- No Crashlytics / crash reporting
- Phone numbers not retroactively normalized
- Dart SDK ^3.12.0 pending local Flutter SDK upgrade

### Genuine next priorities (from v11/v12 audit)
1. **TEST COVERAGE**: JobSearchFilter unit tests (12+ cases), WhatsAppLauncher.normalizeNumber() tests, transfer rule emulator tests
2. **WEB NAVIGATION**: ZoomDrawer → NavigationRail/persistent nav at desktop widths (>1024px)
3. **APP SHORTCUTS**: Wire Ctrl+F, Ctrl+E, Ctrl+P to admin_all_jobs_screen, analytics_screen, reports_hub_screen
4. **ResponsiveBody**: Apply to remaining 25+ screens that lack maxContentWidth constraint
5. **RESEND INVITATION**: Add "Resend Invitation" button in team screen for techs who never opened email
6. **PWA SCREENSHOTS**: Replace icon images in manifest.json with real app screenshots

The codebase is **production-clean**. The comprehensive 30-domain audit (D01–D30) confirmed by `flutter analyze --no-pub`, `flutter test` (423/423), and a full Firestore rules review is complete.

### All confirmed bugs resolved

| ID | File | Description | Status |
| --- | --- | --- | --- |
| NAV-001–004 | Multiple screens | `context.go()` on detail routes → `context.push()` | ✅ Fixed in 2.0.1+77 |
| NAV-005 | `tech_dashboard_screen.dart` | Rejected stat card nav destroyed back stack | ✅ Fixed in 2.0.6+82 |
| NAV-006 | `tech_dashboard_screen.dart` | Popup `view_history` nav destroyed back stack | ✅ Fixed in 2.0.6+82 |
| NAV-007 | `admin_dashboard_screen.dart` | Pending jobs mini-list nav destroyed back stack | ✅ Fixed in 2.0.6+82 |
| UI-001 | `reports_hub_screen.dart` | Hardcoded `Colors.green.shade700` on Excel button | ✅ Fixed in 2.0.6+82 |
| UI-002 | `admin_dashboard_screen.dart` | Approved shared installs error → silent `SizedBox.shrink()` | ✅ Fixed in 2.0.6+82 |
| ERR-001 | `approval_config_repository.dart` | Raw untyped `Exception(...)` thrown in catch block | ✅ Fixed in 2.0.6+82 |
| SEC-001 | `firestore.rules` | companies/app_settings using `isAuth()` | ✅ Already fixed in prior session (confirmed by direct file read) |

### Architecture highlights preserved

- **Firestore rules**: All 1600 lines verified. All helper functions use short-circuit `&&` (no conditional-get ternary). No duplicate `allow` verbs. All collections use `isAdmin() || isActiveUser()` (not raw `isAuth()`).
- **Provider budget**: ~9 concurrent Firestore listeners per tech session — all day-view providers derive from monthly listeners (no extra listeners).
- **Navigation**: `context.push()` on all detail routes; `context.go()` only for shell-root tab changes and auth redirects.
- **Exception handling**: All repository catch blocks use typed `FirebaseException` — no raw `Exception(...)`.
- **Dead code**: All zero-consumer providers and orphan widgets removed as of 1.5.x audit.
- **Collection strings**: All `.collection()` and `.doc()` calls use `AppConstants.*` constants.

---

## Next Priorities (Not Yet Implemented)

These were identified during the comprehensive re-audit but are not confirmed bugs — they are quality improvements. Address in future sessions, in order:

### Priority 1 — APK build for 2.0.6+82

No Firestore rules/indexes changed → no deploy needed before build.

```powershell
# Bump version (already at 2.0.6+82)
# flutter analyze --no-pub (already confirmed clean)
# flutter test (already confirmed 423/423)
flutter build apk --release --split-per-abi --no-tree-shake-icons
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" -s R5GL22RGT9V uninstall com.actechs.pk
& "$env:ANDROID_HOME\platform-tools\adb.exe" -s R5GL22RGT9V install d:\AcTechs\build\app\outputs\flutter-apk\app-release-arm64-v8a.apk
```

### Priority 2 — Test coverage expansion

Current baseline: 423 tests at ~60% line coverage. Coverage gate enforced at 60% in CI.
Areas with low coverage: admin flows, settlement state machine, shared install conflict resolution.

### Priority 3 — Web surface smoke test

The web build has not been tested since the zoom drawer integration. Run:

```powershell
flutter build web --release --no-wasm-dry-run
firebase deploy --only hosting --project actechs-d415e
```

### Priority 4 — CHANGELOG catch-up

CHANGELOG entries 1.5.4+62 through 1.5.7+65 (if those versions were built) are missing. If those versions were never shipped, no entries needed. SESSION_LOG has the implementation ledger.

---

## Governance Rules for This File

1. Update **before** starting a new feature session, not after
2. Move completed items from "Next Priorities" to "All confirmed bugs resolved" (or remove if non-bug)
3. Never delete lines from the "All confirmed bugs resolved" table — use ✅ to mark done
4. Keep the "Current Status" section accurate — update version on every session
5. This file is NOT a substitute for CHANGELOG.md (user-visible) or SESSION_LOG.md (implementation ledger). It is the **forward-looking plan** for the AI assistant.

---

## Session Continuity Protocol

To prevent plan loss (which happened when session memory was overwritten by a prior AI session):

1. **Read this file first** at the start of every new session
2. **Read SESSION_LOG.md** to identify the last completed session
3. **Read MASTER_BLUEPRINT.md** to confirm current app version
4. Never resume from scratch — always continue from the exact point of interruption
5. Update this file at the end of every session before the conversation ends

```text
Session start → read IMPLEMENTATION_PLAN.md + SESSION_LOG.md + MASTER_BLUEPRINT.md
Work completed → update SESSION_LOG.md + CHANGELOG.md + IMPLEMENTATION_PLAN.md + MASTER_BLUEPRINT.md
Then build/deploy if applicable
```
