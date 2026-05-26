# Khayal Platform

Khayal is a **Flutter** mobile app for medication reminders and care coordination. Patients manage daily medicines and dose alarms; caregivers and doctors can link to patients, view adherence, and (for doctors) chat with patients on a paid subscription.

**Backend:** [Supabase](https://supabase.com) (PostgreSQL, Auth, Storage, Realtime, Edge Functions)  
**Payments (chat):** [Stripe](https://stripe.com) via Supabase Edge Functions  
**Maps:** OpenStreetMap (client-side, no map server of our own)

This document explains **how the app works from start to end** — frontend (Flutter) through to backend (Supabase and Stripe). For database table definitions, see `.md files/DATABASE.md`. For RLS policies, see `supabase/sql/`.

---

## Table of contents

1. [Architecture at a glance](#architecture-at-a-glance)
2. [Tech stack](#tech-stack)
3. [App startup (cold start → first screen)](#app-startup-cold-start--first-screen)
4. [Onboarding and sign-in](#onboarding-and-sign-in)
5. [Roles and home screens](#roles-and-home-screens)
6. [Linking patient ↔ caregiver / doctor](#linking-patient--caregiver--doctor)
7. [Medicines and dose tracking](#medicines-and-dose-tracking)
8. [Dose reminders and alarms](#dose-reminders-and-alarms)
9. [Doctor–patient chat and Stripe](#doctorpatient-chat-and-stripe)
10. [Maps and medicine photos](#maps-and-medicine-photos)
11. [How the Flutter app talks to Supabase](#how-the-flutter-app-talks-to-supabase)
12. [Backend layout (Supabase)](#backend-layout-supabase)
13. [Frontend layout (`lib/`)](#frontend-layout-lib)
14. [Environment and run](#environment-and-run)

---

## Architecture at a glance

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter app (Android / iOS)                  │
│  UI screens  →  Backend.repo / Backend.chat / chatBilling       │
│  Local: notifications, TTS, ringtone, timers, SharedPreferences │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS (REST + Auth + Realtime WS)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Supabase                                 │
│  • Postgres + RLS    • Auth (JWT)    • Storage (photos)         │
│  • Realtime (chat)   • Edge Functions (Stripe)                   │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS (server-side API)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                            Stripe                                │
│  Checkout, subscriptions, webhooks → updates DB subscription row │
└─────────────────────────────────────────────────────────────────┘
```

**Important:** There is **no custom WebSocket server**. Live chat uses **Supabase Realtime** (WebSocket transport managed by the Supabase SDK). Dose alarms use **on-device** scheduling, not push from your server.

---

## Tech stack

| Layer | Technology | Purpose |
|--------|------------|---------|
| UI | Flutter / Dart | All screens, navigation, local state |
| API client | `supabase_flutter` | Queries, auth, storage, realtime |
| Dose alarms (OS) | `flutter_local_notifications` | Lock-screen / closed-app notifications |
| Dose alarms (in-app) | `Timer` + `flutter_ringtone_player` + `flutter_tts` | Voice + ringtone while app is open |
| Timezone | `timezone` (Asia/Karachi) | Schedule daily dose notifications |
| Chat payments | Stripe Checkout in `webview_flutter` | Monthly subscription |
| Maps | `flutter_map` + OSM / Overpass | Nearby clinics, set home |
| Config | `flutter_dotenv` (`.env`) | Supabase URL, keys, secrets |

---

## App startup (cold start → first screen)

```text
main()
  → load .env (AppEnv)
  → load language + reminder preferences from disk
  → initialize MedicationNotificationService (channels, permissions)
  → Supabase.initialize(url, anonKey)
  → runApp → SplashScreen
```

**Splash** (`lib/screens/onboarding/splash_screen.dart`):

1. Shows brand briefly (~1.6s).
2. Calls `AuthRestore.routeForRestoredSession()`:
   - If Supabase already has a valid session → go to the right home (`patient-home`, `caregiver-dashboard`, or `doctor-dashboard`), and for patients refresh dose notification schedules.
   - If no session → **Language select** → **Role select** → sign-in / registration flow.

**Lifecycle:** `MedAlarmLifecycleHost` keeps dose alarm scheduling in sync when the app resumes.

---

## Onboarding and sign-in

```text
Language select → Role select (Patient / Caregiver / Doctor)
  → Phone sign-in screen (OtpLinkScreen)
  → Profile registration (name, etc.) if profile incomplete
  → Role-specific next step:
       Patient     → Patient home
       Caregiver   → Registration → Link patient OR dashboard if already linked
       Doctor      → Registration → Link patient OR dashboard if already linked
```

### Authentication (not SMS OTP)

- User enters **phone number**.
- App uses **Supabase email/password auth** with a **synthetic email** per phone (e.g. `+92300…@khayal.app`) and a shared `PHONE_AUTH_PASSWORD` from `.env`.
- **SMS OTP is not implemented** in the current release (planned/deferred).
- Session JWT is stored by Supabase Auth; `AppSession` holds role, user id, and selected patient id (for caregiver/doctor).

**Dev bypass:** `DEV_OTP_BYPASS` in `.env` can sign in fixed test users without phone auth.

---

## Roles and home screens

| Role | Main home | What they do |
|------|-----------|----------------|
| **Patient** | `PatientHomeScreen` | Today’s medicines, dose status, menu (☰) for meds/map/chat, reminders, settings |
| **Caregiver** | `CaregiverDashboardScreen` | Linked patient’s meds, adherence summary, add/edit meds, reminders |
| **Doctor** | `DoctorDashboardScreen` | Patient list, missed doses count, chat, dose history |

All homes read/write data through `Backend.repo` (`BackendRepository`) unless noted (chat uses `Backend.chat`).

---

## Linking patient ↔ caregiver / doctor

This is **not** login OTP. It is a **short-lived link code** stored in Postgres.

```text
Patient: home → key icon → createPatientLinkCode()
  → row in otp_artifacts (code, expiry)
  → patient shares 6-digit code + phone with family/doctor

Caregiver/Doctor: enter phone + code
  → verify in Supabase → insert caregiver_patient_links / doctor_patient_links (active)
```

RLS ensures only authorized users can create or consume codes. SQL: `supabase/sql/linking_rls.sql`.

---

## Medicines and dose tracking

### Data model

| Table | Role |
|--------|------|
| `medications` | Medicine names (EN/UR), dose, type, optional photo path |
| `medication_schedules` | One or more `local_time` values per day per medicine |
| `dose_logs` | Per slot: `scheduled_for`, status (`taken`, `missed`, …) |

### Frontend flow

```text
Load meds: Backend.repo.getMedicationsForPatient(patientId)
Load today taken slots: getTodayTakenDoseSlotKeys()
Compute status on device: MedicationDoseStatusLogic (PKT, missed after 5 min past time)
If missed → DoseMissedSync writes missed row to dose_logs (for doctor/caregiver views)

Patient taps dose → confirmDose() → upsert dose_logs (taken)
```

**Add / edit / delete** medicines: `medication_management_screen`, `edit_medication_screen` → `createMedication` / `updateMedication` / `deleteMedication` → then **reschedule** OS notifications via `MedicationNotificationService.syncSchedules`.

Patients can manage their own meds; caregivers manage linked patient’s meds. RLS: `supabase/sql/medications_rls.sql`, `medications_rls_patient_write.sql`.

---

## Dose reminders and alarms

Two complementary paths:

### A) App closed or phone locked — OS notifications

| Step | What happens |
|------|----------------|
| Schedule | `MedicationNotificationService.syncSchedules()` uses `flutter_local_notifications` **zonedSchedule** (daily, Asia/Karachi) |
| Sound | Android notification channel uses **system alarm tone** (native `RingtoneManager` via `MainActivity`) |
| Tap notification | Opens app; can run TTS + in-app ringtone from payload |
| Permissions | Notifications, exact alarms, full-screen intent (Android 14+) |

No Firebase/APNs push server sends dose times — the **phone schedules locally**.

### B) App open — in-app reminder

| Step | What happens |
|------|----------------|
| Timer | `MedicationAlarmScheduler` / `MedicationReminderWatcher` every ~20s checks schedule vs clock |
| Fire | Urdu TTS (“دوا کا وقت ہو گیا ہے”) + English name → **then** looping ringtone |
| UI | Full-screen / overlay (`notification_overlay_screen`) |

User can disable reminders in **Settings** → cancels OS schedules.

---

## Doctor–patient chat and Stripe

### Who can chat?

- **Doctor:** free; must be linked via `doctor_patient_links`.
- **Patient:** must have active row in `patient_chat_subscriptions` (Stripe monthly sub), unless dev bypass.

### Chat data flow

```text
1. getLinkedDoctorForPatient() / getOrCreateThread()
2. listMessages(threadId)        ← HTTP query (history)
3. sendMessage()                 ← HTTP insert into chat_messages
4. subscribeToThread(threadId)   ← Supabase Realtime: listen for INSERT on chat_messages
```

**Realtime:** `ChatRepository.subscribeToThread` opens a `RealtimeChannel` on table `chat_messages` filtered by `thread_id`. New messages appear without refresh. This uses Supabase’s WebSocket layer, not a custom socket server.

Tables: `chat_threads`, `chat_messages`, `patient_chat_subscriptions` — see `supabase/sql/doctor_patient_chat.sql`.

### Stripe payment flow

```text
Patient taps Pay
  → App: Backend.chatBilling.createCheckoutUrl()
       → Supabase Edge Function: create-chat-checkout
       → Stripe API: Checkout Session (subscription)
  → App opens URL in StripeCheckoutWebViewScreen (WebView)
  → User pays; success URL contains session_id
  → App: syncSubscriptionAfterPayment(sessionId)
       → Edge Function: sync-chat-subscription
       → Updates patient_chat_subscriptions in Postgres
  → App reloads chat; thread + messages if subscribed

Background: Stripe webhook → Edge Function stripe-webhook → renew/cancel in DB
```

| Edge Function | File |
|---------------|------|
| `create-chat-checkout` | `supabase/functions/create-chat-checkout/index.ts` |
| `sync-chat-subscription` | `supabase/functions/sync-chat-subscription/index.ts` |
| `stripe-webhook` | `supabase/functions/stripe-webhook/index.ts` |

Stripe secrets live in **Supabase project secrets**, not in the mobile app.

---

## Maps and medicine photos

**Maps**

- Patient sets **home** on map → saved locally (`PatientHomeLocationStore`) and optionally profile in Supabase.
- **Nearby care** uses OpenStreetMap tiles + Overpass for clinics/hospitals (HTTP from app).

**Photos**

- Upload to Supabase Storage bucket `medication-photos`.
- Path stored on `medications.image_storage_path`.
- UI loads **signed URLs** (time-limited). RLS: `supabase/sql/medication_photos_storage.sql`, `medication_photos_patient_upload.sql`.

---

## How the Flutter app talks to Supabase

| Pattern | Used for | Package / API |
|---------|----------|----------------|
| REST (PostgREST) | CRUD on tables | `_client.from('table').select/insert/update/delete` |
| Auth | Sign-in, JWT | `Supabase.instance.client.auth` |
| Storage | Pill photos | `_client.storage.from('medication-photos')` |
| Realtime | Live chat messages | `_client.channel(...).onPostgresChanges(...).subscribe()` |
| Edge Functions | Stripe checkout/sync | `_client.functions.invoke('function-name')` |

**Security:** The app only ships the **anon** key. **Row Level Security (RLS)** on Postgres and Storage policies enforce who can read/write which rows. Never put `SUPABASE_SERVICE_ROLE_KEY` in the mobile app.

**Central access in code:**

```dart
Backend.repo      // BackendRepository — meds, profiles, links, dose logs
Backend.chat      // ChatRepository — threads, messages, realtime
Backend.chatBilling // ChatBillingService — Stripe edge functions
```

Defined in `lib/core/backend/backend.dart`.

---

## Backend layout (Supabase)

```text
supabase/
  sql/                    # RLS, chat schema, medication policies (run in SQL Editor)
  functions/
    create-chat-checkout/ # Stripe session URL
    sync-chat-subscription/
    stripe-webhook/
```

**Main Postgres tables (conceptual groups):**

- **Users:** `profiles` (extends `auth.users`)
- **Links:** `caregiver_patient_links`, `doctor_patient_links`, `otp_artifacts`
- **Meds:** `medications`, `medication_schedules`, `dose_logs`
- **Chat:** `chat_threads`, `chat_messages`, `patient_chat_subscriptions`
- **Optional:** `alert_events`, `push_tokens` (for future push)

Deploy Edge Functions with Supabase CLI or Dashboard; set secrets: `STRIPE_SECRET_KEY`, `STRIPE_CHAT_PRICE_ID`, `STRIPE_WEBHOOK_SECRET`, etc.

---

## Frontend layout (`lib/`)

```text
lib/
  main.dart                 # Entry, Supabase init, notification init
  core/
    app_env.dart            # .env values
    backend/                # BackendRepository, session
    chat/                   # ChatRepository, models
    billing/                # ChatBillingService (Stripe)
    reminders/              # Notifications, alarms, TTS, voice
    medication/             # Dose status, missed sync, delete helper
    maps/                   # Home location, OSM helpers
    navigation/             # AppRoutes
    ui/                     # Patient design tokens + shared widgets
  screens/
    onboarding/             # Splash, language, role, phone sign-in
    patient/                # Home, meds, chat, maps, history
    caregiver/              # Dashboard, med management, link patient
    doctor/                 # Dashboard, patients, history, chat
    settings/               # Reminders, language, logout
  widgets/                  # Drawer, lifecycle host
```

---

## Environment and run

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- A Supabase project (URL + anon key)
- For chat payments: Stripe + deployed Edge Functions

### First-time setup

```bash
cp .env.example .env
# Edit .env — set SUPABASE_URL, SUPABASE_ANON_KEY, PHONE_AUTH_PASSWORD, etc.
flutter pub get
flutter run
```

### Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Public anon key (RLS-protected) |
| `PHONE_AUTH_PASSWORD` | Yes (phone auth) | Shared password for synthetic auth emails |
| `CHAT_STRIPE_PAYMENT_LINK` | Optional | Fallback if Edge Function missing |
| `DEV_OTP_BYPASS` | Optional | QA sign-in without phone |
| `DEV_CHAT_SUBSCRIPTION_ACTIVE` | Optional | Skip Stripe for chat in dev |

**Never** commit `.env` or embed `SUPABASE_SERVICE_ROLE_KEY` in the app.

Access in code: `lib/core/app_env.dart`.

### SQL scripts (run once per Supabase project)

Run in order as needed:

1. Base schema — `.md files/DATABASE.md`
2. `supabase/sql/medications_rls.sql`
3. `supabase/sql/medications_rls_patient_write.sql`
4. `supabase/sql/medication_photos_storage.sql`
5. `supabase/sql/medication_photos_patient_upload.sql`
6. `supabase/sql/linking_rls.sql`
7. `supabase/sql/doctor_patient_chat.sql`
8. `supabase/sql/chat_messages_images.sql` (create private Storage bucket `chat-images` first — required for chat photos)

### CI

GitHub Actions copies `.env.example` → `.env` for `flutter analyze` / tests. Use repository secrets only when integration tests need real credentials.

### If a secret was committed

1. Rotate the key in Supabase (or Stripe) immediately.  
2. Remove from git history if it reached a public branch.  
3. Never reuse the old key.

---

## End-to-end example: patient morning dose

```text
1. User already signed in → Splash restores → Patient home
2. Home loads medications + schedules from Supabase (HTTPS)
3. OS notifications already scheduled for 8:00 AM (local)
4. At 8:00 (app closed): system notification fires (alarm sound)
5. User opens app → TTS + ringtone → dose confirmation screen
6. User confirms → confirmDose() upserts dose_logs (taken)
7. Home summary updates (taken count); caregiver/doctor see adherence on next load
```

---

## Further reading

- [Flutter documentation](https://docs.flutter.dev/)
- [Supabase Flutter docs](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- Project SRS / change log: compare implemented features vs planned (e.g. SMS OTP login deferred)

---

*Khayal Platform — medication reminders and connected care.*
