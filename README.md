# AC Techs

AC Techs is a production-focused Flutter operations app for AC installation teams in Saudi Arabia. It supports technicians in the field and admins in the office, with Firebase-backed approval workflows, shared invoice handling, tri-lingual UX, offline-friendly Firestore behavior, reporting, imports, exports, and release automation.

This project is intentionally kept Spark-only. The supported backend surface is Firebase Auth, Cloud Firestore, Hosting, and client-side App Check. Do not add Cloud Functions or any Firebase feature that requires Blaze.

This README is the current master overview of the codebase: what the product does, how the repo is structured, how the backend behaves, how to build it, and what engineering constraints matter when changing it.

## Product Overview

AC Techs is built around two roles:

- Technicians submit daily operational data: installation jobs, AC-install unit records, earnings, and expenses.
- Admins review submissions, manage users and companies, enforce approval policy, import historical records, export reports, and maintain deployment settings.

The app targets Android first, also supports Flutter web, and uses Firebase Auth, Cloud Firestore, and App Check.

## Core Workflows

### Technician workflow

Technicians can:

- submit invoice-based AC jobs
- attach multiple AC unit types to one invoice
- record bracket and delivery charges
- submit shared installs with per-tech contribution shares
- track daily IN/OUT activity through earnings and expenses
- view job history and monthly summaries
- export their history as reports
- switch app language and theme preferences

### Admin workflow

Admins can:

- approve or reject jobs, expenses, earnings, and AC installations
- bulk-approve pending jobs
- inspect shared-install approval context
- view analytics and technician productivity summaries
- manage technicians, activation state, and password resets
- manage companies, invoice prefixes, and logos
- control approval requirements through Firestore-backed settings
- enforce minimum supported app build numbers
- import historical Excel workbooks with technician mapping
- export Excel and PDF reports
- run destructive database flush operations with explicit confirmation

## Main Feature Areas

### Jobs

The jobs domain is centered on invoice-based AC installation records.

Key capabilities:

- invoice normalization through `InvoiceUtils`
- multi-unit job capture across split, window, freestanding, cassette, and uninstall categories
- approval statuses: `pending`, `approved`, `rejected`
- approver and review timestamps
- approval history subcollections for auditability
- period and technician filtering for reports and analytics

Primary files:

- `lib/core/models/job_model.dart`
- `lib/features/jobs/data/job_repository.dart`
- `lib/features/jobs/providers/job_providers.dart`

### Shared installs

Shared installs are the most sensitive workflow in the repo.

Current design:

- the mobile client writes shared jobs through Firestore transactions only
- the repository validates invoice totals, per-type capacity, bracket counts, and delivery-share rules before writing
- aggregate capacity is tracked in `shared_install_aggregates`
- mismatched totals across technicians are rejected
- rejected shared jobs release their reserved capacity back to the group
- re-approving a previously rejected shared job revalidates and re-reserves capacity

Relevant files:

- `lib/features/jobs/data/job_repository.dart`
- `firestore.rules`
- `firestore.indexes.json`

### AC installations

AC installations are tracked separately from invoice jobs for approval-safe unit accounting.

Current behavior:

- technicians submit total invoice units plus their personal share per type
- admins review and approve or reject records
- approval history is stored under `ac_installs/{id}/history`
- technicians cannot delete AC-install records directly

Relevant files:

- `lib/core/models/ac_install_model.dart`
- `lib/features/expenses/data/ac_install_repository.dart`
- `lib/features/expenses/presentation/ac_installations_screen.dart`
- `lib/features/admin/presentation/approvals_screen.dart`

### Earnings and expenses

The IN/OUT system tracks both business and home-related flows.

Capabilities:

- separate earning and expense records
- approval support controlled by `inOutApprovalRequired`
- daily, monthly, and technician-scoped filtering
- export-ready reporting for both admin and technician use

Relevant files:

- `lib/core/models/earning_model.dart`
- `lib/core/models/expense_model.dart`
- `lib/features/expenses/data/earning_repository.dart`
- `lib/features/expenses/data/expense_repository.dart`
- `lib/features/expenses/presentation/daily_in_out_screen.dart`

### Admin analytics and reporting

Admins have access to summary screens, charts, and exports.

Included features:

- job status summaries
- technician workload summaries
- shared-install invoice-aware totals
- uninstall totals
- PDF exports with branding
- Excel exports for jobs, earnings, expenses, and company invoice activity

Relevant files:

- `lib/core/models/admin_job_summary.dart`
- `lib/features/admin/presentation/analytics_screen.dart`
- `lib/core/services/pdf_generator.dart`
- `lib/core/services/excel_export.dart`

### Historical import

Historical workbook import is an admin-only maintenance flow.

Capabilities:

- multi-sheet Excel import
- technician mapping against active users
- sheet-aware period naming and metadata notes
- row-level validation and skipped-row reporting
- cleanup-safe file loading for mobile and web

Relevant files:

- `lib/features/admin/presentation/historical_import_screen.dart`
- `lib/features/admin/data/historical_jobs_import_service.dart`
- `lib/core/utils/picked_file_bytes.dart`

### Team and company management

Admins manage both user lifecycle and company metadata.

Users:

- create technician/admin accounts
- soft deactivate via `isActive`
- bulk activate/deactivate
- send reset emails

Companies:

- create and edit companies
- store invoice prefixes
- store logos for branded exports

Relevant files:

- `lib/features/admin/data/user_repository.dart`
- `lib/features/admin/presentation/team_screen.dart`
- `lib/features/admin/presentation/companies_screen.dart`

## Current Architecture

The app follows a feature-first layout.

```text
lib/
  core/
    constants/
    models/
    providers/
    services/
    theme/
    utils/
    widgets/
  features/
    admin/
    auth/
    expenses/
    jobs/
    settings/
    technician/
  l10n/
  routing/
docs/
scripts/
```

Repo rules that matter:

- Firestore access belongs in repositories.
- Widgets should not expose raw Firebase messages.
- Approval logic must stay aligned across UI, repository code, and rules.
- Shared installs are Spark-safe and repository-mediated.
- User-visible strings should come from localization or typed exceptions.

## Firebase Data Model

Main collections:

- `users`
- `jobs`
- `jobs/{jobId}/history`
- `expenses`
- `expenses/{expenseId}/history`
- `earnings`
- `earnings/{earningId}/history`
- `ac_installs`
- `ac_installs/{installId}/history`
- `companies`
- `shared_install_aggregates`
- `app_settings/approval_config`
- `app_settings/company_branding`

Important implementation notes:

- shared-install aggregate writes are blocked to normal clients and coordinated through repository transactions
- active-user checks are enforced in Firestore rules for technician writes
- approval history documents are immutable once created
- admin flush operations depend on both rules and repository code staying aligned

## Security Model

Security is layered across the client and Firestore rules.

Current protections:

- Firebase Auth for sign-in
- Firestore `isActiveUser()` gating for technician writes
- admin-only review transitions for approvals
- App Check enabled on Android
- repository-layer validation before writes
- localized typed exceptions instead of raw backend messages

Files to review before changing security-sensitive behavior:

- `firestore.rules`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/jobs/data/job_repository.dart`

## Localization and UI

Supported locales:

- English
- Urdu
- Arabic

UI characteristics:

- Material 3
- Arctic-themed styling
- RTL support for Urdu and Arabic
- locale-aware fonts
- shimmer and animated transitions for loading and UI polish

Localization sources live in `lib/l10n/` and generate `lib/l10n/app_localizations.dart`.

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x |
| Backend | Firebase Auth, Cloud Firestore, Hosting, App Check |
| State | Riverpod 3.x |
| Routing | GoRouter |
| Models | Freezed, json_serializable |
| Charts | fl_chart |
| Reporting | excel, pdf, printing, share_plus |
| File handling | file_picker |
| Rendering | flutter_svg, shimmer, flutter_animate |

## Setup

### Prerequisites

- Flutter SDK matching the repo Dart/Flutter constraints
- Android SDK for device builds and installs
- Firebase CLI for rules, indexes, and hosting deployment

### Install dependencies

```bash
flutter pub get
```

### Generate code and localization

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Run the app

### Android

```bash
flutter run -d <deviceId>
```

### Web

```bash
flutter run -d chrome
```

### List devices

```bash
flutter devices
```

## Validation workflow

Recommended local validation order:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
```

For backend and platform-sensitive changes also run:

```bash
flutter build apk --release
```

## Build and install

### Release APK

```bash
flutter build apk --release
```

### Release web

```bash
flutter build web --release
```

### Install release APK to a device

```bash
flutter install -d <deviceId> --release
```

Or manually:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Firebase deployment

### Firestore rules and indexes

```bash
firebase deploy --only firestore --project actechs-d415e
```

This repository is Spark-only. Do not deploy or add Cloud Functions.

## CI and automation

GitHub workflows currently cover:

- static analysis
- generated-code step
- tests
- debug APK build
- manual APK build workflow

Relevant files:

- `.github/workflows/ci.yml`
- `.github/workflows/build-apk.yml`
- `.github/workflows/release.yml`

The repo also includes release/version helpers under `scripts/` for bumping version numbers, building artifacts, installing builds, and pushing release changes.

## High-risk change areas

These parts of the repo need extra care because a narrow change can cascade across rules, repository logic, exports, and approvals:

- shared installs
- approval settings and approval history
- Firestore rules
- analytics summaries
- import/export formatting
- localization keys and RTL rendering

When touching any of those, update code and docs together and rerun the full validation workflow.

## Documentation

- `docs/firebase-setup-guide.md`
- `docs/error-messages.md`
- `docs/ultimate_master_audit_report_v6.txt`
- `docs/ultimate_master_fix_plan_v1.md`

## Current source of truth

`main` is the canonical branch for this repository.

If you change approval behavior, shared-install rules, model fields, or backend payloads, treat the following as a single contract that must stay synchronized:

- Flutter models
- repository write logic
- Firestore rules
- indexes
- tests
- operational documentation
