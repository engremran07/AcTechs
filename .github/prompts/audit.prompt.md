---
mode: agent
description: Full cross-team audit. Launches 4 specialised subagents concurrently then synthesises findings.
---

# /audit — AC Techs Full System Audit

Launch **four** subagents concurrently using `runSubagent`. Each agent must search the actual codebase — do **not** guess.

## Subagent 1 — backend-engineer
Audit scope:
- Firestore security rules: verify no `doc.delete()` paths for tech-owned records (expenses, earnings, installs); verify `teamMemberIds` present on every new aggregate create payload; verify all optional settlement fields use `.get('field', null)` safe access
- Repositories: confirm `archiveExpense`, `archiveEarning`, `archiveInstall` exist (not `delete`); confirm stream mappers filter `isDeleted != true`
- Indexes: verify `firestore.indexes.json` includes `shared_install_aggregates → teamMemberIds`
- Report: list of findings with file path + line number

## Subagent 2 — frontend-engineer
Audit scope:
- `submit_job_screen.dart`: confirm `_selectedTeamMembers` list exists (not `_sharedTeamSize` int); team selector UI present; delivery split = `rawDelivery / (_selectedTeamMembers.length + 1)`
- `daily_in_out_screen.dart`: confirm swipe/dismiss calls `archiveExpense/Earning` (not `delete`); undo SnackBar present
- All user-facing strings via `context.l10n` — no hardcoded strings
- RTL layout check for Urdu/Arabic locales
- Report: list of findings with file path + line number

## Subagent 3 — qa-engineer
Audit scope:
- `flutter analyze` output — zero issues required
- `flutter test` — all tests pass; `test/unit/expenses/archive_lifecycle_test.dart` exists
- Shared install team selection covered by at least one test
- Archive/restore lifecycle covered by tests
- All providers handle loading/error/data states
- Report: list of findings, test counts, coverage gaps

## Subagent 4 — security-auditor
Audit scope:
- Confirm no `doc.delete()` in tech-accessible repositories
- Confirm `teamMemberIds` size ≤ 10 guard exists in rules
- Confirm `allow list` on `/users/{userId}` is scoped to `isActiveUser() || isAdmin()` only
- Confirm App Check is active on Android; note if web App Check is missing
- Confirm no PII leaked to client logs
- Report: list of findings with severity (CRITICAL / HIGH / MEDIUM / LOW)

## Synthesis
After all 4 subagents complete:
1. Aggregate all CRITICAL and HIGH findings first
2. Produce a closure matrix table: `| Item | Status | File | Line |`
3. List any items that are OPEN (not yet implemented)
4. Recommend next implementation priority
