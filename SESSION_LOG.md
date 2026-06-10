# SESSION_LOG

## 2026-06-11 — v12 Audit Implementation — APK v2.3.1+100

- **P0 WA-001/REG-016**: Samsung One UI always opened Business when Personal was selected — root cause: Samsung ActivityManagerService ignores `intent://` `package=` parameter; fix: added `openWhatsApp` handler to `MainActivity.kt` using `Intent.setPackage()`; updated `_openInPackage()` in `whatsapp_launcher.dart` to route through `MethodChannel` instead of `launchUrl()`
- **P0 GOV-P0-001/REG-017**: Version collision `2.2.10+99` and `2.3.0+99` shared versionCode=99; pre-commit hook produced wrong version name; manually corrected to `2.3.1+100`
- **WA-002**: submit_job_screen team notification → `showChooserWithMessage` (was `openChatWithMessage`)
- **SEC-001**: SecureScreen added to `approvals_screen`, `settlement_inbox_screen`, `tech_profile_screen` — 7 screens now protected total
- **WEB-001**: Admin shell now shows `NavigationRail` on desktop (kIsWeb + ≥1024px); body constrained to `Responsive.maxContentWidth()`
- **WEB-005**: deploy-web.yml — added `flutter test` step before web build
- **PLAY-005**: release.yml — ProGuard `mapping.txt` archived as 365-day artifact
- **Governance**: REG-016, REG-017 added to REGRESSION_REGISTRY; `_changelog` `2.3.1` entry added; all governance docs synced to `2.3.1+100`
- Zero `flutter analyze --no-pub` issues confirmed before build
- Build: `flutter build apk --release --split-per-abi --no-tree-shake-icons`

## 2026-06-09 — v12 Audit Implementation — deep audit cross-check + web surface

- **P0 deploy-web.yml App Check fix**: Added `--dart-define=FIREBASE_APP_CHECK_WEB_KEY` + App Check secret verification (exit 1) to deploy-web.yml build step — every live web deployment now has App Check protection
- **deploy-web.yml flutter version**: Changed to `flutter-version-file: .flutter-version` (was hardcoded 3.41.6)
- **build-apk.yml flutter version**: Changed default path to `flutter-version-file: .flutter-version`
- **deploy-web.yml dead fallback removed**: Removed `elif [ -f lib/firebase_options.dart ]` (file not checked in since v2.1.0+87)
- **P0 IMPLEMENTATION_PLAN.md rewrite**: Updated from v2.0.6+82 to v2.2.9+98 — full current architecture, all known constraints, genuine next priorities
- **CI gate: IMPLEMENTATION_PLAN.md version sync**: New hygiene gate added to ci.yml
- **Responsive.dart desktop breakpoints**: Added `desktop = 1024`, `desktopWide = 1440`, `isDesktop()`, `isDesktopWide()`, `maxContentWidth()` returns 900/1200px for desktop
- **SecureScreen expanded**: Added to admin_all_jobs_screen, analytics_screen, flush_database_screen, reports_hub_screen (4 new screens; was 1 screen only)
- **Settings company phone → PhoneInputField**: Replaced plain TextFormField in branding dialog with PhoneInputField (E.164 normalization, country picker)
- **web/index.html**: Added viewport meta tag (WEB-011), loading spinner (WEB-010) with brand colours and fade-on-ready
- **normalize_invoice_data.js production guard**: Added SEC-004 guard — script refuses to run unless `FIRESTORE_EMULATOR_HOST` is set or `FORCE_PRODUCTION=1` is explicit
- **analysis_options.yaml**: Added `cancel_subscriptions` rule; verified zero issues
- Zero `flutter analyze --no-pub` issues confirmed before build
- Build: `flutter build apk --release --split-per-abi --no-tree-shake-icons`
- Device: uninstalled + installed arm64 APK on R5GL22RGT9V

## 2026-06-09 — v11 Audit Implementation — APK v2.2.7+96 → v2.2.8+97

- **P0 WhatsApp Fix**: Root cause confirmed — `canLaunchUrl()` cannot distinguish packages; fixed with `MethodChannel('com.actechs.pk/packages')` calling `PackageManager.getPackageInfo()` in `MainActivity.kt`; `_openInPackage()` now has `try/catch` fallback to `wa.me`; both bugs documented in REG-013
- **MainActivity.kt extended**: added `isInstalled` (WA fix) + `setSecureScreen` (STK-001) MethodChannel handlers
- **SecureScreen utility**: `lib/core/utils/secure_screen.dart` — platform channel to enable/disable `FLAG_SECURE` for sensitive screens; wired into `InvoiceSettlementsScreen`
- **BLK-001/005**: `bulkTransferJobs()` and `bulkTransferJobsAsTech()` now use `Future.wait()` parallel execution instead of serial loops
- **PER-001**: Settlement screen shows banner when 200-record cap is hit
- **GOV**: `REGRESSION_REGISTRY.md` entries REG-013, REG-014, REG-015 added; `MASTER_BLUEPRINT.md` "Known Limitations" + "Supported Platforms" sections added
- **Stack**: Flutter pinned to 3.44.0 in all CI workflows; `firebase_app_check ^0.4.2`; `google-services 4.4.2`; 34 transitive deps upgraded; `.flutter-version` file created
- **SEC-001**: App Check CI gate changed from warning to hard `exit 1` failure
- **ARB**: `whatsappBusinessSubtitle`, `whatsappPersonalSubtitle`, `settlementCapWarning` added to en/ur/ar
- **What's New**: `_changelog` entry `2.2.8` added
- Zero `flutter analyze` issues confirmed before build
- Build: `flutter build apk --release --split-per-abi --no-tree-shake-icons`

- Scope: Full implementation of all P1/P2 findings from the v9 ultimate audit report.
- Critical fixes:
  - AUTH-003: Added `allJobsProvider` + `pendingTransferRequestsProvider` to `signOut()` invalidation list in `auth_providers.dart`
  - CQA-001: Renamed `transferredByAdminId` → `transferredByTechId` in `transferJobAsTech()` — correct audit trail for tech-initiated transfers
  - WA-001: `WhatsAppLauncher.normalizeNumber()` now prepends country code for local '0X...' numbers (KSA default)
  - WA-005: WhatsApp chooser bottom sheet labels use localized ARB keys
  - SEC-002: `--dart-define=FIREBASE_APP_CHECK_WEB_KEY` added to all web build steps in ci.yml and release.yml
  - CI-001: Coverage threshold raised from 60% to 80%
- Features added:
  - **PhoneInputField widget**: country code picker (95+ countries, KSA default), E.164 normalization, `CountryDialCode` model with `PhoneDisplayExtension.toDisplayPhone()`
  - **JobSearchFilter / UserSearchFilter**: centralised search replacing three copy-pasted lambdas; adds phone-number (digits-only) and Firestore doc ID search
  - **Tech transfer UI in JobDetailsScreen**: request transfer button + cancel pending request button; respects `techTransferAllowed` + `techTransferRequiresApproval`; imported `activeTechniciansForTeamProvider`
  - **AAB build**: `flutter build appbundle --release` added to `release.yml`; AAB artifact uploaded alongside APKs
  - **CI version-drift gate**: new hygiene step in `ci.yml` that fails if `MASTER_BLUEPRINT.md` version ≠ `pubspec.yaml` version
- Screens updated: `approvals_screen`, `admin_all_jobs_screen`, `job_history_screen`, `team_screen` (search + phone), `job_details_screen` (transfer UI)
- New files: `lib/core/models/country_dial_code.dart`, `lib/core/widgets/phone_input_field.dart`, `lib/core/utils/job_search_filter.dart`
- L10n: 9 new strings in en/ur/ar ARBs
- Zero-problems policy: `flutter analyze --no-pub` exits 0 — verified before build
- Build: `flutter build apk --release --split-per-abi --no-tree-shake-icons` + `flutter build appbundle --release`
- Device: uninstalled + installed arm64 APK on R5GL22RGT9V
- Committed and pushed

- Scope: WhatsApp chooser, phone field in user creation, transferred badge, multi-select bulk actions in admin all-jobs screen, allJobs() limit, What's New dialog, governance docs sync.
- Bug fixes (shipped as v2.2.1+90 earlier in session):
  - Fixed "Request Transfer" button shown when `techTransferRequiresApproval` is false — now performs direct transfer
  - Fixed "No active technicians" error — switched to `activeTechniciansForTeamProvider`
  - Added `JobRepository.transferJobAsTech()` + `techDirectTransferAllowed()` Firestore rule
- Features:
  - **WhatsApp chooser**: `WhatsAppLauncher.showChooser()` shows bottom sheet with Business / Regular options when both apps installed; 8 call sites migrated; batch loop keeps `openChatWithMessage` direct
  - **Phone in create user**: `_showAddTechnicianDialog` now has optional phone field; `createUser()` accepts and saves `phone` param
  - **Transferred badge**: appears on `_HistoryJobCard` and `_AllJobTile` when `transferredFromTechId.isNotEmpty && !isTransferPending`; transfer details (from whom + date) added to `job_details_screen.dart`
  - **Bulk job actions (admin)**: `_AdminAllJobsScreenState` has `_selectedJobIds` + `_isBulkProcessing`; long-press enters selection mode; `BulkActionBar` with Transfer and Cancel-Transfer actions; `_showBulkTransferDialog()` and `_bulkCancelTransferRequests()` methods; `_AllJobTile` updated with `isSelected`/`onTap`/`onLongPress` params
  - **allJobs limit**: `allJobs()` stream capped at `.limit(150)`; limit-note banner shown in AdminAllJobsScreen
  - **Bulk repo methods**: `bulkTransferJobs`, `bulkCancelTransferRequests`, `bulkRequestJobTransfers`, `bulkTransferJobsAsTech` added to `JobRepository`
  - **What's New dialog**: `WhatsNewChecker.checkAndShow(context)` called from both `TechShell` and `AdminShell` `initState` via `addPostFrameCallback`; compares `PackageInfo` version+buildNumber against `SharedPreferences` `last_seen_version`; `WhatsNewDialog` shows changelog for current + 2 previous versions in user's locale; `AppConstants.lastSeenVersionKey` added
  - **L10n**: 9 new strings in en/ur/ar ARBs
- Zero-problems policy: `flutter analyze --no-pub` exits 0 — "No issues found!"
- Build: `flutter build apk --release --split-per-abi --no-tree-shake-icons` → arm64-v8a 31.2 MB
- Device: uninstalled + installed arm64 APK on R5GL22RGT9V
- APK copy pushed to `/sdcard/Download/AcTechs-v2.2.2+91-arm64.apk`
- Committed as `cfcadc7` — pre-commit hook bumped pubspec to v2.2.3+92

- Scope: Full implementation of all 30 findings from the v8 audit report; new Job Transfer admin feature; enforceMinimumBuild runtime gate; per-ABI APK build + deployment.
- Security:
  - SEC-001: `firebase_options.dart` removed from git tracking (`git rm --cached`); committed + pushed; user must rotate exposed API keys in Firebase Console (Android: AIzaSyA-G22X…, Web: AIzaSyDETPeE…)
  - `adminJobTransferAllowed()` Firestore security function: limits transfer payload to 6 specific fields, enforces `unpaid` status, validates `transferredAt == request.time` and `transferredByAdminId == request.auth.uid`
- Features added:
  - **Job Transfer**: admin presses Transfer in the job verification dialog → picks active tech from dropdown → calls `JobRepository.transferJob()` → audit fields written to Firestore; Transfer button only shown for unpaid jobs
  - **enforceMinimumBuild (BIZ-001)**: `app_router.dart` reads `appBuildNumberProvider` and `approvalConfigProvider`; if tech APK build < `minSupportedBuildNumber`, router redirects to `/update-required`; `UpdateRequiredScreen` created
- Fixes:
  - AND-001: WhatsApp + WhatsApp Business package visibility queries in AndroidManifest
  - CQA-001/002/003: Duplicate constants (`_kRememberMeKey`, `_kRememberEmailKey`, `_kClearFirestoreCacheOnLaunchKey`, web/android ActionCodeSettings literals) moved to `AppConstants`; callers updated
  - CQA-004: Duplicate `.tmp/` block removed from `.gitignore`
  - FBR-004: `archiveNonAdminUsersInChunks()` query now filters `isActive == true && role != admin` — prevents re-archiving already-inactive users
  - FBR-001: Composite Firestore index `status + isDeleted + submittedAt` added for `jobs` collection
  - OPS-001: Flush screen Step 1 now shows export-before-flush recommendation card with link to Analytics
  - UX-001: Historical import preview dialog shows locked-period warning when parsed jobs predate `approvalConfig.lockedBeforeDate`
  - UX-002: Historical import validates keyword + technician + company before opening file picker
- Build:
  - L10n: 15 new ARB strings added across en/ar/ur (transfer flow, export-before-flush, locked-period warning, update-required)
  - `JobModel` freezed: 4 new transfer audit fields added; `build_runner` regenerated
  - `flutter analyze` clean before build
  - Firestore rules deployed; Firestore indexes deployed
  - `flutter build apk --release --split-per-abi --no-tree-shake-icons`
  - Uninstalled + installed arm64-v8a APK on R5GL22RGT9V
  - APK copy pushed to `/sdcard/Download/AcTechs-v2.1.0+87-arm64.apk`
  - Committed and pushed as v2.1.0+87

## 2026-05-31 — Android/Play Services exhaustive audit — APK v2.0.9+85

- Scope: Exhaustive audit of all Android platform features, manifest, autofill signals, and security configs; implemented all genuine findings; rebuilt per-ABI APK; installed on R5GL22RGT9V.
- Audit findings:
  - `android:supportsRtl` — MISSING from AndroidManifest.xml despite tri-lingual (Arabic/Urdu) RTL support; FIXED — added to `<application>` element
  - `android:networkSecurityConfig` — MISSING; created `network_security_config.xml` trusting only system CAs with cleartext blocked; added to manifest
  - `android:dataExtractionRules` — MISSING for Android 12+ backup control; created `data_extraction_rules.xml` excluding all domains; added to manifest (complements existing `fullBackupContent="false"` for API 30-)
  - Change-password autofill — dialog had no `AutofillGroup`, no `autofillHints`, and no `finishAutofillContext` call; FIXED — wrapped form in `AutofillGroup`, added hints, added `TextInput.finishAutofillContext(shouldSave: true)` before dismiss
  - Login screen autofill: FALSE POSITIVE — already has `AutofillGroup`, email/password hints, and `finishAutofillContext(shouldSave: true)` ✅
  - Predictive back: FALSE POSITIVE — `enableOnBackInvokedCallback="true"` already set ✅
  - Splash screen: FALSE POSITIVE — `windowSplashScreenAnimatedIcon` + `windowSplashScreenBackground` already in values-v31/styles.xml ✅
  - Adaptive icons: FALSE POSITIVE — mipmap-anydpi-v26/ic_launcher.xml uses foreground + background layers ✅
  - HTTPS enforcement: FALSE POSITIVE — `usesCleartextTraffic="false"` already set ✅
  - Backup disabled: FALSE POSITIVE — `allowBackup="false"` + `fullBackupContent="false"` ✅
  - Locale config: FALSE POSITIVE — `locales_config.xml` with en/ur/ar ✅
  - firebase_messaging / POST_NOTIFICATIONS: N/A — no FCM push in this app
  - App shortcuts: N/A — not warranted (no strings.xml infrastructure, low ROI for internal tool)
- All 423 tests pass; `flutter analyze` clean.
- Built: arm64-v8a (per-ABI split), armeabi-v7a, x86_64
- Installed: uninstalled v2.0.8+84 → installed app-arm64-v8a-release.apk v2.0.9+85 on R5GL22RGT9V

## 2026-05-30 — v7 Audit implementation: Phase 0 D01–D03 + Phase 1 D05/D08 + D16 CI — APK v2.0.8+84

- Scope: Implemented confirmed non-false-positive findings from the Ultimate Master Audit Plan v7 (25 domains, 4 phases). Most Phase 0–2 items verified as false positives. Genuine fixes applied across 5 files.
- Phase 0 D01 Firestore security — all 8 sub-findings verified in firestore.rules:
  - D01-F001 (settlement temporal guards): ALREADY DONE in prior session ✅
  - D01-F002 (email spoofing in validOwnUserUpdate): FALSE POSITIVE — `authEmailOrEmpty()` guard already present
  - D01-F003 (approvalConfigData crashes): FALSE POSITIVE — all callers guard with `!exists()` first
  - D01-F004 (isAdmin missing role): FALSE POSITIVE — `userData().role is string` already validates
  - D01-F005 (invoice_claims list asymmetry): FALSE POSITIVE — intentional design, techs use `get` by known ID
  - D01-F006 (settlementBatchId immutability): FALSE POSITIVE — Cases 2 and 3 enforce `== resource.data.get(...)`
  - D01-F007 (settlement batch createdAt guard): FALSE POSITIVE / N/A — no separate batch collection
  - D01-F008 (reviewedAt pattern in auto-approve): FALSE POSITIVE — already `== request.time` in all three collections
- Phase 0 D02 CI/CD:
  - D02-F001/F002 (keystore integrity): DONE in prior session — release.yml verification step ✅
- Phase 0 D03 web (dart:io): FALSE POSITIVE — conditional imports already handle it
- Phase 1 D04 auth:
  - userStream() manual StreamController: FALSE POSITIVE — `onCancel` properly cancels subscription and closes controller
  - _syncProfileFromAuth() error swallowing: Accepted as intentional — background sync, logged but not propagated
- Phase 1 D05:
  - D05-F002 clamp overflow: DONE in prior session ✅
  - Other D05 sub-items: FALSE POSITIVES
- Phase 1 D08 UI:
  - Submit button loading state: FALSE POSITIVE — `_isSubmitting` + spinner already implemented
  - Month nav tap targets: FALSE POSITIVE — Material 3 `IconButton` default is 48dp
- Phase 1 real fixes:
  - **`settings_screen.dart`**: 3 approval-toggle error handlers `l.couldNotExport` → `l.genericError` (D08/ERR-002)
  - **`admin_shared_installs_screen.dart`**: raw `e.toString()` → `l.genericError` in error handler (D08/ERR-003)
  - **`reports_hub_screen.dart`**: 12 raw catch blocks → `_reportError()` helper (D08/ERR-004)
- Phase 2 D16 CI/CD real fix:
  - **`.github/workflows/ci.yml`**: Added `timeout-minutes: 15` to `analyse`, `timeout-minutes: 20` to `test`, `timeout-minutes: 30` to `build-debug` jobs (D16/CI-002)
- Phase 2 D09/D10/D11 — verified as false positives:
  - canTechnicianEdit correctionRequired: FALSE POSITIVE — correction_required is settlement state, not job-edit opportunity
  - normalizeWithCompanyPrefix bounds: FALSE POSITIVE — substring calls are guarded by startsWith/length checks
  - invoiceClaimDocumentId 'unknown_invoice': FALSE POSITIVE — intentional collision prevention
- Version bump: 2.0.7+83 → 2.0.8+84
- Verification:
  - `flutter analyze --no-pub` — "No issues found!"
  - `flutter test` — 423/423 passed

## 2026-05-28 — Navigation/color/error bug fixes + comprehensive re-audit — version 2.0.6+82

- Scope: Resumed from compacted prior session; fixed all 6 confirmed bugs; ran comprehensive re-audit of all 117 Dart files + Firestore rules; confirmed codebase is production-clean; updated CHANGELOG, SESSION_LOG, and IMPLEMENTATION_PLAN
- Bugs fixed:
  - **NAV-005** (`tech_dashboard_screen.dart` L206): "rejected" stat card `context.go('/tech/history')` → `context.push('/tech/history')` — prevents back-stack destruction
  - **NAV-006** (`tech_dashboard_screen.dart` L428): popup menu "view_history" branch `context.go('/tech/history')` → `context.push('/tech/history')` — same fix
  - **NAV-007** (`admin_dashboard_screen.dart` L332): pending jobs list `context.go('/admin/approvals')` → `context.push('/admin/approvals')` — prevents back-stack destruction
  - **UI-001** (`reports_hub_screen.dart`): Excel button `Colors.green.shade700` → `ArcticTheme.arcticSuccess` — eliminates last hardcoded color in lib/
  - **UI-002** (`admin_dashboard_screen.dart`): approved shared installs error handler `const SizedBox.shrink()` → `_DashCard` with dash value — errors are no longer silently swallowed
  - **ERR-001** (`approval_config_repository.dart`): raw `Exception('Failed to update config: ...')` → `on FirebaseException { rethrow; }` — typed exception hierarchy preserved
- Comprehensive re-audit: Explore subagent scanned all 117 Dart files + Firestore rules; confirmed one reported finding (SEC-001: companies/app_settings `isAuth()`) was already fixed in a prior session — both collections already use `isAdmin() || isActiveUser()`; no additional genuine issues found
- Governance: CHANGELOG.md updated with 2.0.1+77 and 2.0.6+82 entries; IMPLEMENTATION_PLAN.md created at repo root; session memory note re: plan persistence (plans must be in repo files, not session memory)
- Verification:
  - `get_errors` — 0 issues on all 4 modified files
  - `flutter analyze --no-pub` — "No issues found!" (ran in 10.1s)
  - `flutter test` — 423/423 passed
- Version: bumped 2.0.5+81 → 2.0.6+82

## 2026-05-11 — 30-domain audit (D01–D30): 18 confirmed bugs fixed — APK v2.0.1+77

- Scope: Full multi-phase audit across all domains; Phase 0 previously completed; Phases 1–15 implemented this session
- False positives confirmed and skipped: D10-F003/F004 (archiveExpense/archiveEarning already have try/catch), D09-F005/F007 (hardDeleteJob/restoreJob admin-only — no period lock by design), D04-F001/F002 (settlement methods already exist)
- Changes implemented:
  - **`auth_providers.dart`** signOut(): Added 10 missing `ref.invalidate()` calls — `approvedSharedInstallsProvider`, `adminJobSummaryProvider`, `adminScopedJobSummaryProvider`, `filteredAdminJobsProvider`, `techJobsByAcTypeProvider`, `technicianJobSummaryProvider`, `monthlyJobsProvider`, `monthlyTechnicianJobSummaryProvider`, `userSharedInstallStatusProvider`, `monthlyTechnicianInOutSummaryProvider` — prevents stale state after sign-out.
  - **`firestore.rules`**: Fixed `reviewedAt is timestamp` → `reviewedAt == request.time` in auto-approve create sections for expenses, earnings, and ac_installs — prevents client from backdating `reviewedAt`.
  - **`job_repository.dart`** `approvedSharedInstalls()`: Added `.where((job) => !job.isDeleted)` filter so soft-deleted shared installs don't appear in the approved list.
  - **`job_repository.dart`** `resubmitForApproval()`: Added `_periodLockGuard.ensureUnlockedDocument()` call so techs cannot resubmit a job in a locked period.
  - **`job_repository.dart`** `fetchStaleSharedAggregates()`: Replaced `Duration(days: 30)` with `Duration(days: AppConstants.staleAggregateThresholdDays)`.
  - **`expense_repository.dart`** `restoreExpense()`: Added `on PeriodException { rethrow; }` so period lock errors surface instead of being swallowed as generic `ExpenseException.saveFailed()`.
  - **`earning_repository.dart`** `restoreEarning()`: Same PeriodException rethrow fix.
  - **`tech_dashboard_screen.dart`**: Fixed 3 `context.go('/tech/submit')` → `context.push('/tech/submit')` (empty-state button, FAB, shared install card tap) — prevents back-stack destruction.
  - **`company_selector_field.dart`**: Changed `includeNoCompanyOption` default from `true` → `false` — safe, all existing call sites explicitly pass `false`.
  - **`app_constants.dart`**: Added `noCompanyKey = 'no-company'` and `staleAggregateThresholdDays = 30`.
  - **`invoice_utils.dart`**: Replaced `'no-company'` literal with `AppConstants.noCompanyKey`; added `app_constants.dart` import.
  - **`analysis_options.yaml`**: Added 4 lint rules: `unnecessary_const`, `avoid_empty_else`, `use_build_context_synchronously`, `close_sinks`.
  - **`auth_repository.dart`** `userStream()`: Added `await controller.close()` in `onCancel` callback to satisfy `close_sinks` lint and properly release all resources.
  - **`.github/workflows/ci.yml`**: Added `timeout-minutes: 15` to `firestore-rules` job — prevents indefinite CI hang.
  - **`pubspec.yaml`**: Version bumped 1.5.7+65 → 2.0.0+76.
- Verification:
  - `get_errors` — 0 issues on all modified files
  - `flutter analyze --no-pub` — "No issues found!" (ran in 13.0s)

## 2026-05-11 — Stats card data accuracy: rejected/deleted job filtering in technician summaries

- Scope: Stats cards on technician and admin dashboards showing incorrect data; 3 utility files fixed
- Root cause: All three technician summary utilities were accumulating units, earnings, and expenses for **rejected** entries; `technician_job_summary.dart` also lacked a `isDeleted` guard and used full invoice `totalUnits` for shared installs instead of the technician's own `sharedContributionUnits`.
- Changes implemented:
  - **`lib/core/utils/technician_job_summary.dart`**: Added `if (job.isDeleted) continue;` at top of loop; moved unit/bracket accumulation after `if (job.status == JobStatus.rejected) continue;`; shared installs now use `job.sharedContributionUnits` when > 0, falling back to `job.totalUnits` for solo/legacy records.
  - **`lib/core/utils/technician_in_out_summary.dart`**: Added `if (earning.isRejected) continue;` in earnings loop and `if (expense.isRejected) continue;` in expenses loop.
  - **`lib/core/utils/technician_day_in_out_summary.dart`**: Added `if (earning.isRejected) continue;` and `if (expense.isRejected) continue;` after the `inRange()` guards in both loops.
  - **`test/unit/utils/technician_job_summary_test.dart`**: Updated stale expectations (`totalUnits 7→5`, `uninstallTotal 3→1`) to match the corrected behavior where rejected jobs are excluded from unit counts.
  - **`MASTER_BLUEPRINT.md`**: Corrected stale app version field `1.5.1+59` → `1.5.7+65`.
- False positives investigated and dismissed (no changes needed): settlement batch methods, `context.go` navigation, sign-out invalidations, Firestore settlement rules, exception catch order, `includeNoCompanyOption`, provider `autoDispose`.
- Verification:
  - `get_errors` — 0 issues on all 3 modified utility files
  - `flutter analyze --no-pub` — "No issues found!" (ran in 157.7s)
  - `flutter test` — **423/423 passed**

## 2026-05-09 — Admin panel bug fixes: brackets/uninstalls stats, soft-delete filter, solo edit — APK v1.5.3+61

- Scope: 6 admin panel bugs reported after v1.5.1+59 deployment; all 6 root-caused and fixed
- Changes implemented:
  - **Bug 5 — Brackets stat card missing** (`admin_job_summary.dart`, `admin_dashboard_screen.dart`): Added `bracketCount` field to `AdminJobSummary`; `fromJobs()` accumulates `effectiveBracketCount` for each non-rejected, non-deleted job. New `_DashCard` (hardware_outlined, arcticPurple) added to dashboard, navigates to `/admin/jobs/filter/bracket`.
  - **Bug 6 — Uninstalls stat card missing** (`admin_dashboard_screen.dart`): New `_DashCard` (build_circle_outlined, arcticError) added to dashboard, shows `summary.uninstallTotal`, navigates to `/admin/jobs/filter/uninstall`.
  - **Bug 2 — Inaccurate total/approved counts** (`admin_job_summary.dart`): Added `if (job.isDeleted) continue;` at top of `fromJobs()` loop so soft-deleted jobs are excluded from all counts.
  - **Bugs 3 & 4 — Blank screen for splits/freestanding** (`job_type_filter_screen.dart`): Added `_adminLoadError` flag; catch block in `_loadMoreAdminJobs()` sets the flag; `build()` renders `ErrorCard` (with retry) when `_adminJobs.isEmpty && _adminLoadError`, distinguishing genuine errors from "no results".
  - **Bug 1 — Solo install jobs not editable by admin** (`job_repository.dart`): Root cause — `adminUpdateJob()` was setting `submittedAt`, `approvedBy`, `reviewedAt` to `null` for older/imported jobs that didn't have those fields in Firestore. Firestore's `update()` would then add them as `null`, making them appear in `affectedKeys()` and failing the `hasOnly()` check in `adminApprovedJobUpdate()` rule. Fixed via `_restoreNullableSnapshotField()` helper which removes the key from the update payload when the existing value is null, preventing the "missing → null" delta.
- Verification:
  - `get_errors` — 0 issues on all 4 modified files
  - `flutter analyze --no-pub` — "No issues found!"
  - APK v1.5.3+61 built (74.8 MB) and installed on R5GL22RGT9V; version confirmed `1.5.3`
- Git: commit pending (pre-commit hook will bump pubspec to 1.5.4+62)

## 2026-07-12 — Share recalculation, Firestore rules security, indexes, governance — APK v1.5.1+59

- Scope: Remaining audit findings from Master Audit Report v12 implemented in one session
- Changes implemented:
  - **Share auto-recalculation** (`job_repository.dart`): `adminUpdateJob()` now proportionally recalculates `techSplitShare`, `techWindowShare`, `techFreestandingShare`, `techUninstallSplitShare`, `techUninstallWindowShare`, `techUninstallFreestandingShare`, `techBracketShare`, and `charges.deliveryAmount` on every sibling doc when admin changes shared invoice totals. Uses integer `~/` division for unit counts and floating-point ratio for delivery. Computes adjustments inside the `if (aggregateSnap.exists)` block where old totals are available; applies them in the fan-out loop via `siblingShareAdjustments` map.
  - **Firestore rules security fixes**:
    - F-C002: `adminGeneralJobUpdateAllowed()` now enforces `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` — 35-field allow-list prevents admin from touching immutable fields (techId, submittedAt, isDeleted, settlement*) on non-approved jobs
    - F-C014: `validJobCreatePayload()` — added `invoiceNumber.size() <= 50`
    - F-C008: `validJobCreatePayload()` — added `clientName.size() <= 200` and `get('clientContact', '').size() <= 50`
  - **Firestore indexes** (`firestore.indexes.json`): Added `jobs [techId + isDeleted + date DESC]`, `jobs [status + isDeleted + date DESC]`, `ac_installs [techId + status + date DESC]`, `earnings [techId + status + date DESC]`
  - **Governance**: bumped pubspec to `1.5.1+59`; updated `MASTER_BLUEPRINT.md` version; added `analyze_out.txt` to `.gitignore`; added CHANGELOG entries for 1.5.0+58 and 1.5.1+59
- Verification:
  - `flutter analyze --no-pub` — "No issues found!"
  - `flutter test` — all tests passed
  - Firestore rules linted and deployed
  - Firestore indexes deployed
  - APK v1.5.1+59 built and installed on R5GL22RGT9V
- Git: commit `9ddca91` pushed to main (pre-commit hook auto-bumped pubspec to 1.5.2+60 for next build)

## 2026-05-08 — Bug fixes: shared install editability, history tab colors; feature: admin shared installs list — APK v1.4.9+54

- Scope: Two bug fixes + one new feature; split-per-abi APK built and installed on R5GL22RGT9V
- Changes implemented:
  - **Shared install editability fix** (`approvals_screen.dart`): Approved shared install tiles now navigate via `context.push('/admin/job/${job.id}', extra: job)` instead of opening a read-only `_showJobVerificationDialog`. The admin edit button on `JobDetailsScreen` (visible when approved + unpaid + admin) is now reachable. Removed unused `approvedGroupSize` local variable.
  - **History tab color fix** (`job_history_screen.dart`): Added explicit `labelColor: ArcticTheme.arcticBlue` and `unselectedLabelColor: ArcticTheme.arcticTextPrimary` to the `TabBar` so Jobs and In/Out labels are clearly visible against the dark AppBar background.
  - **Admin shared installs stats card** (`admin_dashboard_screen.dart`): Added `approvedShared = ref.watch(approvedSharedInstallsProvider)` and a `_DashCard` showing approved shared install count after the AC-type row. Card is non-tappable when count is 0; navigates to `/admin/jobs/shared` when count > 0.
  - **AdminSharedInstallsScreen** (new file `admin_shared_installs_screen.dart`): `ConsumerWidget` watching `approvedSharedInstallsProvider`; shows list of approved shared install jobs with client name, tech/invoice, date, status badge, and shared-install chip. Tap → `context.push('/admin/job/:jobId')`.
  - **Route** (`app_router.dart`): Added `/admin/jobs/shared` GoRoute before the existing `/admin/job/:jobId` route.
- Verification:
  - `flutter analyze --no-pub` — "No issues found!"
  - `flutter build apk --split-per-abi --release` — arm64-v8a installed on R5GL22RGT9V
  - APK v1.4.9+54 uninstalled old + installed new; APK copied to /sdcard/Download/
- No Firestore rules/indexes changed → no deploy needed

## 2026-07-11 — Admin edit approved jobs, silent error fixes, audit remediations — APK v1.4.8+52

- Scope: Completed pending infrastructure items from prior session; implemented admin edit of approved jobs feature; fixed all 12 silent error handlers; Firestore index + rules deploy; full sign-off
- Changes implemented:
  - **Admin edit approved jobs** (full feature):
    - `firestore.rules`: `adminApprovedJobUpdate()` helper; `jobUpdateAllowed()` updated to permit admin edits of approved/unpaid jobs
    - `JobModel`: `adminEditedBy: String?` + `adminEditedAt: DateTime?` fields; freezed + json codegen run
    - `JobRepository.adminUpdateJob(JobModel job, String adminUid)`: updates approved job with admin metadata
    - `SubmitJobScreen`: admin early-return branch calls `adminUpdateJob()` + `context.pop()` when `_isEditing && user.isAdmin`
    - `JobDetailsScreen`: admin edit button (visible when approved + unpaid + admin); admin-edited badge (when `adminEditedAt != null`)
    - ARB: 4 new l10n keys — `tryAgain`, `adminEditJob`, `adminEditedBadge`, `adminEditedAt`; `flutter gen-l10n` run
  - **U-01..U-12 silent errors fixed**: All 12 `SizedBox.shrink()` error handlers replaced with `ErrorCard(exception: ...)` across `AdminDashboardScreen`, `TechDashboardScreen`, `HistoricalImportScreen`, `TeamScreen`, `InvoiceReconciliationScreen`
  - **L-01 l10n fix**: `ErrorCard` "Try Again" hardcoded string replaced with `context.l10n.tryAgain`
  - **N-01 nav fix**: `context.go('/admin/team')` → `context.push('/admin/team')` in `AdminDashboardScreen`
  - **S-01 isAdmin guard**: `pendingCollaborationAggregatesProvider` now returns empty list for non-admin users
  - **D-01/D-02 Firestore indexes**: Composite indexes for `expenses` (techId + status + date) and `earnings` (techId + status + date) added to `firestore.indexes.json` and deployed
  - **Test fix**: `stale_shared_aggregates_test.dart` — seed dates changed from 10 days to 31 days so they exceed the 30-day default threshold
- Verification:
  - `flutter analyze --no-pub` — "No issues found!"
  - `flutter test` — 423/423 passed
  - `flutter build apk --split-per-abi --release` — arm64 30.3MB, armeabi 28.8MB, x86_64 31.8MB
  - APK v1.4.8+52 uninstalled old + installed new on R5GL22RGT9V
  - Firestore rules + indexes deployed to actechs-d415e
- Git: commit `9664949` pushed to main (pre-commit hook auto-bumped to 1.4.9+53 for next build)

## 2026-07-11 — Bug fixes: tech data loading, WhatsApp icon, duplicate email detection — APK v1.4.5+49

- Scope: Four regressions diagnosed and fixed; APK built and installed on device R5GL22RGT9V
- Changes implemented:
  - **Tech dashboard + history data loading fix**: `technicianJobs()` and `pendingApprovals()` in `job_repository.dart` had `.where('isDeleted', isNotEqualTo: true)` combined with `.orderBy('submittedAt', ...)`, requiring a missing composite Firestore index. Fix: removed `isDeleted` from Firestore query; moved filter to Dart `.map()` stage (`.where((job) => !job.isDeleted)`). No index deploy needed.
  - **WhatsApp icon fix** (`team_screen.dart`): Changed generic `Icon(Icons.chat_rounded)` → `const FaIcon(FontAwesomeIcons.whatsapp, size: 20)` with `font_awesome_flutter` import.
  - **Duplicate email foolproofing**: Added `hardDeleteUser(uid)` to `UserRepository` (guards active users), `duplicateEmailUsersProvider` (derived from `allUsersProvider`, zero extra listeners) to `admin_providers.dart`, and `_DuplicateEmailBanner` + `_handlePurgeEmailDuplicate()` to `TeamScreen` — shows warning card with Remove button when inactive duplicate email users exist.
  - **ARB localization**: Added 4 new keys (`duplicateEmailWarningTitle`, `duplicateEmailWarningBody`, `removeDuplicateUser`, `userPermanentlyDeleted`) to all 3 locale files; fixed missing ICU `}` in Arabic plural expression.
- Verification:
  - `flutter gen-l10n` — success
  - `flutter analyze --no-pub` — "No issues found!"
  - `flutter build apk --release` — Built (74.8MB, 234s)
  - APK `1.4.5+49` uninstalled old + installed new on R5GL22RGT9V
- No Firestore rules/indexes changed → no deploy needed

## 2026-07-11 — Zoom drawer, stale install cleanup, comprehensive audit, security hardening

- Scope: custom zoom drawer for both shells, stale shared install cleanup (backend + UI), comprehensive backend + security audits, audit finding remediation, dead code removal, additional tests, governance docs update
- Changes implemented:
  - Custom `ZoomDrawerWrapper` widget with `ZoomDrawerController` and `ZoomDrawerScope` — integrated into both `TechShell` and `AdminShell`
  - `DrawerMenuContent` widget for the drawer menu UI
  - Stale shared install cleanup: `fetchStaleSharedAggregates()` and `archiveStaleSharedInstall()` in `JobRepository`, `staleSharedAggregatesProvider` in `job_providers.dart`, admin dashboard cleanup card with confirmation dialog
  - RTL compliance fixes across 18+ files (40+ `AlignmentDirectional` / `EdgeInsetsDirectional` replacements)
  - Backend audit (78 PASS, 2 FAIL, 8 WARN) — all critical findings fixed
  - Security audit (42 PASS, 4 WARN, 2 FAIL) — all code-level findings fixed
  - Firestore rules: AC installs auto-approved edit path added, soft-archive exception for auto-approved entries
  - Removed 6 dead repository methods: `todaysJobs`, `todaysExpenses`, `todaysWorkExpenses`, `todaysHomeExpenses`, `todaysEarnings`, `watchTodaysInstalls`
  - `ApprovalConfigRepository._mergeConfig` wrapped in try/catch for `FirebaseException`
  - `firebase_options.dart` added to `.gitignore`
  - Matrix4 deprecated warnings suppressed with ignore comments in `ZoomDrawer`
  - BuildContext async gap fixed with `context.mounted` check in admin dashboard
  - Deleted temporary artifacts: `analyze_output.txt`, debug scripts, PDF samples, fix plan doc
  - Added 25 new tests across 3 files: stale shared aggregates (9), zoom drawer controller (3), approval config model + repository (16 — note: 3 from zoom drawer test file)
  - Total test count: 424 (up from 399)
- Verification:
  - `flutter analyze` — zero issues ("No issues found!")
  - `flutter test` — 424/424 passed
  - VS Code Problems panel — zero errors
- Pending: Firestore rules deploy, version bump, APK + web build

## 2026-04-12 — Session continuity hardening and APK v1.3.5+41

- Scope: corrected skipped workflow steps from prior session; hardened all governance docs with session continuity, zero-problems policy, and Firestore alignment rules; fixed invoice settlements BulkActionBar color drift; fixed all MD lint issues across workspace
- Workflow executed in mandatory sequence:
  - `pubspec.yaml` bumped from 1.3.4+40 to 1.3.5+41
  - `flutter analyze` passed — No issues found!
  - `flutter test` passed — 399/399
  - Firestore rules deployed to actechs-d415e
  - APK built: `flutter build apk --release --no-tree-shake-icons` (75.1MB)
  - Old APK uninstalled from device 671f700b
  - New APK installed to device 671f700b (v1.3.5+41)
- Governance hardening applied to 8 files: CLAUDE.md, release-surface-sync.instructions.md, code-quality.md, regression-prevention.md, backend-engineer.md, qa-engineer.md, code-reviewer.md, firestore-patterns/SKILL.md
- Color fix: BulkActionBar background changed from hardcoded `ArcticTheme.arcticSurface` to `Theme.of(context).colorScheme.surface`
- All .md lint issues (MD022/MD032/MD047) fixed across CHANGELOG, MASTER_BLUEPRINT, SESSION_LOG, REGRESSION_REGISTRY, docs/domain-architecture.md, docs/audits/README.md, docs/testing-strategy.md, .github/workflows/README.md

## 2026-04-12 — Go-mode implementation pass

- Scope: workflow parity, governance continuity files, technician dashboard interaction fixes, release-surface alignment, and dashboard regression tests
- Confirmed baseline before edits:
  - `flutter analyze --no-pub` passed
  - `flutter test --coverage` passed
  - `npm run lint:firestore-rules` passed
  - `npm test` in `scripts/` passed
- Implemented so far:
  - Weekly audit workflow updated to respect shell-root navigation while enforcing governance assets and web parity
  - CI now builds the web surface
  - CI hygiene now fails if the root governance continuity files are missing
  - Release workflow now builds and publishes the web artifact
  - Technician dashboard settings action now preserves back stack
  - Technician dashboard bracket and uninstall cards are now actionable
  - Global FAB theme no longer forces circular shape on extended FABs
  - Dashboard widget regression test added for settings navigation, history taps, and New Job FAB readability
- Final verification:
  - `flutter analyze --no-pub` passed
  - `flutter test --coverage` passed (`399` tests; existing PDF font fallback warnings unchanged)
  - `npm run lint:firestore-rules` passed
  - `npm test` in `scripts/` passed after stopping a stale local Firestore emulator that was holding port `8080`
  - `flutter build web --release --no-wasm-dry-run` passed
  - `flutter build apk --release --no-tree-shake-icons` passed
  - Release APK installed successfully to device `671f700b`
  - Release app launch smoke check passed via `adb shell monkey -p com.actechs.pk -c android.intent.category.LAUNCHER 1`

## 2026-04-11 — Audit remediation and release verification

- Scope: audit findings remediation, analyzer cleanup, build_runner regeneration, release APK build, install to connected Android phone
- Outcome:
  - Audit findings fixed and committed
  - `flutter analyze --no-pub` clean
  - Release APK built and installed to device

## 2026-04-04 — Comprehensive multi-agent audit baseline

- Scope: broad codebase audit across rules, providers, navigation, admin flows, shared installs, release infrastructure, and regression discipline
- Artifacts:
  - `docs/ultimate_master_audit_report_v6.txt`
  - `docs/ultimate_master_fix_plan_v1.md`
