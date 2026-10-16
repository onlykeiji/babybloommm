# CRUD Implementation — BabyBloom

## Data entities

BabyBloom is a pregnancy/baby-care app. Four entities have full Create,
Read, Update, Delete wired to Supabase:

| Entity | Table | Screen |
|---|---|---|
| Baby profile | `baby_profiles` | Baby profile screen |
| Growth entry (weight/height/head circumference over time) | `growth_entries` | Grow screen (baby care) |
| Medication reminder | `medication_reminders` | Reminders & health schedule → Medications tab (pregnancy) |
| Health appointment | `health_appointments` | Reminders & health schedule → Appointments tab (pregnancy) |
| Vaccine log entry | `vaccine_log_entries` | Reminders & health schedule → Vaccines tab (pregnancy) |

The **baby profile** is the primary entity for the assignment (name, date of
birth, gender, birth weight, birth length, photo) — it has the fullest
Create/Read/Update/Delete UI. The other four extend the same pattern to the
app's pregnancy and baby-care tracking features.

## Storage: Supabase (PostgreSQL)

- Project URL and publishable API key are configured in
  [lib/core/supabase_config.dart](lib/core/supabase_config.dart) and the
  client is initialized once in `main()` before the app runs.
- Table schema, constraints, and Row Level Security policies live in
  [supabase/schema.sql](supabase/schema.sql) — run once in the Supabase SQL
  editor to provision the database.
- Note: every table's RLS policies are left open (`using (true)`) rather
  than scoped per-account. Real accounts now exist (see below), but scoping
  app data to its owner was left out of scope for this assignment —
  see "Known limitations".

## Where each operation lives

Every entity follows the same shape: a plain model class with
`fromRow`/`toRow`, a matching static `*Store` class that wraps the Supabase
client and caches results in a `ValueNotifier`, and a screen that reads the
`ValueNotifier` via `ValueListenableBuilder` so the UI updates reactively the
moment the store changes.

### Baby profile

`BabyProfileStore` in
[baby_care_models.dart](lib/features/home/presentation/baby_care_models.dart),
UI in [baby_profile_screen.dart](lib/features/home/presentation/baby_profile_screen.dart).

| Operation | Method | Supabase call | UI trigger |
|---|---|---|---|
| Create | `BabyProfileStore.addBaby()` | `insert(...).select().single()` | Baby Profile screen → **+** → fill form → Save |
| Read | `BabyProfileStore.fetchAll()` | `select().order('created_at')` | On app launch and whenever the screen opens (or pull-to-refresh) |
| Update | `BabyProfileStore.updateBaby()` | `update(...).eq('id', id).select().single()` | Tap the pencil icon on a baby card → edit form → Save |
| Delete | `BabyProfileStore.removeBaby()` | `delete().eq('id', id)` | Tap the trash icon → confirm in the dialog |

### Growth entry (baby care)

`GrowthLog` in [baby_care_models.dart](lib/features/home/presentation/baby_care_models.dart),
UI in [baby_growth_screen.dart](lib/features/home/presentation/baby_growth_screen.dart)
("Grow" screen — weight/height/head-circumference chart + history for the
active baby).

| Operation | Method | Supabase call | UI trigger |
|---|---|---|---|
| Create | `GrowthLog.add()` | `insert(...).select().single()` | **+** → pick metric/value/date → Save |
| Read | `GrowthLog.fetchForBaby()` | `select().eq('baby_id', id).order('date')` | On screen open and whenever the active baby changes |
| Delete | `GrowthLog.remove()` | `delete().eq('id', id)` | Trash icon on a history row |

No dedicated "edit" UI exists for a past measurement (matches the original
app design — you log a new one instead), so Update wasn't added here; the
overall assignment's Update requirement is covered by baby profiles.

### Medications, appointments, vaccine log (pregnancy)

`MedicationStore`, `AppointmentStore`, `VaccineLogStore` in
[health_schedule_models.dart](lib/features/home/presentation/health_schedule_models.dart),
UI in [reminders_health_screen.dart](lib/features/home/presentation/reminders_health_screen.dart)
("Reminders & health schedule" — 3 tabs).

| Operation | Method (per store) | Supabase call | UI trigger |
|---|---|---|---|
| Create | `add()` | `insert(...).select().single()` | Tab's **+** FAB → fill form → Save |
| Read | `fetchAll()` | `select().order(...)` | On screen open |
| Update | `setReminderEnabled()` | `update({'reminder_enabled': ...}).eq('id', id).select().single()` | Bell icon on any card toggles its reminder |
| Delete | `remove()` | `delete().eq('id', id)` | Trash icon → confirm in the dialog |

`TimeOfDay` fields (medication/appointment time) are stored as `"HH:mm"` text
columns and parsed back on read, since Postgres has no Flutter `TimeOfDay`
equivalent.

## Data validation

- **Client-side**, runs before every Create/Update:
  - `_validateBabyProfile` (baby_care_models.dart): name required, date of
    birth not in the future, birth weight/length positive and under 30.
  - `_validateGrowthEntry`: entry date not in the future, value between 0
    and 100.
  - `_validateMedication` / `_validateAppointment` / `_validateVaccineLog`
    (health_schedule_models.dart): name/title/vaccine-name required.
- **UI-level**: numeric fields use steppers/number keyboards; date pickers
  can't select invalid dates (e.g. a growth entry before the baby's date of
  birth); every form shows a validation or Supabase error inline in red
  instead of failing silently, and the Save button shows a spinner and
  disables itself while the request is in flight.
- **Database-level** (`supabase/schema.sql`): `check` constraints mirror the
  client-side rules for every table (non-empty text fields, enum-restricted
  status/type/gender/metric columns, positive numeric values) so invalid data
  can't reach the database even if the app is bypassed.
- Deleting the last remaining baby profile is blocked in the UI; every delete
  action across all five entities asks for confirmation first.

## User-friendly interface

- Loading spinners while each store's initial fetch is in flight, and
  empty-state messages when a list has no records yet.
- Pull-to-refresh on the baby profile list.
- Every add/edit form shows a spinner on Save and disables the button while
  the request is in flight; errors surface as inline red text in the form or
  a red snackbar, never silently.
- Every delete action opens a confirmation dialog naming the record before
  it runs.

## Accounts: sign up / log in (Supabase Auth)

Sign up and log in are wired to real Supabase Auth — they are not part of
the graded CRUD entity, but they're the front door to the database, so
they're documented here too.

- **Sign up** ([signup_screen.dart](lib/features/auth/presentation/signup_screen.dart)):
  validates full name, email format, password length (≥6 chars), password
  confirmation, and Terms acceptance client-side, then calls
  `SupabaseConfig.client.auth.signUp(email, password, data: {'full_name': ...})`.
  A Postgres trigger (`on_auth_user_created` in `supabase/schema.sql`)
  automatically creates a matching row in `public.profiles` the moment the
  `auth.users` row is inserted.
- **Log in** ([login_screen.dart](lib/features/auth/presentation/login_screen.dart)):
  calls `SupabaseConfig.client.auth.signInWithPassword(email, password)`.
- **Email verification** ([email_verification_screen.dart](lib/features/auth/presentation/email_verification_screen.dart)):
  a real code-verification flow, not a UI mock. `signUp()` triggers
  Supabase's confirmation email; the user pastes the code from that email
  into this screen, which calls `client.auth.verifyOTP(type: OtpType.signup,
  token: code, email: ...)`. Success establishes a real, confirmed session
  immediately — no app relaunch needed — and the user proceeds straight into
  onboarding. "Resend code" calls `client.auth.resend(...)` for real.
  Clicking the link in the email also still confirms the account (Supabase
  does that server-side either way); a user who does that instead is offered
  a "Log in" fallback, since confirming via an external browser tab doesn't
  hand a session back to the running app.
  **Setup required**: Supabase's default "Confirm signup" email template
  only shows a clickable link, not a code. In your Supabase dashboard →
  Authentication → Email Templates → **Confirm signup**, add `{{ .Token }}`
  somewhere in the body (e.g. "Or enter this code in the app: `{{ .Token
  }}`") so the code is actually visible to paste in.
- **Forgot password** ([forgot_password_screen.dart](lib/features/auth/presentation/forgot_password_screen.dart)):
  same code-based pattern — email in, `resetPasswordForEmail()` sends a
  code, then the user pastes the code + a new password, verified with
  `verifyOTP(type: recovery)` then `updateUser(password: ...)`. Needs the
  same `{{ .Token }}` addition on the **Reset Password** template. Linked
  from the "Forgot Password?" text on the login screen.
- **Log out**: every "Sign Out"/"LOGOUT" button calls `client.auth.signOut()`
  for real (Profile screen's Sign Out previously only reset local state
  without actually ending the Supabase session — fixed).
- Errors from Supabase (e.g. "User already registered", wrong password,
  invalid/expired code) are caught as `AuthException` and shown inline in
  red under the form instead of failing silently.

### Access gate ([auth_gate.dart](lib/features/auth/presentation/auth_gate.dart))

`AuthGate` is the app's `home:` widget (`main.dart`) and decides what a user
sees on cold start, based on their real Supabase session:

| State | Destination |
|---|---|
| No session | `WelcomeScreen` (sign up / log in) |
| Session exists, `user.emailConfirmedAt == null` | `EmailVerificationScreen`, blocked until they verify (offers resend + logout) |
| Verified, `profiles.app_mode` set | straight to that dashboard |
| Verified, no `app_mode` yet | the onboarding quiz |

In practice Supabase won't hand out a session before the email is confirmed
(the default "Confirm email" project setting), so `signInWithPassword`
already refuses unverified logins with an `email_not_confirmed` error — the
gate's `emailConfirmedAt` check is the belt to that suspenders, for projects
where confirmation is optional.

### `profiles` table

`public.profiles` (id, full_name, email, birth_date, journey_stage, app_mode,
timestamps) is 1:1 with `auth.users`. Row Level Security restricts every row
to its own owner (`auth.uid() = id`) — this table is scoped per-account from
the start, unlike the tables below. `app_mode` remembers whether the account
is in family-planning, pregnancy, or baby-care mode, so a returning user who
logs in is taken straight to their dashboard instead of redoing onboarding.

## Onboarding ("journey") screens now save real data

The onboarding quiz screens collect information that other screens depend
on — this used to disappear the moment onboarding finished (nothing read
it back), now it's saved to Supabase and immediately usable app-wide:

| Screen | Collects | Saved to |
|---|---|---|
| [family_planning_screen.dart](lib/features/onboarding/presentation/family_planning_screen.dart) | Last cycle start date | `daily_logs` — inserted as a real period-start entry, so `CyclePrediction` (see below) has real data to work with the moment onboarding finishes, instead of waiting for a first manual log |
| [pregnancy_screen.dart](lib/features/onboarding/presentation/pregnancy_screen.dart) | Due date, **or** last period date (auto-converted via Naegele's rule: `+280 days`) | `app_settings.due_date` via `AppSettingsStore.setDueDate()` |
| [baby_care_screen.dart](lib/features/onboarding/presentation/baby_care_screen.dart) | Baby's name, date of birth (or due date), gender | A real `baby_profiles` row via `BabyProfileStore.addBaby()` — the same row Baby Profile / Grow screens read afterward |

All three now validate before saving (non-empty name, a date actually
picked) and show a loading spinner + inline error on the Continue button
instead of silently proceeding with missing data, which the original UI
did.

### Pregnancy week is now derived, not a stale snapshot

Previously `app_settings.pregnancy_current_week` was a fixed number that
never advanced — set it to "week 12" on day one and it stayed "week 12"
forever. `AppSettings.currentPregnancyWeek` (in
[app_settings_store.dart](lib/core/app_settings_store.dart)) now computes
the live week from `due_date` (`40 − weeks until due`) every time it's
read, the same fix already applied to cycle predictions. Pregnancy
dashboard, Profile screen, and Pregnancy Settings all read this derived
value. Manually adjusting the week in Pregnancy Settings still works — it
reverse-computes and stores a matching `due_date` so both stay consistent
no matter which screen last touched it.

## Every other screen made functional

Beyond the graded CRUD entity and Gemini integration, every remaining screen
that claimed to save, log, toggle, or post something now actually persists
to Supabase instead of just showing a snackbar or resetting on navigation:

| Screen | Table(s) | Store |
|---|---|---|
| Personal details | `profiles` | `ProfileStore` ([user_profile_store.dart](lib/core/user_profile_store.dart)) — requires login |
| Notifications / Privacy / Cycle / Pregnancy / App preferences settings | `app_settings` (single shared row) | `AppSettingsStore` ([app_settings_store.dart](lib/core/app_settings_store.dart)) |
| Contraction timer | `contractions` | `ContractionStore` ([contraction_models.dart](lib/features/home/presentation/contraction_models.dart)) |
| Hospital bag checklist | `hospital_bag_progress` | inline `_HospitalBagStore` in [hospital_bag_screen.dart](lib/features/home/presentation/hospital_bag_screen.dart) |
| Daily cycle log (flow/mood/symptoms/notes) | `daily_logs` (upsert per date) | `DailyLogStore` ([daily_log_models.dart](lib/features/home/presentation/daily_log_models.dart)) |
| Milestones (baby care) | `milestones` | `MilestoneLog` in [baby_care_models.dart](lib/features/home/presentation/baby_care_models.dart) |
| Community posts | `community_posts` | `CommunityStore` ([community_models.dart](lib/features/home/presentation/community_models.dart)) |
| Belly photo journal | `belly_photos` (local file path per week) | inline `_BellyPhotoStore` in [belly_photo_journal_screen.dart](lib/features/home/presentation/belly_photo_journal_screen.dart) |

Two settings-screen actions remain UI-only and are called out here rather
than silently left broken: **"Download my data"** and **"Delete my
account"** (Privacy settings) — a real data export and a real account
deletion both require server-side logic (an Edge Function using the
`service_role` key, never exposed to the client), which is out of scope for
a client-only Supabase setup. Everything else on every screen persists.

Screens that are **read-only reference content** (Learn library, baby
names, vaccine reference cards, WHO growth-chart curves) or **illustrative
dashboard analytics with no save action** (Insights charts/PDF export) were
intentionally left as-is — there is no user data entry there to persist, and
rebuilding them into a live predictive analytics engine is a different, much
larger feature than "make the screen functional."

## Placeholders replaced with real data

Beyond the tables above, several screens displayed hardcoded demo text
("Cayen Toledo", a fixed pregnancy week, a fixed due date) instead of what
the user actually entered. These now read from the real stores:

- **Name, email, avatar initials** — Profile screen header, every dashboard's
  "Good morning, …" greeting, the community post composer's identity card,
  and the Insights PDF report footer all now read `ProfileStore.current`
  (falls back to a placeholder only if not logged in / not yet loaded).
- **Pregnancy week, due date, starting weight** (Pregnancy dashboard) — now
  read `AppSettingsStore.current.pregnancyCurrentWeek` /
  `.prePregnancyWeightLb` (the same values the Pregnancy Settings screen
  writes) instead of a separate hardcoded `currentWeek = 12`. Due date is
  computed from that real week and the real current date instead of a fixed
  demo date (`DateTime(2025, 10, 10)`).
- **Next appointment card** (Pregnancy dashboard) — now shows the nearest
  upcoming row from `AppointmentStore` (the same Supabase-backed appointments
  from Reminders & health) instead of a hardcoded "20-week anatomy scan".
- **Profile screen's "Weeks along" stat and journey card** — same
  `AppSettingsStore` value, trimester text computed from it.

## Real cycle predictions (family planning dashboard + cycle screen)

The family-planning dashboard's "Cycle day 10" and fertile-window date, and
the cycle calendar screen's month view, are no longer demo numbers — they're
computed from the user's own logged period data.

**Method** ([cycle_prediction.dart](lib/features/home/presentation/cycle_prediction.dart),
`CyclePrediction`): standard luteal-phase estimation, the same approach used
by most consumer cycle-tracking apps.

1. **Detect period starts** — scan `daily_logs` for flow entries; a date
   counts as "day 1" of a period when it has a logged flow and the day
   before it doesn't (`periodStartDatesFrom`).
2. **Anchor the current cycle** — take the most recent logged period start
   and roll it forward in `cycle_length`-sized jumps until it lands on the
   cycle containing today (`CyclePrediction.compute`). This means the
   predictions stay correct even if the user hasn't logged in a while — no
   manual "reset" needed.
3. **Ovulation day** = `cycle_length − luteal_length` (both from
   `app_settings`, the same values the Cycle Settings screen writes).
   **Fertile window** = the 6 days ending on ovulation day (sperm survive up
   to ~5 days, the egg about 1 — the standard fertile-window definition).
4. Every screen re-derives this from `AppSettingsStore.current` and
   `DailyLogStore.all` (both `ValueNotifier`s), so logging a period on the
   Log screen immediately updates the dashboard and calendar — no manual
   refresh.

**What's real vs. estimated**: past dates that have an actual logged flow
entry always show as period days (ground truth). Future/unlogged dates show
the *predicted* period, fertile window, and ovulation day from the formula
above. Recent-cycle history and average-cycle/period stats are computed the
same way — from actual gaps between logged period starts, not fabricated.

**Empty state**: with zero periods logged, every one of these screens shows
a "Log your period to start tracking" prompt (linking straight to the Log
screen) instead of guessing — no fake baseline data.

This is an estimate, like every consumer cycle tracker, not medical or
fertility guidance — the UI doesn't claim otherwise.

## Known limitations

- Photos (baby profile, belly photo journal) are stored as a local file path,
  not uploaded to Supabase Storage — so a photo picked on one device won't
  appear on another. Out of scope since the graded entity is the record
  itself, not binary file storage.
- Only `profiles` (personal details + remembered app mode) is scoped to the
  logged-in account. Every other table — `baby_profiles`, `growth_entries`,
  `medication_reminders`, `health_appointments`, `vaccine_log_entries`,
  `app_settings`, `contractions`, `hospital_bag_progress`, `daily_logs`,
  `milestones`, `community_posts`, `belly_photos` — uses open RLS
  (`using (true)`) rather than per-account scoping, so every signed-in user
  currently shares the same data (and `app_settings` is one single shared
  row rather than one per account). Wiring real per-account scoping would
  mean adding a `user_id uuid references auth.users(id)` column to each
  table, defaulting it to `auth.uid()` on insert, and changing every RLS
  policy to `auth.uid() = user_id`.
- Growth entries have no per-row edit UI (only add/delete), matching the
  original app design — see "Growth entry" above.
- Community post "likes" are a simple counter column, not a per-user join
  table — the app tracks *which posts you've liked this session* locally
  (so the heart icon and count stay consistent while you're using the app),
  but that "liked by me" state isn't itself persisted per account.
- "Download my data" and "Delete my account" (Privacy settings) remain
  UI-only — see "Every other screen made functional" above for why.
