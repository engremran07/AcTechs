# AC Techs

AC Techs is a multi-role Flutter application for AC installation operations, technician productivity, approvals, reporting, and company management. It targets Android and Web, runs on Firebase Auth and Cloud Firestore, and is built for day-to-day field usage with offline-friendly data access, tri-lingual UI, and admin-safe operational tooling.

## What The App Does

The app supports two operational roles:

- Technicians record invoice-based AC installation jobs, including shared installs, additional charges, and daily IN/OUT entries.
- Admins review approvals, monitor analytics, manage team members and companies, import historical workbooks, export reports, and maintain app-level settings.

Recent work in the app includes:

- secure shared-install aggregation without cross-technician Firestore reads
- shared invoice totals, bracket shares, delivery split handling, and mismatch protection
- dynamic app version and build number display inside settings
- company branding and logo handling with base64 and SVG-aware rendering
- centralized success and error feedback patterns
- release version automation for APK, Web, and Git workflows
- improved approval behavior with approval toggles defaulting to off

## Current Feature Set

### Technician Features

- submit invoice jobs with normalized invoice numbers
- record multiple AC unit types on a single invoice
- create shared installs with invoice-wide totals and technician-specific shares
- split delivery charges across a shared team
- assign bracket shares per technician for shared jobs
- view detailed job cards, history, and invoice-aware contribution summaries
- track daily work and home IN/OUT entries
- export history PDFs
- access company/support information from settings

### Shared Install Workflow

Shared installs are now handled through a dedicated aggregate document per shared invoice group.

- Technician 1 creates or joins a shared invoice group and submits their share.
- The app writes the technician job and updates the shared aggregate in one transaction.
- Technician 2 or later submits against the same group key and same invoice totals.
- The aggregate validates remaining split, window, freestanding, bracket, and delivery capacity.
- If a technician enters different totals for the same shared invoice, the app blocks the submission with a mismatch error.
- If a shared job is rejected, its reserved share is released back to the aggregate so the remaining valid shares can still be submitted.

This design fixes the earlier permission issue caused by querying other technicians' job documents directly.

### Admin Features

- approve or reject pending jobs with notes
- bulk approve job queues
- review shared-install context directly from approvals
- view invoice-aware analytics for shared and solo work
- manage technicians and activate/deactivate accounts
- manage companies and company logos
- configure approval toggles for jobs, shared jobs, and IN/OUT entries
- enforce minimum supported build if needed
- import historical Excel files with technician mapping and period-aware naming
- export Excel and PDF reports
- run controlled database flush operations with destructive confirmation

### UX And Platform Features

- English, Urdu, and Arabic localization
- RTL support for Urdu and Arabic
- offline-friendly Firestore behavior
- dynamic version and build display in settings
- support phone and WhatsApp quick actions
- compact Arctic UI system with Material 3 styling

## Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x |
| Targets | Android APK, Web, Windows dev support |
| Backend | Firebase Auth, Cloud Firestore, Firebase App Check |
| State | Riverpod 3.x |
| Navigation | GoRouter |
| Models | Freezed, json_serializable |
| Localization | ARB-based l10n (`en`, `ur`, `ar`) |
| Charts | fl_chart |
| Export | excel, pdf, printing, share_plus |
| UI | flutter_animate, shimmer, flutter_svg |

## Project Identity

- App name: `AC Techs`
- Android package: `com.actechs.pk`
- Firebase project: `actechs-d415e`
- Current app version source: [pubspec.yaml](pubspec.yaml)

## Architecture

The project uses a feature-first clean structure:

```text
lib/
	core/        shared constants, widgets, utilities, theme, models
	features/    feature modules split by data/domain/presentation/providers
	l10n/        ARB and generated localization files
	routing/     app router and shells
```

Key architectural rules:

- Firestore access belongs in repositories
- UI should not expose raw Firebase errors
- user-facing messages come from localized app strings or `AppException`
- shared-install validation is aggregate-driven, not cross-user query driven
- branding, package info, and reusable feedback are centralized in core modules

## Important Collections

- `users`
- `jobs`
- `expenses`
- `earnings`
- `companies`
- `app_settings`
- `shared_install_aggregates`

## Setup

### Prerequisites

- Flutter SDK compatible with the repo's Dart constraint
- Firebase CLI for rules/index deployment
- Android SDK for APK builds and installs
- a configured Firebase project matching `actechs-d415e`

### Install Dependencies

```bash
flutter pub get
```

### Generate Code

Run these whenever models or localization sources change:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Static Validation

```bash
flutter analyze
flutter test
```

## Run The App

### Android

```bash
flutter run -d <deviceId>
```

### Web

```bash
flutter run -d chrome
flutter run -d edge
```

### See Connected Devices

```bash
flutter devices
```

## Build Outputs

### Release APK

```bash
flutter build apk --release
```

### Release Web

```bash
flutter build web --release
```

## Install On Android Device

Install the currently built release app:

```bash
flutter install -d <deviceId> --release
```

Or install a built APK manually:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Versioning And Release Automation

The repo includes a PowerShell release helper in [scripts/bump_version.ps1](scripts/bump_version.ps1).

Examples:

```powershell
.\scripts\bump_version.ps1
.\scripts\bump_version.ps1 -Build
.\scripts\bump_version.ps1 -Build -Web
.\scripts\bump_version.ps1 -Build -Install
.\scripts\bump_version.ps1 -Build -Web -Install -Push
```

What it does:

- increments `pubspec.yaml` version and build number
- can build release APK and Web artifacts
- can install a release build
- can commit and push the version bump without triggering a double bump from git hooks

Git hooks are installed through [scripts/install-hooks.ps1](scripts/install-hooks.ps1).

## Firebase Operations

### Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules --project actechs-d415e
```

### Deploy Rules And Indexes

```bash
firebase deploy --only firestore --project actechs-d415e
```

### Notes

- Firestore rules are part of the repo in [firestore.rules](firestore.rules)
- Firestore indexes are versioned in [firestore.indexes.json](firestore.indexes.json)
- shared installs depend on the `shared_install_aggregates` rules being deployed with the app changes

## Developer Workflow

Recommended local workflow:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

Useful diagnostics:

```bash
flutter logs
adb logcat | findstr /I "flutter dart AndroidRuntime FATAL EXCEPTION"
```

## Current Product Behavior To Preserve

- solo jobs save directly as approved when approval is off
- shared jobs respect `sharedJobApprovalRequired`
- invoice display stays normalized without forcing an `INV-` prefix in UI
- shared-install metrics appear across technician history, details, dashboard, approvals, analytics, and export flows
- settings show company branding, support contacts, version/build info, and developed-by attribution
- company logos support base64 image data and SVG rendering paths

## Documentation

- Firebase setup guide: [docs/firebase-setup-guide.md](docs/firebase-setup-guide.md)
- Error and success message catalog: [docs/error-messages.md](docs/error-messages.md)

## Repository Notes

This project is under active product iteration. If you change models, Firestore rules, approval logic, shared-install behavior, or l10n keys, update both the implementation and the corresponding operational docs in the same change.
