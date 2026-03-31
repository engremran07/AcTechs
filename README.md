# AC Techs — AC Technician Management System

Multi-role mobile + web app for an AC installation company in Saudi Arabia.

## About Repo

🚀 Welcome to AC Techs: a production-focused, tri-lingual technician operations app built for real field work in Saudi Arabia.

✨ What makes this repo special:
- Fast technician workflows for invoices and daily IN/OUT tracking
- Admin-first control for approvals, team management, and companies
- Real-time Firebase sync with offline resilience
- RTL-ready Urdu/Arabic UX and export support
- Practical architecture optimized for scaling features without chaos

💡 If you want one repo that is clean, deployable, and business-ready for AC service operations, this is it.

## Features

- **Technicians**: Submit invoices with company-specific prefixes, batch-add daily IN/OUT entries, separate work and home expenses, view history, and track approval status
- **Admins**: Approve/reject jobs, view analytics, manage technicians, manage client companies, and export to Excel/PDF
- **Tri-lingual**: English, Urdu (RTL), Arabic (RTL)
- **Offline-first**: Firestore local persistence with automatic sync
- **Theme modes**: Auto, Dark, Light, High Contrast

## Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x (Android APK + Web) |
| Backend | Firebase Auth + Firestore (Spark/free tier) |
| State | Riverpod 3.x |
| Navigation | GoRouter with auth redirect guards |
| Theme | Material 3 Dark, arctic blue (#00D4FF) seed |
| Fonts | Syne + DM Sans (English), NotoNastaliqUrdu (Urdu), NotoNaskhArabic (Arabic) — bundled offline |
| Charts | fl_chart |
| Export | excel + share_plus (Excel), pdf + printing (PDF with RTL) |
| i18n | flutter_localizations + ARB (en, ur, ar) |
| Models | freezed + json_serializable |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate freezed/json code
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Run on connected device
flutter run

# Run on Chrome
flutter run -d chrome

# Build release APK
flutter build apk --release

# Build release web
flutter build web --release

# Lint check
flutter analyze

# Run tests
flutter test
```

## Install On Phone (Debug + Release)

### 1) Build APKs

```bash
# Debug APK (faster builds, development)
flutter build apk --debug

# Release APK (optimized production build)
flutter build apk --release --no-tree-shake-icons
```

### 2) Install APK To Connected Android Device

```bash
# Verify device is connected
adb devices

# Install debug APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Install release APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 3) Run Directly In Debug Mode (alternative)

```bash
flutter run -d <deviceId>
```

Use `flutter devices` to list available device IDs.

## Realtime Logs And Rapid Fix Workflow

### Collect realtime logs

```bash
# Flutter app logs (best for Dart exceptions)
flutter logs

# Full Android logs (filter later for app/package)
adb logcat

# Useful filtered logcat (Windows PowerShell)
adb logcat | findstr /I "flutter dart AndroidRuntime FATAL EXCEPTION"
```

### Triage and fix loop

```bash
# 1) Analyze static issues
flutter analyze

# 2) Run tests
flutter test

# 3) Re-run app and monitor logs
flutter run -d <deviceId>
```

Recommended issue-fix order:
1. Crash/exception blockers from `AndroidRuntime` or Dart stack traces
2. Firestore permission and write failures
3. UI overflows and input/cursor issues
4. Localization and RTL layout mismatches

For Firebase permission errors, ensure rules/indexes are deployed:

```bash
firebase deploy --only firestore --project actechs-d415e
```

## Dependency Status

- Riverpod stack is on 3.x: `flutter_riverpod`, `riverpod_annotation`, and `riverpod_generator`
- Dependency health command: `flutter pub outdated`
- Policy: avoid deprecated packages and keep versions actively maintained
- Some packages may be intentionally pinned below latest major versions for Flutter SDK compatibility and stability

## Firebase Setup

See [docs/firebase-setup-guide.md](docs/firebase-setup-guide.md) for full setup instructions.

## Architecture

Clean Architecture with feature folders: `auth`, `technician`, `admin`, `expenses`, `settings`.  
Each feature has `data/`, `domain/`, `presentation/`, and `providers/` layers.  
Shared code lives in `core/` (theme, widgets, errors, utils, constants).

## Current Functional Areas

- `admin/team`: create, edit, deactivate, delete, and reset-password flows for technicians
- `admin/companies`: add, edit, and activate/deactivate installation companies and invoice prefixes
- `tech/submit`: submit invoice jobs against an active company
- `tech/inout`: batch-add daily earnings and expenses, including separate home-expense tracking
- `tech/summary`: monthly totals for earnings, work expenses, home expenses, and net profit
- `settings`: locale-aware themes and language switching

## Package

- **Android Package**: `com.actechs.pk`
- **Firebase Project**: `actechs-d415e`
