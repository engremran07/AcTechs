# Ultimate Master Fix Plan v1

## Phase 1

- Risk: Critical. Blast radius: High. Harden Firestore technician access so operational collections require an active provisioned user profile, not just a valid auth token.
- Risk: Critical. Blast radius: High. Lock AC-install approval fields behind admin-only review transitions, record review history, and remove technician-side destructive deletion from the workflow.
- Risk: High. Blast radius: High. Add missing regression harnesses for Firestore rules, shared-install aggregate behavior, router redirects, and approval UI so approval-path regressions fail fast.
- Risk: High. Blast radius: Medium. Add the missing `jobs(status, isSharedInstall, submittedAt)` index so approved shared-install review queries do not fail in production.

## Phase 2

- Risk: High. Blast radius: Medium. Replace broad shared-aggregate write permissions with a server-mediated reservation flow; current transaction validation is good, but direct aggregate writes still need a tighter authority boundary.
- Risk: High. Blast radius: Medium. Remove remaining technician-side destructive deletes for jobs, expenses, and earnings once the same review and correction pattern is in place across those modules.
- Risk: Medium. Blast radius: Medium. Convert user deactivation from document deletion to a soft-disable path so auth semantics and rules enforcement stay aligned.

## Phase 3

- Risk: Medium. Blast radius: Medium. Remove `dart:io` imports from shared app graph paths so the web target builds cleanly.
- Risk: Medium. Blast radius: Medium. Tighten admin analytics and summary aggregation around stable technician identifiers instead of display names.
- Risk: Medium. Blast radius: Low. Expand export, localization, and RTL regression coverage after backend approval paths are locked down.