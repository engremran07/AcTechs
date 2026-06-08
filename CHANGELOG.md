# CHANGELOG

## 2.2.7+96

- Fix: admin bulk transfer now shows confirmation dialog before committing (BLK-004)
- Fix: filter changes in All Jobs screen clear multi-selection to prevent ghost actions (BLK-007)
- Fix: allJobsLimitNote banner only shown when 150-record cap is hit (UX-001)
- Fix: tech transfer button hidden for jobs in a locked period (UX-002)
- Fix: WhatsNew dialog skips display for phantom/governance version bumps — only shows when `_changelog` has an entry for the current version (WND-002)
- Fix: WhatsNew dialog saves seen-key AFTER showing, not before — backgrounding no longer marks dialog as shown without displaying (WND-003)
- Fix: WhatsNew dialog header uses `cs.onPrimary` instead of hardcoded `Colors.white` (WND-005)
- Fix: WhatsNew dialog shows up to 5 recent versions instead of 3 (WND-004)
- Fix: phone input strips ALL leading zeros before prepending country code (PHN-002)
- Fix: phone input adds `AutofillHints.telephoneNumber` for password manager integration (PHN-005)
- Fix: `approveJobTransferRequest()` and `rejectJobTransferRequest()` wrapped in `runTransaction()` to eliminate TOCTOU race condition (PER-003)
- Fix: `ApprovalConfig.toMap()` no longer contains `FieldValue.serverTimestamp()` — model is now Firestore-agnostic (PER-004)
- Fix: `fetchSettlementCandidates()` logs a warning when 200-record cap is hit (PER-001)
- Pre-commit hook: governance-only commits (*.md files only) no longer trigger a version bump (GOV-001 root cause / WND-002)
- CI: removed dead "Resolve firebase_options.dart" step from build-debug job (BLD-001)
- CI: added Gate — WhatsNewDialog `_changelog` has entry for current version (WND-008/BLD-002)
- CI: extended Colors.white gate to cover all of `lib/` not just presentation screens (BLD-003/WND-005)
- CI: added Gate — FIREBASE_APP_CHECK_WEB_KEY secret verification warning (SEC-001)
- Country list comment updated to reflect actual count (~100 countries) (PHN-003)

## 2.2.6+95

- Governance: MASTER_BLUEPRINT and CHANGELOG synced after pre-commit hook version bump

## 2.2.5+94

- Fix: What's New dialog `_changelog` map updated with entries for v2.2.4 and v2.2.5 — the dialog was showing stale content because new version keys were absent from the in-code map
- Fix: MASTER_BLUEPRINT.md version synced to match pubspec.yaml after pre-commit hook bump
- Rule: sign-off sequence now explicitly requires updating `whats_new_dialog.dart` `_changelog` before every build

## 2.2.4+93

- Feature: Country code picker in phone input — `PhoneInputField` widget with full 95+ country list, KSA pre-selected, E.164 normalization on output; replaces raw TextFormField in team screen add/edit dialogs
- Feature: Centralised search — `JobSearchFilter.apply()` now searches invoice number, Firestore doc ID, client name, client contact (digits-only phone match), and tech name; replaces three separate copy-pasted filter lambdas in approvals, all-jobs, and history screens
- Feature: `UserSearchFilter.apply()` for team screen — also searches phone digits
- Feature: Tech-initiated transfer UI — transfer request button + cancel button added to `JobDetailsScreen`; shows current pending target; uses `requestJobTransfer()` or direct `transferJobAsTech()` depending on approval config; `activeTechniciansForTeamProvider` imported from admin providers
- Feature: CI/CD — App Bundle (AAB) build step added to `release.yml`; both APK and AAB now produced and uploaded as artifacts on every release
- Feature: CI/CD — MASTER_BLUEPRINT version-drift gate added to `ci.yml` hygiene job; fails if `MASTER_BLUEPRINT.md` version does not match `pubspec.yaml`
- Feature: CI/CD — `FIREBASE_APP_CHECK_WEB_KEY` passed as `--dart-define` to all web build steps in `ci.yml` and `release.yml` (SEC-002 fix)
- Fix: `signOut()` now invalidates `allJobsProvider` and `pendingTransferRequestsProvider` — prevents stale job data after user switch (AUTH-003)
- Fix: `transferJobAsTech()` — field renamed from `transferredByAdminId` to `transferredByTechId` to correctly record tech-to-tech transfer audit trail (CQA-001)
- Fix: `WhatsAppLauncher.normalizeNumber()` now expands local KSA numbers (0554XXXXXX → 966554XXXXXX) and any other local format with leading 0; `defaultCountry` parameter added (WA-001)
- Fix: WhatsApp chooser bottom sheet labels localized — `whatsappAppLabel` / `whatsappBusinessLabel` ARB keys used instead of hardcoded English (WA-005)
- Fix: CI coverage threshold raised from 60% to 80% (CI-001)
- L10n: 9 new strings in en/ur/ar: `selectCountryCode`, `phoneLocalHint`, `invalidPhone`, `whatsappAppLabel`, `whatsappBusinessLabel`, `cancelTransferConfirm`, `transferRequestSent`, `jobTransferred`, `searchByTechClientInvoicePhone`
- Models: `CountryDialCode` — 95+ country list with flag emoji, dial prefix, ISO code; `PhoneDisplayExtension.toDisplayPhone()` for formatted display
- Utilities: `JobSearchFilter` + `UserSearchFilter` in `lib/core/utils/job_search_filter.dart`

## 2.2.2+91

- Feature: What's New dialog — shown once per app version for both admins and technicians; lists new features and bug fixes in English, Urdu, and Arabic; dismissed with "Got It" or the ✕ button; uses `SharedPreferences` to ensure it never repeats for the same version build
- Feature: WhatsApp chooser bottom sheet — when opening a contact's WhatsApp chat, a bottom sheet lets the user pick WhatsApp Business or regular WhatsApp if both are installed; falls back to direct open if only one is installed; falls back to `wa.me` link on web
- Feature: Phone number field added to the Add Technician dialog; saved to Firestore user document
- Feature: "Transferred" badge on job cards (tech history + admin all-jobs) and transfer details section on job detail screen — shows original tech name and transfer date
- Feature: Admin bulk job actions — long-press to enter multi-select mode, then bulk-transfer or bulk-cancel transfer requests for selected jobs; BulkActionBar shows selected count with clear and per-action buttons
- Performance: `allJobs()` stream limited to 150 most-recent documents; limit note banner shown below filters
- Repo: `bulkTransferJobs`, `bulkCancelTransferRequests`, `bulkRequestJobTransfers`, `bulkTransferJobsAsTech` added to `JobRepository`
- L10n: 9 new strings added across en/ur/ar ARBs (`bulkTransferSuccess`, `bulkTransferFailed`, `bulkCancelTransferSuccess`, `bulkCancelTransferFailed`, `bulkRequestTransferSuccess`, `allJobsLimitNote`, `longPressToSelect`, `whatsNewTitle`, `whatsNewGotIt`)
- Fix: Dangling docstring fragment in `job_repository.dart` `bulkTransferJobs` closing brace — restored `fetchStaleSharedAggregates` doc comment

## 2.2.1+90

- Fix: "Request Transfer" button shown on tech job cards even when `techTransferRequiresApproval` is false — now creates a direct transfer (no approval step) when approval is not required
- Fix: Technician job transfer dialog showed "No active technicians" — changed from `allTechniciansProvider` to `activeTechniciansForTeamProvider`
- Feature: `JobRepository.transferJobAsTech()` — tech-side direct transfer (no pending state) when approval is disabled
- Firestore: `techDirectTransferAllowed()` helper function added to rules; `jobUpdateAllowed()` tech branch updated to support direct transfer payload

## 2.1.0+87

- Security: Removed `firebase_options.dart` from git tracking (SEC-001) — file was committed despite `.gitignore` rule; rotate exposed API keys in Firebase Console
- Feature: Job transfer — admin can reassign any unpaid job to a different technician via new Transfer button in the job verification dialog; transfer tracked with audit fields (`transferredFromTechId`, `transferredFromTechName`, `transferredAt`, `transferredByAdminId`)
- Feature: Minimum build enforcement (`BIZ-001`) — router redirects techs with outdated APK builds to a new `/update-required` screen when `enforceMinimumBuild` is enabled in approval config
- Android: WhatsApp + WhatsApp Business package visibility queries added to `AndroidManifest.xml` (AND-001) — fixes silent WhatsApp share failure on Android 11+
- UX: Flush database screen — prominent export-before-flush recommendation card added to Step 1 with link to Analytics (OPS-001)
- UX: Historical import — keyword and selection validated before file picker opens (UX-002)
- UX: Historical import — locked-period pre-flight warning banner shown when parsed jobs fall before `approvalConfig.lockedBeforeDate` (UX-001)
- Code: Consolidated duplicate `SharedPreferences` / `ActionCodeSettings` constants to `AppConstants` (CQA-001, CQA-002, CQA-003); callers in `main.dart`, `auth_repository.dart`, `login_screen.dart`, `user_repository.dart` updated
- Fix: `.gitignore` duplicate `.tmp/` block removed (CQA-004)
- Fix: `archiveNonAdminUsersInChunks()` in `user_repository.dart` now queries `isActive == true && role != admin` to avoid re-archiving already-inactive users (FBR-004)
- Firestore: Added `status + isDeleted + submittedAt` composite index for `jobs` collection (FBR-001)
- Firestore: `adminJobTransferAllowed()` security function added; transfer payload limited to 6 audit fields; only permitted for `unpaid` jobs (rules layer)

## 2.0.10+86

- Pre-commit version bump from hook; no additional code changes in this build number

## 2.0.9+85

- Android: Added `android:supportsRtl="true"` to `AndroidManifest.xml` — enables proper right-to-left layout mirroring for Arabic and Urdu locales on Android
- Android: Added `android:networkSecurityConfig="@xml/network_security_config"` — explicit network security policy trusting only system CAs with cleartext traffic blocked
- Android: Added `android:dataExtractionRules="@xml/data_extraction_rules"` — Android 12+ (API 31+) data extraction rules that exclude all app data from cloud backup and device-to-device transfers
- UX: Change-password dialog in Settings — added `AutofillGroup` wrapper, `AutofillHints.password` on current-password field, `AutofillHints.newPassword` on new/confirm-password fields, and `TextInput.finishAutofillContext(shouldSave: true)` on submit to signal Android password managers to update stored credentials

## 2.0.8+84

- Fixed: `settings_screen.dart` — approval-toggle error handlers used `l.couldNotExport` (wrong string); changed to `l.genericError` for `_toggleJobApproval`, `_toggleInOutApproval`, `_toggleSharedJobApproval` (D08/ERR-002)
- Fixed: `admin_shared_installs_screen.dart` — `.when(error:)` handler exposed raw `e.toString()` to UI; replaced with `l.genericError` (D08/ERR-003)
- Fixed: `reports_hub_screen.dart` — 12 raw catch blocks exposed raw exception strings to UI; added `_reportError()` helper using `AppException.message(locale)` when available, `l.genericError` otherwise (D08/ERR-004)
- Fixed: `job_repository.dart` — `.clamp(0, 1 << 31)` web integer overflow (1 << 31 = -2147483648 in JS bitwise); changed 15 occurrences to `.clamp(0, 0x7FFFFFFF)` (D05/WEB-001)
- Fixed: `.github/workflows/release.yml` — added keystore integrity verification step (file must exist and be >100 bytes) to prevent silent debug-signing if keystore decode produces an empty or corrupted file (D02/CI-001)
- Added: `timeout-minutes` to `analyse` (15 min), `test` (20 min), and `build-debug` (30 min) CI jobs to prevent indefinitely-hanging CI runs from consuming runner minutes (D16/CI-002)
- Security: `firestore.rules` settlement temporal guards — `settlementRequestedAt`, `settlementPaidAt`, `settlementCorrectedAt` all enforce `<= request.time` in all three transition cases to prevent backdated settlements (D01/SEC-001)

## 2.0.6+82

- Fixed: "rejected" stat card on tech dashboard used `context.go('/tech/history')` — destroyed back stack; changed to `context.push('/tech/history')` (NAV-005)
- Fixed: popup menu "View History" action on tech dashboard used `context.go('/tech/history')` — destroyed back stack; changed to `context.push('/tech/history')` (NAV-006)
- Fixed: "pending jobs" mini-list on admin dashboard used `context.go('/admin/approvals')` — destroyed back stack; changed to `context.push('/admin/approvals')` (NAV-007)
- Fixed: approved shared installs error handler on admin dashboard was `const SizedBox.shrink()` — replaced with `_DashCard` showing dash value so errors don't silently swallow the card (UI-002)
- Fixed: Excel export button in `ReportsHubScreen` used hardcoded `Colors.green.shade700` — replaced with `ArcticTheme.arcticSuccess` (UI-001)
- Fixed: `ApprovalConfigRepository._mergeConfig()` catch block threw raw untyped `Exception(...)` — changed to `on FirebaseException { rethrow; }` to preserve the typed exception hierarchy (ERR-001)

## 2.0.1+77

- Fixed: 10 missing `ref.invalidate()` calls in `auth_providers.dart` `signOut()` — stale state no longer persists after sign-out for `approvedSharedInstallsProvider`, `adminJobSummaryProvider`, `adminScopedJobSummaryProvider`, `filteredAdminJobsProvider`, `techJobsByAcTypeProvider`, `technicianJobSummaryProvider`, `monthlyJobsProvider`, `monthlyTechnicianJobSummaryProvider`, `userSharedInstallStatusProvider`, `monthlyTechnicianInOutSummaryProvider`
- Security: `firestore.rules` — fixed `reviewedAt is timestamp` → `reviewedAt == request.time` in auto-approve create sections for expenses, earnings, and ac_installs to prevent client from backdating the reviewed timestamp
- Fixed: `job_repository.dart` `approvedSharedInstalls()` — added `isDeleted` filter so soft-deleted shared installs no longer appear in the approved list
- Fixed: `job_repository.dart` `resubmitForApproval()` — added `_periodLockGuard.ensureUnlockedDocument()` so techs cannot resubmit a job in a locked period
- Fixed: `job_repository.dart` `fetchStaleSharedAggregates()` — replaced magic literal `Duration(days: 30)` with `Duration(days: AppConstants.staleAggregateThresholdDays)`
- Fixed: `expense_repository.dart` `restoreExpense()` / `earning_repository.dart` `restoreEarning()` — added `on PeriodException { rethrow; }` so period lock errors surface correctly
- Fixed: `tech_dashboard_screen.dart` — 3 instances of `context.go('/tech/submit')` (empty-state button, FAB, shared install card tap) changed to `context.push('/tech/submit')` to preserve back stack
- Fixed: `company_selector_field.dart` `includeNoCompanyOption` default changed from `true` → `false` — prevents submitting jobs without a company when companies exist
- Added: `AppConstants.noCompanyKey = 'no-company'` and `AppConstants.staleAggregateThresholdDays = 30`
- Fixed: `invoice_utils.dart` — replaced `'no-company'` literal with `AppConstants.noCompanyKey`
- Governance: `analysis_options.yaml` — added 4 lint rules: `unnecessary_const`, `avoid_empty_else`, `use_build_context_synchronously`, `close_sinks`
- Fixed: `auth_repository.dart` `userStream()` — added `await controller.close()` in `onCancel` to satisfy `close_sinks` lint and properly release resources
- CI: added `timeout-minutes: 15` to `firestore-rules` CI job to prevent indefinite hang
- Version bumped from `1.5.7+65` → `2.0.0+76` then `2.0.1+77`

## 1.5.3+61

- Fixed: admin dashboard missing Brackets stat card — added `bracketCount` to `AdminJobSummary.fromJobs()` with new dashboard `_DashCard` (Bug 5)
- Fixed: admin dashboard missing Uninstalls stat card — new `_DashCard` showing `uninstallTotal` (Bug 6)
- Fixed: total/approved job counts included soft-deleted jobs — added `isDeleted` guard in `AdminJobSummary.fromJobs()` (Bug 2)
- Fixed: AC type filter screens showing blank screen on error instead of error card — added `_adminLoadError` flag + `ErrorCard` with retry in `job_type_filter_screen.dart` (Bugs 3 & 4)
- Fixed: solo install jobs not editable by admin — `adminUpdateJob()` now uses `_restoreNullableSnapshotField()` to omit `submittedAt`/`approvedBy`/`reviewedAt` from the update payload when they are absent in the existing doc, preventing Firestore PERMISSION_DENIED from the `hasOnly()` rule check (Bug 1)

## 1.5.1+59

- Fixed: proportional per-sibling share recalculation in `adminUpdateJob()` — when admin changes shared invoice totals (`sharedInvoiceSplitUnits`, etc.), each sibling job doc's `techSplitShare` / `techWindowShare` / `techFreestandingShare` / `techUninstallSplitShare` / `techUninstallWindowShare` / `techUninstallFreestandingShare` / `techBracketShare` / `charges.deliveryAmount` is recalculated proportionally inside the transaction
- Security: `adminGeneralJobUpdateAllowed()` Firestore rule now restricts which fields admin can touch on non-approved jobs via `affectedKeys().hasOnly([...])` (F-C002)
- Security: `validJobCreatePayload()` Firestore rule adds length limits — `invoiceNumber.size() <= 50` (F-C014), `clientName.size() <= 200`, `clientContact.size() <= 50` (F-C008)
- Indexes: added composite Firestore indexes for `jobs [techId + isDeleted + date]`, `jobs [status + isDeleted + date]`, `ac_installs [techId + status + date]`, `earnings [techId + status + date DESC]` (F-D001..F-D004)
- Docs: added `analyze_out.txt` to `.gitignore`

## 1.5.0+58

- Fixed: `techName` preserved on sibling docs when admin edits a shared install job — `adminUpdateJob()` reads `existing.techName` from Firestore and restores it in the update payload to prevent name corruption
- Added: fan-out of shared fields (`clientName`, `invoiceNumber`, `sharedInvoice*`, `sharedDeliveryTeamCount`, `adminEditedBy/At`) to all sibling team-member job docs when admin edits a shared install
- Added: "Admin Edited" badge in `_HistoryJobCard` when `adminEditedAt != null`

## 1.4.9+54

- Fixed: approved shared install tiles in Approvals screen now navigate to `JobDetailsScreen` (admin edit button accessible for approved+unpaid jobs)
- Fixed: history screen tab bar — Jobs/In-Out labels now have explicit color overrides for clear visibility on dark AppBar
- Added: "Approved Shared Installs" tappable stats card on admin dashboard (navigates to shared installs list screen when count > 0)
- Added: `AdminSharedInstallsScreen` — list of all approved shared install jobs; each tile taps into job details
- Added: `/admin/jobs/shared` route in GoRouter

## 1.4.8+52

- Added admin edit of approved jobs: `adminUpdateJob()` in `JobRepository`, admin edit button + admin-edited badge in `JobDetailsScreen`, admin code-path in `SubmitJobScreen`
- Added `adminEditedBy`/`adminEditedAt` fields to `JobModel`; Firestore rules `adminApprovedJobUpdate()` helper
- Fixed 12 silent error handlers (U-01..U-12): replaced `SizedBox.shrink()` with `ErrorCard` across dashboard, analytics, and team screens
- Fixed `ErrorCard` hardcoded "Try Again" string → `context.l10n.tryAgain`
- Fixed `context.go('/admin/team')` → `context.push('/admin/team')` in admin dashboard
- Added `isAdmin` guard to `pendingCollaborationAggregatesProvider`
- Added composite Firestore indexes for expenses and earnings (techId + status + date); deployed
- Added 4 new l10n keys: `tryAgain`, `adminEditJob`, `adminEditedBadge`, `adminEditedAt`

## 1.4.6+50

- Fixed reports system: replaced `ref.read(autoDispose StreamProvider).value` (returns null when unsubscribed) with one-shot `Future` Firestore fetches across all 12 report handlers
- Fixed date-range reports excluding jobs on the end date: normalize `range.end` to `23:59:59` before passing to Firestore `isLessThanOrEqualTo`
- Added `fetchMonthlyEarnings` to `EarningRepository` (one-shot get, respects `isDeleted` filter)
- Added `fetchMonthlyExpenses` to `ExpenseRepository` (one-shot get, respects `isDeleted` filter)
- Added `fetchTechJobsForPeriod` and `fetchAllTechJobs` to `JobRepository` (one-shot gets, filter `isDeleted` in Dart)
- Fixed PDF double-shaping: removed pre-`_shapeRtlForPdf` calls from data arrays that were then re-shaped inside `_shapeTableForPdf`; affects `generateJobsReport`, `generateExpensesReport` (×2), `generateEarningsReport`
- Fixed PDF empty cells showing literal `-` in In/Out report day rows and monthly totals; now renders blank
- Fixed PDF `e.note` null/empty crash: wrapped all 6 note references with `_safeTableCellText()`
- Added center alignment to all data, header, and total rows in Excel exports (`buildJobsWorkbook`, `buildEarningsWorkbook`, `buildExpensesWorkbook`, `buildInOutWorkbook`, `buildSettlementWorkbook`) via new `_centerRow` helper

## 1.4.5+49

- Fixed tech dashboard and history data loading: removed `isDeleted` filter from Firestore query and moved to Dart layer to avoid composite index requirement
- Fixed WhatsApp icon in team screen (generic icon → FontAwesome `whatsapp`)
- Added duplicate email detection: admin banner with hard-delete tool removes inactive duplicate-email users
- Added `hardDeleteUser()` to `UserRepository` (guards against deleting active users)
- Added `duplicateEmailUsersProvider` derived from `allUsersProvider` (zero extra Firestore listeners)
- Added 4 new localization keys (`duplicateEmailWarningTitle`, `duplicateEmailWarningBody`, `removeDuplicateUser`, `userPermanentlyDeleted`) across all 3 locale files

## 1.4.0+44

- Added custom zoom drawer navigation for both technician and admin shells
- Added stale shared install cleanup feature with admin dashboard card and batch archive
- Fixed AC installs Firestore rules: auto-approved edit path and soft-archive exception for auto-approved entries
- Removed 6 dead repository methods (todaysJobs, todaysExpenses, todaysWorkExpenses, todaysHomeExpenses, todaysEarnings, watchTodaysInstalls)
- Added FirebaseException error handling to ApprovalConfigRepository
- Added firebase_options.dart to .gitignore for security
- Fixed RTL compliance across 18+ files with AlignmentDirectional/EdgeInsetsDirectional
- Fixed Matrix4 deprecated member warnings in zoom drawer
- Fixed BuildContext async gap in admin dashboard stale install cleanup
- Deleted temporary artifacts (debug scripts, PDF samples, analysis output, fix plan)
- Added 25 new tests: stale aggregates, zoom drawer controller, approval config model + repository
- Total test count: 424 (up from 399)

## 1.3.5+41

- Fixed settlement PERMISSION_DENIED for locked-period jobs (REG-011)
- Added edit re-approval sub-flow: approved jobs can request correction (REG-012)
- Added admin hard delete with dual-confirm UI and emulator regression test
- Added unified history status filter with Shared as 5th chip
- Added bracket and uninstall filtered job list screens from dashboard stat cards
- Added invoice reconciliation screen: compare Excel report against DB jobs, mark matched as paid
- Hardened Firestore rules: settlement path and edit re-approval transition
- Hardened all governance docs, agent/skill files with zero-problems policy and Firestore alignment blocking rules
- Added web build parity to CI and release workflows so web and APK are validated from the same source tree
- Added governance continuity file enforcement to CI hygiene and weekly audit gates
- Updated weekly audit gates to distinguish shell-root navigation from pushed detail routes
- Added governance continuity files: blueprint, regression registry, session log, and changelog
- Fixed technician dashboard settings navigation to preserve back stack
- Made technician dashboard bracket and uninstall summary cards actionable
- Removed the global circular FAB shape override so extended FAB labels stay readable on-device
- Added a dashboard widget regression test covering settings navigation, summary-card taps, and the New Job FAB
- Replaced the last hardcoded approval-config document ID with the shared `AppConstants` constant
- Fixed BulkActionBar background color drift across themes (was hardcoded surface, now theme-aware)

## 1.3.4+40

- Fixed Daily In/Out FAB overlap with list content
- Added undo feedback helper for archive actions
- Added job soft-delete model fields and archive/restore support
- Tightened job archive Firestore rules
- Improved submit screen company loading error state
- Added CI coverage-file existence verification

## 1.3.3+39

- Previous stable baseline before the April 2026 audit remediation cycle
