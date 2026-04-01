# AC Techs - AC Technician Management System

📱 Multi-role Flutter app for AC installation operations in Saudi Arabia.

## ✨ Highlights

- 🧰 Technician-first daily workflow: invoice jobs, IN/OUT entries, and quick history access
- 🛡️ Admin control center: approvals, analytics, team/company management, and safe database flush
- 🌍 Full tri-lingual support: English + Urdu (RTL) + Arabic (RTL)
- 🔄 Real-time + offline-ready Firestore data flow
- 📄 Export pipeline for Excel and PDF reports
- 🧪 Production-focused structure with clean architecture and repository boundaries

## 🧩 Core Features

### Technician
- Submit jobs with invoice normalization and multi-unit AC support
- Track work and home expenses with daily IN/OUT summaries
- Open job details, call/WhatsApp from cards, and navigate filtered history views

### Admin
- Approve/reject pending jobs with notes
- Manage technicians and companies
- Run period and technician-scoped analytics
- Import historical Excel workbooks with technician mapping and period-aware parsing
- Flush operational data with a two-step confirmation and optional non-admin user deletion

## 🏗️ Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.x (Android + Web) |
| Backend | Firebase Auth + Cloud Firestore |
| State | Riverpod 3.x |
| Navigation | GoRouter with auth guards |
| Theme | Material 3 (Arctic style system) |
| Localization | ARB-based l10n (`en`, `ur`, `ar`) |
| Data Models | Freezed + JSON Serializable |
| Charts | fl_chart |
| Export | excel, share_plus, pdf, printing |

## 📂 Architecture

- Feature-first clean architecture under `lib/features/*`
- Layer split per feature: `data`, `domain`, `presentation`, `providers`
- Shared modules in `lib/core/*` (theme, constants, errors, widgets, utilities)
- Firestore access isolated in repositories

## 🚀 Getting Started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze
flutter test
```

Run app:

```bash
flutter run
flutter run -d chrome
```

Build artifacts:

```bash
flutter build apk --debug
flutter build apk --release --no-tree-shake-icons
flutter build web --release
```

## 📲 Install APK On Device

```bash
flutter devices
flutter install -d <deviceId> --use-application-binary build/app/outputs/flutter-apk/app-debug.apk
```

Alternative via ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 🧪 Debug Workflow

```bash
flutter analyze
flutter test
flutter logs
adb logcat | findstr /I "flutter dart AndroidRuntime FATAL EXCEPTION"
```

If Firestore permissions/indexes are out of sync:

```bash
firebase deploy --only firestore --project actechs-d415e
```

## 🔐 Firebase Notes

- Firestore rules and indexes are versioned in this repo
- Admin deletes are enabled by rules for operational cleanup flows
- Use repository methods for Firestore writes/deletes instead of direct UI-layer calls

## 📦 Project Identity

- Android package: `com.actechs.pk`
- Firebase project: `actechs-d415e`

## 📚 Additional Docs

- Firebase setup guide: [docs/firebase-setup-guide.md](docs/firebase-setup-guide.md)
- Error catalog: [docs/error-messages.md](docs/error-messages.md)
