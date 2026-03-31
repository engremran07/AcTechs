# AC Techs — AC Technician Management System

Multi-role mobile + web app for an AC installation company in Saudi Arabia.

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
| State | Riverpod 2.x |
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
