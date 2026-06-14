# ZERO-TOLERANCE RELEASE SIGN-OFF — AC Techs

This is the release contract. Every gate is **blocking**: a single failure stops the
release. No step may be skipped, reordered, or "noted for later". The APK, web bundle,
and Firestore configuration must always ship from the same source tree.

Project: `actechs-d415e` · Package: `com.actechs.pk` · Surfaces: Android APK + Firebase Hosting

## Phase 1 — Static gates

| # | Gate | Command | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 1 | Analyzer | `flutter analyze` | exit 0 AND output contains `No issues found!` |
| 2 | Problems panel | `get_errors` on every file modified this session | zero issues, all file types |
| 3 | Format | `dart format --set-exit-if-changed lib test` | exit 0 |
| 4 | Rules lint | `cd scripts; npm run lint:firestore-rules` | zero `[W]` warnings |

## Phase 2 — Test gates

| # | Gate | Command | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 5 | Full suite | `flutter test --coverage` | 100% pass |
| 6 | Coverage floor | lcov summary on `coverage/lcov.info` | ≥ 80% lines (single source of truth — ci.yml AND audit.yml) |
| 7 | Rules emulator | `cd scripts; npm test` | all pass; no expression-limit evaluator messages |
| 8 | Codegen freshness | `dart run build_runner build --delete-conflicting-outputs` (if models changed) | exit 0, no diff surprises |
| 9 | L10n sync | `flutter gen-l10n` (if ARB changed) + key-parity check en/ur/ar | exit 0; identical key sets |

## Phase 3 — Version & governance gates

| # | Gate | Check | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 10 | versionCode monotonic | pubspec `+N` vs last installed/released build | strictly greater; never reused |
| 11 | whats_new coverage | `_changelog` map in `whats_new_dialog.dart` | key exists for current versionName, en/ur/ar all present |
| 12 | CHANGELOG entry | `## X.Y.Z+N` heading | exists for current version |
| 13 | MASTER_BLUEPRINT sync | `Current app version:` line | equals pubspec version |
| 14 | SESSION_LOG entry | latest entry | describes this release scope |
| 15 | Registry discipline | every regression fixed this cycle | has a REG-NNN entry + guard |

## Phase 4 — Firestore alignment gates (⛔ before ANY install/deploy)

| # | Gate | Command | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 16 | Rules deploy | `firebase deploy --only firestore:rules --project actechs-d415e` (if firestore.rules changed) | success BEFORE building APK |
| 17 | Indexes deploy | `firebase deploy --only firestore:indexes --project actechs-d415e` (if indexes changed) | success; wait for index build completion |

An APK that depends on undeployed rules WILL fail with silent PERMISSION_DENIED.
This is the highest-frequency historical failure mode (see REG-018 context).

## Phase 5 — Build & deploy gates

| # | Gate | Command | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 18 | Web build | `flutter build web --release` (with `--dart-define=FIREBASE_APP_CHECK_WEB_KEY=...` for live deploys) | exit 0 |
| 19 | Hosting deploy | `firebase deploy --only hosting --project actechs-d415e` | success; served version matches source |
| 20 | APK build | `flutter build apk --release --split-per-abi --no-tree-shake-icons` | exit 0 |
| 21 | Device install | `adb uninstall com.actechs.pk` then `adb install app-arm64-v8a-release.apk` | uninstall→install (NEVER `install -r`); app launches without PERMISSION_DENIED in logcat |
| 22 | Version visible | Settings → About on device | shows the new versionName+build |

## Phase 6 — Git hygiene gates

| # | Gate | Command | Pass criterion |
| --- | ------ | ------- | ---------------- |
| 23 | Tree state | `git status --short` | only intended changes; no stray logs/artifacts |
| 24 | Commit | `git add -A && git commit` | pre-commit hook passes; if hook bumps version, re-sync MASTER_BLUEPRINT |
| 25 | Push | `git push origin main` | success |

## Editing discipline (REG-018 protocol)

For any file > 800 lines:
- One logical block per edit; never multi-hunk structural patches.
- Run `get_errors` after EVERY edit; a single error stops further edits until fixed.
- If a file accumulates ≥ 3 failed patches, STOP: `git checkout HEAD -- <file>` and
  re-apply changes incrementally on the clean base.

## Self-healing loop

```text
Failure found → fix → rule (.claude/rules) → gate (audit.yml/ci.yml) → test (test/)
→ REGRESSION_REGISTRY entry → this checklist updated if a new phase/gate is needed
```

A release is signed off only when all 25 gates are green in order. Treat warnings —
including info-level lints — as failures. Zero tolerance means zero.
