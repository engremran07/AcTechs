# AcTechs — Product Requirements Document (PRD)

**Version:** 2.2.8+97  
**Last Updated:** 2026-06-09  
**Status:** Production · Internal Deployment · Single-tenant (Saudi Arabia)

---

## 1. Vision

AC Techs is a **multi-role field operations management app** for an HVAC installation and maintenance company.
It digitises the entire job lifecycle — from technician submission through admin approval to settlement — replacing WhatsApp
screenshots and manual Excel tracking.

**Core value proposition:**
- Technicians submit jobs from the field via Android APK; no data-entry lag.
- Admins approve, reject, transfer, and settle jobs from the same app.
- All financial records (jobs, expenses, earnings) are tied to a locked-period audit trail.
- Settlement workflow produces a monthly pay batch that is disputeable by technicians.

---

## 2. User Types

| Role | App Access | Key Workflows |
| --- | --- | --- |
| **Admin** | Android + Web | Approve jobs, view analytics, manage team, settle invoices, flush/export data |
| **Technician** | Android only | Submit jobs, record in/out expenses, respond to settlements, view history |

---

## 3. Feature Inventory

### 3.1 Job Management
| Feature | Status | Notes |
| --- | --- | --- |
| Job submission (tech) | ✅ Shipped | Multi-AC-type, client contact, company, shared install |
| Job approval (admin) | ✅ Shipped | Approve, reject, edit-approve, bulk approve |
| Job edit request (tech) | ✅ Shipped | Tech can flag approved job for correction |
| Admin job edit | ✅ Shipped | Admin can correct approved+unpaid jobs |
| Job transfer (admin) | ✅ Shipped | Reassign unpaid job to different tech |
| Job transfer (tech-initiated) | ✅ Shipped | Request or direct transfer depending on config |
| Pending transfer requests (admin) | ✅ Shipped | Approvals screen section |
| Bulk job transfer | ✅ Shipped | Multi-select + parallel Future.wait |
| Shared installs | ✅ Shipped | Multi-tech contribution, team split, aggregate tracking |

### 3.2 Settlement
| Feature | Status | Notes |
| --- | --- | --- |
| Settlement batch initiation | ✅ Shipped | Admin marks approved+unpaid jobs as awaiting_technician |
| Settlement response (tech) | ✅ Shipped | Confirm, dispute, request correction |
| Settlement correction | ✅ Shipped | Admin adjusts disputed amount |
| Settlement history | ✅ Shipped | Full audit trail |
| Settlement cap warning | ✅ Shipped | Banner when >200 records (PER-001) |

### 3.3 In/Out (Expense & Earning Tracking)
| Feature | Status | Notes |
| --- | --- | --- |
| Daily expense/earning entry | ✅ Shipped | Work + Home categories |
| Monthly summary | ✅ Shipped | Per-tech, per-category |
| Admin In/Out approval | ✅ Shipped | Optional (configurable) |
| AC install tracking | ✅ Shipped | Per-type breakdown |
| Period lock | ✅ Shipped | Admin can lock historical periods |

### 3.4 Team Management
| Feature | Status | Notes |
| --- | --- | --- |
| Add/edit technician | ✅ Shipped | PhoneInputField with country code (KSA default) |
| Phone number picker | ✅ Shipped | E.164 normalisation on save |
| Team search | ✅ Shipped | UserSearchFilter (name, email, phone digits) |
| Deactivate user | ✅ Shipped | Soft-deactivate (rules check isActive) |
| Resend invitation | ❌ Not shipped | Currently no resend button |

### 3.5 Analytics & Reports
| Feature | Status | Notes |
| --- | --- | --- |
| Admin analytics dashboard | ✅ Shipped | Job counts, settlement summaries, fl_chart |
| Excel export (jobs, expenses, earnings) | ✅ Shipped | XLSX via excel package |
| PDF export (jobs, settlement) | ✅ Shipped | RTL-aware, compute() isolated |
| Historical import | ✅ Shipped | Excel → Firestore with locked-period warning |

### 3.6 Settings & Configuration
| Feature | Status | Notes |
| --- | --- | --- |
| Job approval toggle | ✅ Shipped | Per approval config |
| Shared install approval toggle | ✅ Shipped | |
| In/Out approval toggle | ✅ Shipped | |
| Minimum build enforcement | ✅ Shipped | Forces outdated techs to update APK |
| Period lock management | ✅ Shipped | Lock historical months from editing |
| Tech transfer toggles | ✅ Shipped | Allow + requires-approval flags |

### 3.7 Infrastructure
| Feature | Status | Notes |
| --- | --- | --- |
| Multilingual (EN/UR/AR) | ✅ Shipped | RTL support, locale-aware fonts |
| What's New dialog | ✅ Shipped | Once per version, locale-aware |
| Offline persistence | ✅ Shipped | 50MB Firestore cache |
| Screen content protection | ✅ Shipped | FLAG_SECURE on settlement screen |
| WhatsApp contact chooser | ✅ Shipped | Business vs Personal, MethodChannel detection |
| Zoom drawer navigation | ✅ Shipped | Both shells |

---

## 4. User Stories (Selected)

**As a technician**, I want to submit a job from the field with the client's phone number so the admin can contact them directly.

**As an admin**, I want to bulk-transfer all jobs from a leaving technician to another in one action.

**As a technician**, I want to see a clear indicator when my job has a pending transfer request so I know what's happening to it.

**As an admin**, I want to export a settlement PDF for a specific technician and month so I can share it via WhatsApp.

**As a technician**, I want to choose between WhatsApp Business and regular WhatsApp when opening a client contact.

---

## 5. Non-functional Requirements

| Requirement | Target | Current Status |
| --- | --- | --- |
| Android support | API 29+ (Android 10+) | ✅ minSdk = 29 |
| Offline capability | Core workflows offline | ✅ Firestore 50MB cache |
| Response time | <2s for job submit | ✅ Firestore write < 500ms |
| Read budget (Spark) | <50k reads/day | ⚠️ allJobs capped at 150 |
| RTL support | Arabic + Urdu | ✅ supportsRtl + RTL-aware fonts |
| Security | App Check (Android + Web) | ✅ Play Integrity + reCAPTCHA v3 |
| Privacy | No cloud backup | ✅ allowBackup=false |

---

## 6. Roadmap (Pending)

| Item | Priority | Notes |
| --- | --- | --- |
| Phone numbers retroactive normalisation | P2 | One-time migration of stored `UserModel.phone` values |
| Firebase Crashlytics | P2 | Free, add to pubspec + main.dart |
| Privacy policy URL | P3 | Required for Play Store public listing |
| Push notifications | P4 | Requires Blaze tier (FCM) |
| Global search screen | P4 | Cross-domain search at /admin/search |
