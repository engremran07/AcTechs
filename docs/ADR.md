# AcTechs — Architecture Decision Records (ADRs)

**Format:** Title · Status · Context · Decision · Consequences

---

## ADR-001: Riverpod 3.x over BLoC

**Status:** Accepted  
**Date:** ~2024-06-01 (project inception)

**Context:** Need state management for a multi-screen app with real-time Firestore streams, role-based UI, and shared state across admin + tech shells.

**Decision:** Use `flutter_riverpod: ^3.3.1` with `StreamProvider.autoDispose` for Firestore streams and derived `Provider.family` for filtered views.

**Consequences:**
- ✅ Zero boilerplate compared to BLoC events/states
- ✅ autoDispose prevents stale Firestore listeners when navigating away
- ✅ StreamProvider deduplicates identical subscriptions automatically
- ✅ `ref.invalidate()` in signOut() cleanly resets all state

---

## ADR-002: Soft Delete over Hard Delete

**Status:** Accepted  
**Date:** ~2024-08-01

**Context:** Technician-owned records (expenses, earnings, jobs, ac_installs) are referenced by settlement batches and reports. Hard deletes create orphaned references.

**Decision:** All technician-owned documents use `isDeleted: bool` + `deletedAt: Timestamp`. Archive methods set these fields instead of calling `.delete()`.

**Consequences:**
- ✅ Settlement history remains accurate even after tech "deletes" a record
- ✅ Period lock enforcement still works (no need to handle delete edge case)
- ⚠️ Collections grow indefinitely — acceptable for current scale
- ⚠️ No Firestore index on `isDeleted` (Dart-layer filter to save index budget)

---

## ADR-003: Firebase Spark Tier (No Cloud Functions)

**Status:** Accepted  
**Date:** Project inception

**Context:** Project is internal deployment for a single HVAC company. Need to minimise operational cost.

**Decision:** Use Firestore for all business logic that can be expressed as Firestore rules. No Cloud Functions. No Cloud Messaging. Spark free tier.

**Consequences:**
- ✅ Zero monthly cost
- ✅ Firestore rules provide server-side enforcement without Cloud Functions
- ⚠️ 50,000 reads/day limit — requires careful query design (allJobs .limit(150), etc.)
- ⚠️ No push notifications (FCM requires Blaze tier)
- ⚠️ Settlement caps at 200/500 records — documented as Known Limitation

---

## ADR-004: GoRouter 17.x over auto_route

**Status:** Accepted

**Context:** Need type-safe navigation with auth guards, shell routes for tab navigation, and role-based redirects.

**Decision:** Use `go_router: ^17.2.0` with shell routes, redirect guards, and `context.push()` vs `context.go()` discipline.

**Consequences:**
- ✅ Native support for shell routes (bottom nav + drawer)
- ✅ Redirect guards enforce auth + role + minimum-build gates
- ✅ `context.go()` for shell tabs; `context.push()` for detail routes (REG-006 prevention)
- ⚠️ GoRouter's redirect debounce (80ms) can cause double-evaluation on slow connections

---

## ADR-005: Freezed Models over Plain Classes

**Status:** Accepted

**Context:** Need immutable models with `copyWith`, equality, serialization, and pattern matching for 60+ fields in `JobModel`.

**Decision:** Use `freezed: ^3.0.6` + `json_serializable` for all domain models.

**Consequences:**
- ✅ Zero runtime equality bugs (value equality by default)
- ✅ `@Default` annotations handle missing Firestore fields gracefully
- ✅ copyWith prevents accidental mutation
- ⚠️ Code generation required (`build_runner`) — must run when models change
- ⚠️ Generated files (`.freezed.dart`, `.g.dart`) must be committed

---

## ADR-006: Three-Language ARB Localization (EN, UR, AR)

**Status:** Accepted

**Context:** App is deployed in Saudi Arabia. Admin users may be Arabic-speaking; technicians may be Urdu-speaking. Both Arabic and Urdu are RTL.

**Decision:** Use Flutter's `flutter_localizations` + ARB files for EN, UR, AR. CI enforces key parity across all three. NotoNastaliqUrdu + NotoNaskhArabic bundled for offline PDF generation.

**Consequences:**
- ✅ Native RTL layout for Arabic and Urdu
- ✅ Font bundling enables offline PDF generation with correct script rendering
- ⚠️ All three ARB files must be updated synchronously on every string addition
- ⚠️ CI ARB parity gate prevents mismatches

---

## ADR-007: MethodChannel for Per-Package WhatsApp Detection

**Status:** Accepted  
**Date:** 2026-06-09

**Context:** `canLaunchUrl()` with `intent://` URIs checks the scheme (`whatsapp://`) not the specific `package=` field. Both `com.whatsapp` and `com.whatsapp.w4b` returned true regardless of which was installed. This caused the chooser dialog to appear even with a single WA variant, then silently fail when the non-installed app was tapped.

**Decision:** Implement `MethodChannel('com.actechs.pk/packages')` in `MainActivity.kt` calling `PackageManager.getPackageInfo()`. Both packages declared in `<queries>` in AndroidManifest.xml.

**Consequences:**
- ✅ Reliable per-package detection on Android 11+ (confirmed via REG-013)
- ✅ Chooser only appears when BOTH apps are installed
- ✅ Fallback chain: specific intent → wa.me universal → browser
- ⚠️ Test environments receive `false` for both packages (acceptable behavior)

---

## ADR-008: Period Lock Architecture

**Status:** Accepted

**Context:** Company needs to "close" historical months to prevent retroactive edits that would affect already-paid settlements.

**Decision:** `approvalConfig.lockedBeforeDate` Firestore field. `dateIsUnlocked()` Firestore rule function guards job/expense/earning creates and edits. Settlement _responses_ intentionally exempt (REG-011).

**Consequences:**
- ✅ Historical period integrity preserved
- ✅ Settlement workflow unblocked after lock (REG-011)
- ⚠️ Historical import tool can bypass lock with admin confirmation — partial-success UX risk (FEAT-005)

---

## ADR-009: Shared Install Aggregate Architecture

**Status:** Accepted

**Context:** Multiple techs contribute to one job installation. Need to split the credit fairly without complex server-side aggregation.

**Decision:** Deterministic group key `{companyId}-{invoiceNumber}`. `shared_install_aggregates` collection holds running totals. Each tech contribution triggers an increment. Consumer-side delivery calculation from aggregate snapshot.

**Consequences:**
- ✅ No Cloud Functions required
- ✅ Reproducible group key prevents duplicates
- ⚠️ Counter rollback on archive not implemented (Spark tier constraint)
- ⚠️ Stale aggregates accumulate — admin cleanup tool provided

---

## ADR-010: FLAG_SECURE for Sensitive Screens

**Status:** Accepted  
**Date:** 2026-06-09

**Context:** Settlement screens display invoice amounts and technician personal data. Android screen recording / sharing would expose this data.

**Decision:** `SecureScreen` utility using `MethodChannel` → `WindowManager.LayoutParams.FLAG_SECURE`. Enabled in `initState()`, disabled in `dispose()`.

**Consequences:**
- ✅ Screenshots and screen recordings blocked on settlement screens
- ✅ No UI impact — invisible to user unless they attempt screenshot
- ⚠️ Only implemented for InvoiceSettlementsScreen currently; JobDetailsScreen deferred
