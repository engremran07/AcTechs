# Firebase Setup Guide — AC Techs

## Your Firebase Project
- **Project ID**: actechs-d415e
- **Console**: https://console.firebase.google.com/u/2/project/actechs-d415e/overview
- **Plan**: Spark (Free)

---

## Step 1: Register Android App

1. Go to: https://console.firebase.google.com/u/2/project/actechs-d415e/settings/general
2. Click **Add app** → **Android**
3. Package name: `com.actechs.pk`
4. App nickname: `AC Techs Android`
5. SHA-1: (optional for now, needed for Google Sign-In later)
6. Click **Register app**
7. Download `google-services.json`
8. Place it at: `android/app/google-services.json`

## Step 2: Register Web App

1. Same settings page → **Add app** → **Web**
2. App nickname: `AC Techs Web`
3. Click **Register app**
4. Copy the firebaseConfig object (you'll need it for `firebase_options.dart`)

## Step 3: Enable Authentication

1. Go to: https://console.firebase.google.com/u/2/project/actechs-d415e/authentication
2. Click **Get started**
3. Enable **Email/Password** provider
4. Keep "Email link (passwordless sign-in)" disabled

## Step 4: Create Firestore Database

1. Go to: https://console.firebase.google.com/u/2/project/actechs-d415e/firestore
2. Click **Create database**
3. Choose **Start in production mode** (we'll set proper rules)
4. Select region: **asia-south1** (closest to Saudi Arabia that's available) or **europe-west1**
5. Click **Enable**

## Step 5: Deploy Firestore Security Rules

Copy the rules from `firestore.rules` in the project root and paste them in:
https://console.firebase.google.com/u/2/project/actechs-d415e/firestore/rules

## Step 6: Create Firestore Indexes

Go to: https://console.firebase.google.com/u/2/project/actechs-d415e/firestore/indexes

Create these composite indexes for the `jobs` collection:

| Fields | Order |
|--------|-------|
| `techId` ASC, `submittedAt` DESC | Collection |
| `techId` ASC, `date` DESC | Collection |
| `status` ASC, `submittedAt` ASC | Collection |
| `status` ASC, `date` ASC, `date` ASC | Collection |

## Step 7: Create Initial Admin User

1. Go to Authentication → Users
2. Click **Add user**
3. Email: `admin@actechs.pk` (or your preferred admin email)
4. Password: (set a strong password)
5. Copy the **User UID**

Then in Firestore → Data:
1. Create collection: `users`
2. Add document with ID = the User UID you copied
3. Fields:
   - `uid`: (string) the User UID
   - `name`: (string) "Admin"
   - `role`: (string) "admin"
   - `isActive`: (boolean) true
   - `createdAt`: (timestamp) now
   - `language`: (string) "en"

## Step 8: Create Technician Users

Repeat Step 7 for each technician, but set `role` to `"technician"`.

## Step 9: FlutterFire CLI (Alternative Setup)

If you have the FlutterFire CLI installed:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=actechs-d415e
```

This auto-generates `firebase_options.dart` and configures platform files.

---

## Firebase Free Tier Limits

| Resource | Free Limit | AC Techs Est. Usage |
|----------|-----------|-------------------|
| Auth users | Unlimited | ~20 |
| Firestore reads/day | 50,000 | ~10,000 |
| Firestore writes/day | 20,000 | ~450 |
| Firestore deletes/day | 20,000 | ~0 |
| Firestore storage | 1 GiB | ~50 MB |
| Firestore network | 10 GiB/month | ~1 GiB |

**15 technicians × 30 jobs/day = 450 writes/day** — well within the 20,000 limit.

---

## Troubleshooting

**"Permission denied" errors**: Check Firestore rules. The user's role in the `users` collection must match the rule expectations.

**"No Firebase App" error**: Ensure `Firebase.initializeApp()` is called in `main.dart` before `runApp()`.

**Web CORS issues**: Firebase Auth and Firestore handle CORS automatically. If you see CORS errors, check that the web app is registered correctly.

**Offline not working**: Firestore persistence is enabled by default in Flutter. Check that you haven't explicitly disabled it.
