---
description: "Use when: user asks to build, deploy, release, sync web and APK, or when user-visible Flutter changes must ship consistently across Hosting and Android."
applyTo: "lib/**,web/**,android/**,firebase.json,firestore.rules,firestore.indexes.json,pubspec.yaml,README.md,.github/workflows/**"
---

# Release Surface Sync Instruction

Treat web and APK as one release surface.

- If user-visible behavior, branding, About content, navigation, auth flow, dashboards, localization, or reports changed, do not assume prior build artifacts are still valid.
- Before any release build, confirm pubspec version/build matches the intended release.
- Never claim Hosting and APK are in sync unless both artifacts came from the same current source tree.

Required order when user asks for release or deploy:

1. Run `flutter analyze` and any task-specific tests first.
2. Check `git status --short` so the release surface is explicit.
3. Build web when the request affects Firebase Hosting.
4. Deploy Hosting when web output is part of the request.
5. Deploy Firestore rules and indexes when query behavior or permissions changed.
6. Build release APK when Android delivery is part of the request.
7. Install APK to a connected device only if the user asked for it.
8. Commit or push only after validation and requested build or deploy steps succeed.

Strict quality gates (must pass with zero warnings):

- **BLOCKING**: `flutter analyze` exit code must be 0 AND output must contain "No issues found!" before any build or deploy step. Exit code 1 even with only info-level messages is a hard stop.
- Use `get_errors` on every recently modified file BEFORE running `flutter analyze` to catch Problems-tab issues that the IDE surfaces but the CLI may have missed in a previous run.
- Treat warnings (including `info`) as failures for release readiness (rules, lint, analyzer, tests, deploy checks).
- Run `npm run lint:firestore-rules` in `scripts/` before rules tests or rules deploy.
- Run Firestore rules emulator tests and confirm there are no expression-limit evaluator messages in the run logs.
- If any gate produces warnings or expression-limit noise, perform a micro-pass and re-run gates until clean before deploy.

Release verification rules:

- Confirm the displayed app version and build in Settings/About match the built source.
- If web looks older than APK, inspect Hosting cache behavior and the service worker before assuming source drift.
- Do not treat generated build outputs as authoritative if source, localization, routing, or Firebase config changed afterward.
