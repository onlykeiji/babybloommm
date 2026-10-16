# Baby Care database setup

Apply the migrations in `supabase/migrations` in filename order. For an
existing Supabase project matching the exported schema, run only:

`20260829010000_secure_baby_care_crud.sql`

Paste the file into **Supabase Dashboard → SQL Editor → New query**, run it,
then restart the Flutter app and sign in again.

This migration is self-contained and creates `baby_care_logs` when it is
missing. It is also safe to rerun after a previous attempt stopped with a
`relation public.baby_care_logs does not exist` error.

## Data saved by Baby Care

| Feature | Supabase table | App CRUD |
| --- | --- | --- |
| Baby profiles | `baby_profiles` | Create, read, update, delete |
| Weight, height, head circumference | `growth_entries` | Create, read, update, delete |
| Developmental milestones | `milestones` | Create/read via completion, update via upsert, delete via unmark |
| Feeding, diaper, sleep | `baby_care_logs` | Create, read, update, delete |
| Medicines and reminders | `medication_reminders` | Create, read, update, delete |
| Pediatric appointments | `health_appointments` | Create, read, update, delete |
| Vaccine records | `vaccine_log_entries` | Create, read, update, delete |

All Baby Care profile, growth, milestone, and daily-care rows are protected by
row-level security. An authenticated user can access only records belonging to
their own account. Deleting a baby profile cascades to that baby's growth,
milestone, and daily-care records.

## Existing development data

The security migration automatically assigns unowned legacy baby profiles only
when the Supabase project contains exactly one user. In a multi-user project it
does not guess ownership; unowned legacy rows remain unassigned and hidden by
RLS until an administrator assigns the correct `user_id`.
