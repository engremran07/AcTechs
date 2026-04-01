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
- **Feature folders**: auth, technician, admin, settings
- **Core**: shared theme, widgets, errors, extensions, utils, constants
- **Routing**: GoRouter with shell routes for bottom nav, auth redirect guard
- **Models**: Freezed immutable classes with JSON serialization
- **Errors**: Custom sealed exception hierarchy — NEVER show raw Firebase/Flutter errors
- **Offline**: Firestore local persistence enabled, connectivity_plus for detection

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

## Error Philosophy

Every user-facing message is custom-written, contextual, and tri-lingual. No raw exception strings, no "Error: PERMISSION_DENIED", no default SnackBars. Custom error cards with icon, title, description, action button.

## Recent Product Behaviors To Preserve

- Invoice display is normalized (no forced `INV-` prefix in UI)
- Historical import supports sheet-aware period naming and metadata notes
- Shared AC-type filtered job list route is used by both technician and admin dashboards
- Database flush has optional non-admin user deletion with explicit destructive warning UI
