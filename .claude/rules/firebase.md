---
description: Firebase and data-layer rules for AC Techs.
paths:
	- lib/features/*/data/**
---

# Firebase & Data Layer Rules — AC Techs

- All Firestore operations go through repository classes
- Use Firestore snapshots (streams) for real-time data, not one-time get()
- Wrap all Firebase calls in try/catch, convert to AppException
- Never expose FirebaseException messages to users
- Denormalize frequently-queried fields (e.g., techName in job docs)
- Use compound indexes for multi-field queries
- Collection paths are constants in `AppConstants`
- All write operations validate data before sending to Firestore
- Offline: Firestore persistence handles caching automatically
- Free tier awareness: minimize reads, use pagination for large lists
- Destructive operations (delete/flush) must be admin-only and triggered from repository methods
