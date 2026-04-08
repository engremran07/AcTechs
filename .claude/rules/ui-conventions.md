---
description: UI conventions for presentation-layer files.
paths:
	- lib/features/*/presentation/**
---

# UI Conventions — AC Techs

- Theme: Material 3 Dark, arctic blue (#00D4FF) seed color
- Custom Arctic widgets for consistent look: ArcticCard, ArcticButton, ArcticInput, ArcticBadge
- Glassmorphism style: semi-transparent backgrounds with subtle borders
- Status colors: cyan=info, amber=pending, green=approved, red=rejected
- Error display: custom ErrorCard widget, NOT default SnackBar or AlertDialog
- Success display: custom SuccessCard with animated checkmark
- Loading: prefer shimmer skeleton screens for list/page loading; inline progress indicators are acceptable for short button actions
- All text via context.l10n — zero hardcoded display strings
- RTL support: test all screens with Urdu/Arabic locale
- Animations: flutter_animate, max 300ms duration, ease curves
- Bottom navigation: Tech has **5 tabs** (Home / Submit / In-Out / History / Settings); Admin has **4 tabs** (Dashboard / Approvals / Analytics / Team). Settlement and shared-install screens are accessed from dashboard cards or history badges — they are NOT bottom-nav tabs.
- Screen padding: EdgeInsets.symmetric(horizontal: 16)
- Card spacing: 10-12px gap between cards
- Destructive actions must include explicit warning affordances (color, icon, confirmation)
