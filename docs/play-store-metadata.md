# Play Store Metadata Checklist

## Listing Content (PLAY-003)

- App name: AC Techs
- Short description: Internal operations app for AC installation technicians and admins
- Full description: Explain job capture, approvals, in/out tracking, and reporting
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Phone screenshots: at least 2 for technician flows and 2 for admin flows

## Policy and Privacy (PLAY-001)

- Privacy policy URL: `https://your-hosting-domain/privacy-policy.html`
- Ensure policy URL is publicly accessible without authentication
- Keep policy content aligned with actual data usage and Crashlytics collection

## Data Safety Form (PLAY-003)

- Data collected:
  - Personal info: name, email, optional phone
  - App activity / operational records: jobs, approvals, earnings, expenses
  - Diagnostics: crash logs (Crashlytics)
- Data sharing: No
- Data encrypted in transit: Yes
- Data deletion process: via internal administrator support workflow

## Crash Reporting (PLAY-002)

- Dependency present: `firebase_crashlytics`
- Runtime wiring present in `main.dart`
- ProGuard mapping uploaded in release workflow artifacts

## Pre-Submission Gate

1. Run `flutter analyze --no-pub`
2. Run `flutter test --coverage`
3. Run `flutter build appbundle --release`
4. Verify privacy policy URL resolves in browser
5. Verify `mapping.txt` artifact generated for the release
