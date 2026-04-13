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
- Animations: prefer flutter_animate with 220ms entrance, 180ms exit, and 60ms stagger steps; reserve longer elastic motion for one accent element only
- Bottom navigation: Tech has **5 tabs** (Home / Submit / In-Out / History / Settings); Admin has **4 tabs** (Dashboard / Approvals / Analytics / Team). Settlement and shared-install screens are accessed from dashboard cards or history badges — they are NOT bottom-nav tabs.
- Shell route index rules: `_currentIndex()` MUST return `-1` for pushed non-tab routes such as settings, settlements, imports, flush, companies, summary, and detail screens.
- Screen padding: EdgeInsets.symmetric(horizontal: 16)
- Card spacing: 10-12px gap between cards
- Destructive actions must include explicit warning affordances (color, icon, confirmation)
- Use ArcticRefreshIndicator instead of raw RefreshIndicator.
- **Zoom Drawer**: Both `TechShell` and `AdminShell` use `ZoomDrawerWrapper` for side navigation. Access the controller via `ZoomDrawerScope.of(context).toggle()`. RTL auto-inverts slide direction. Defined in `lib/core/widgets/zoom_drawer.dart` + `drawer_menu_content.dart`.
- **Stale Shared Install Cleanup Card**: Admin dashboard only. Shows shared aggregates >30 days old with no new contributions. Archive action with confirmation dialog.
