-- BabyBloom: baby_profiles table
-- Run this once in the Supabase SQL editor (Project > SQL Editor > New query).

create extension if not exists pgcrypto;

create table if not exists public.baby_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) > 0),
  date_of_birth date not null,
  gender text not null check (gender in ('boy', 'girl', 'other')),
  birth_weight_lb numeric(5, 2) check (birth_weight_lb is null or birth_weight_lb > 0),
  birth_length_in numeric(5, 2) check (birth_length_in is null or birth_length_in > 0),
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at current on every edit.
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists baby_profiles_set_updated_at on public.baby_profiles;
create trigger baby_profiles_set_updated_at
  before update on public.baby_profiles
  for each row execute function public.set_updated_at();

-- Row Level Security.
-- This project has no real authentication wired up yet (login/signup screens
-- are UI-only), so policies are left open to the anon key for this class
-- assignment. Before shipping this to real users, scope every policy to
-- `auth.uid()` and add a `user_id` column instead of using `true`.
alter table public.baby_profiles enable row level security;

drop policy if exists "Allow anon read" on public.baby_profiles;
create policy "Allow anon read" on public.baby_profiles
  for select using (true);

drop policy if exists "Allow anon insert" on public.baby_profiles;
create policy "Allow anon insert" on public.baby_profiles
  for insert with check (true);

drop policy if exists "Allow anon update" on public.baby_profiles;
create policy "Allow anon update" on public.baby_profiles
  for update using (true) with check (true);

drop policy if exists "Allow anon delete" on public.baby_profiles;
create policy "Allow anon delete" on public.baby_profiles
  for delete using (true);

-- ============================================================
-- Sign up / log in: user accounts
-- ============================================================
-- Supabase Auth (auth.users) already stores email + hashed password and
-- handles sign up / log in / sessions for us. This `profiles` table just
-- holds the extra app-facing field (full name) for each account, linked
-- 1:1 to auth.users, and is created automatically on sign up.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) > 0),
  email text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create a profile row every time someone signs up. Runs as the
-- function owner (security definer), so it can insert past the RLS
-- policies above even though the new user has no session yet.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.email
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- Baby care: growth entries (weight / height / head circumference)
-- ============================================================

create table if not exists public.growth_entries (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.baby_profiles (id) on delete cascade,
  date date not null,
  metric text not null check (metric in ('weight', 'height', 'headCircumference')),
  value numeric(6, 2) not null check (value > 0),
  created_at timestamptz not null default now()
);

alter table public.growth_entries enable row level security;

drop policy if exists "Allow anon read" on public.growth_entries;
create policy "Allow anon read" on public.growth_entries
  for select using (true);

drop policy if exists "Allow anon insert" on public.growth_entries;
create policy "Allow anon insert" on public.growth_entries
  for insert with check (true);

drop policy if exists "Allow anon delete" on public.growth_entries;
create policy "Allow anon delete" on public.growth_entries
  for delete using (true);

-- ============================================================
-- Pregnancy: medications, appointments, vaccine log
-- ============================================================
-- These are not scoped per-account (same open-RLS approach as
-- baby_profiles above) to keep the demo simple and predictable to test —
-- see CRUD_DOCUMENTATION.md "Known limitations".

create table if not exists public.medication_reminders (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) > 0),
  dosage text not null default '—',
  time text not null, -- "HH:mm", 24-hour
  frequency text not null check (
    frequency in ('onceDaily', 'twiceDaily', 'threeTimesDaily', 'weekly', 'asNeeded')
  ),
  reminder_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.medication_reminders enable row level security;

drop policy if exists "Allow anon read" on public.medication_reminders;
create policy "Allow anon read" on public.medication_reminders for select using (true);
drop policy if exists "Allow anon insert" on public.medication_reminders;
create policy "Allow anon insert" on public.medication_reminders for insert with check (true);
drop policy if exists "Allow anon update" on public.medication_reminders;
create policy "Allow anon update" on public.medication_reminders for update using (true) with check (true);
drop policy if exists "Allow anon delete" on public.medication_reminders;
create policy "Allow anon delete" on public.medication_reminders for delete using (true);

create table if not exists public.health_appointments (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) > 0),
  date date not null,
  time text not null, -- "HH:mm", 24-hour
  type text not null check (type in ('checkup', 'lab', 'ultrasound', 'other')),
  notes text not null default '',
  reminder_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.health_appointments enable row level security;

drop policy if exists "Allow anon read" on public.health_appointments;
create policy "Allow anon read" on public.health_appointments for select using (true);
drop policy if exists "Allow anon insert" on public.health_appointments;
create policy "Allow anon insert" on public.health_appointments for insert with check (true);
drop policy if exists "Allow anon update" on public.health_appointments;
create policy "Allow anon update" on public.health_appointments for update using (true) with check (true);
drop policy if exists "Allow anon delete" on public.health_appointments;
create policy "Allow anon delete" on public.health_appointments for delete using (true);

create table if not exists public.vaccine_log_entries (
  id uuid primary key default gen_random_uuid(),
  vaccine_name text not null check (char_length(trim(vaccine_name)) > 0),
  status text not null check (status in ('scheduled', 'completed')),
  date date not null,
  notes text not null default '',
  reminder_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.vaccine_log_entries enable row level security;

drop policy if exists "Allow anon read" on public.vaccine_log_entries;
create policy "Allow anon read" on public.vaccine_log_entries for select using (true);
drop policy if exists "Allow anon insert" on public.vaccine_log_entries;
create policy "Allow anon insert" on public.vaccine_log_entries for insert with check (true);
drop policy if exists "Allow anon update" on public.vaccine_log_entries;
create policy "Allow anon update" on public.vaccine_log_entries for update using (true) with check (true);
drop policy if exists "Allow anon delete" on public.vaccine_log_entries;
create policy "Allow anon delete" on public.vaccine_log_entries for delete using (true);

-- ============================================================
-- Account: extra profile fields + persisted app mode
-- ============================================================
-- Backs the Personal Details screen and remembers which mode (family
-- planning / pregnancy / baby care) the signed-in user is in, so it
-- survives a re-login instead of resetting every session.

alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists journey_stage text;
alter table public.profiles add column if not exists app_mode text
  check (app_mode is null or app_mode in ('familyPlanning', 'pregnancy', 'babyCare'));

-- ============================================================
-- App settings (notifications, privacy, cycle & pregnancy tuning, prefs)
-- ============================================================
-- A single shared settings row (same simplified, non-per-account approach
-- as baby_profiles etc. — see CRUD_DOCUMENTATION.md "Known limitations").

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  -- Notifications
  period_reminders boolean not null default true,
  fertile_window_alerts boolean not null default true,
  daily_checkin boolean not null default true,
  daily_checkin_time text not null default '20:00',
  community_activity boolean not null default true,
  weekly_insights boolean not null default false,
  bloom_ai_checkins boolean not null default false,
  -- Privacy
  post_anonymously boolean not null default false,
  share_research_data boolean not null default true,
  app_lock boolean not null default false,
  -- Cycle & fertility
  cycle_length int not null default 28 check (cycle_length between 21 and 40),
  period_length int not null default 5 check (period_length between 2 and 10),
  luteal_length int not null default 14 check (luteal_length between 10 and 16),
  cycle_tracking text[] not null default array['Cycle & Ovulation', 'Mood & Symptoms'],
  -- Pregnancy
  pregnancy_current_week int not null default 12 check (pregnancy_current_week between 1 and 42),
  due_date date,
  pre_pregnancy_weight_lb numeric(6, 1) not null default 132.0 check (pre_pregnancy_weight_lb between 80 and 300),
  pregnancy_tracking text[] not null default array['Symptoms', 'Kick counts', 'Weight'],
  -- App preferences
  units text not null default 'Metric' check (units in ('Metric', 'Imperial')),
  haptic_feedback boolean not null default true,
  updated_at timestamptz not null default now()
);

-- In case this table already existed before these columns were added.
alter table public.app_settings add column if not exists due_date date;
alter table public.app_settings add column if not exists user_id uuid references auth.users (id) on delete cascade;
create unique index if not exists app_settings_user_id_key on public.app_settings (user_id);

drop trigger if exists app_settings_set_updated_at on public.app_settings;
create trigger app_settings_set_updated_at
  before update on public.app_settings
  for each row execute function public.set_updated_at();

alter table public.app_settings enable row level security;

drop policy if exists "Allow anon read" on public.app_settings;
drop policy if exists "Allow anon update" on public.app_settings;
create policy "Users can read own settings" on public.app_settings for select using (auth.uid() = user_id);
create policy "Users can insert own settings" on public.app_settings for insert with check (auth.uid() = user_id);
create policy "Users can update own settings" on public.app_settings for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- Contraction timer
-- ============================================================

create table if not exists public.contractions (
  id uuid primary key default gen_random_uuid(),
  start_time timestamptz not null,
  duration_seconds int not null check (duration_seconds >= 0),
  since_previous_seconds int check (since_previous_seconds is null or since_previous_seconds >= 0),
  created_at timestamptz not null default now()
);

alter table public.contractions enable row level security;

drop policy if exists "Allow anon read" on public.contractions;
create policy "Allow anon read" on public.contractions for select using (true);
drop policy if exists "Allow anon insert" on public.contractions;
create policy "Allow anon insert" on public.contractions for insert with check (true);
drop policy if exists "Allow anon delete" on public.contractions;
create policy "Allow anon delete" on public.contractions for delete using (true);

-- ============================================================
-- Hospital bag checklist progress
-- ============================================================
-- Items themselves stay hardcoded in the app; this table just remembers
-- which item keys ("category·item") are checked off.

create table if not exists public.hospital_bag_progress (
  item_key text primary key,
  packed boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.hospital_bag_progress enable row level security;

drop policy if exists "Allow anon read" on public.hospital_bag_progress;
create policy "Allow anon read" on public.hospital_bag_progress for select using (true);
drop policy if exists "Allow anon insert" on public.hospital_bag_progress;
create policy "Allow anon insert" on public.hospital_bag_progress for insert with check (true);
drop policy if exists "Allow anon delete" on public.hospital_bag_progress;
create policy "Allow anon delete" on public.hospital_bag_progress for delete using (true);

-- ============================================================
-- Daily cycle log (period flow / mood / symptoms / notes)
-- ============================================================
-- One row per calendar date; saving the same date again updates it
-- (upsert), matching how a daily check-in naturally behaves.

create table if not exists public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  log_date date not null,
  flow text not null default 'None' check (flow in ('None', 'Light', 'Medium', 'Heavy')),
  mood text,
  symptoms text[] not null default array[]::text[],
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, log_date)
);

alter table public.daily_logs add column if not exists user_id uuid references auth.users (id) on delete cascade;
alter table public.daily_logs alter column user_id set default auth.uid();
alter table public.daily_logs drop constraint if exists daily_logs_log_date_key;
create unique index if not exists daily_logs_user_id_log_date_key on public.daily_logs (user_id, log_date);

drop trigger if exists daily_logs_set_updated_at on public.daily_logs;
create trigger daily_logs_set_updated_at
  before update on public.daily_logs
  for each row execute function public.set_updated_at();

alter table public.daily_logs enable row level security;

drop policy if exists "Allow anon read" on public.daily_logs;
drop policy if exists "Allow anon insert" on public.daily_logs;
drop policy if exists "Allow anon update" on public.daily_logs;
create policy "Users can read own daily logs" on public.daily_logs for select using (auth.uid() = user_id);
create policy "Users can insert own daily logs" on public.daily_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own daily logs" on public.daily_logs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- Learning progress (one completed lesson per user and lesson title)
-- ============================================================

create table if not exists public.lesson_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  lesson_title text not null check (char_length(trim(lesson_title)) > 0),
  completed_at timestamptz not null default now(),
  unique (user_id, lesson_title)
);

alter table public.lesson_completions enable row level security;

drop policy if exists "Users can read own lesson completions" on public.lesson_completions;
drop policy if exists "Users can insert own lesson completions" on public.lesson_completions;
drop policy if exists "Users can update own lesson completions" on public.lesson_completions;
create policy "Users can read own lesson completions" on public.lesson_completions
  for select using (auth.uid() = user_id);
create policy "Users can insert own lesson completions" on public.lesson_completions
  for insert with check (auth.uid() = user_id);
create policy "Users can update own lesson completions" on public.lesson_completions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- Baby care: milestones achieved
-- ============================================================

create table if not exists public.milestones (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.baby_profiles (id) on delete cascade,
  title text not null,
  achieved_date date not null,
  created_at timestamptz not null default now(),
  unique (baby_id, title)
);

alter table public.milestones enable row level security;

drop policy if exists "Allow anon read" on public.milestones;
create policy "Allow anon read" on public.milestones for select using (true);
drop policy if exists "Allow anon insert" on public.milestones;
create policy "Allow anon insert" on public.milestones for insert with check (true);
drop policy if exists "Allow anon delete" on public.milestones;
create policy "Allow anon delete" on public.milestones for delete using (true);

-- ============================================================
-- Community posts
-- ============================================================

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_name text not null default 'Anonymous',
  initials text not null default '?',
  topic text not null,
  body text not null check (char_length(trim(body)) > 0),
  is_question boolean not null default false,
  likes int not null default 0 check (likes >= 0),
  comments int not null default 0 check (comments >= 0),
  created_at timestamptz not null default now()
);

alter table public.community_posts enable row level security;

drop policy if exists "Allow anon read" on public.community_posts;
create policy "Allow anon read" on public.community_posts for select using (true);
drop policy if exists "Allow anon insert" on public.community_posts;
create policy "Allow anon insert" on public.community_posts for insert with check (true);
drop policy if exists "Allow anon update" on public.community_posts;
create policy "Allow anon update" on public.community_posts for update using (true) with check (true);
drop policy if exists "Allow anon delete" on public.community_posts;
create policy "Allow anon delete" on public.community_posts for delete using (true);

/* Sample community posts deliberately disabled: a new installation starts empty.
insert into public.community_posts (author_name, initials, topic, body, is_question, likes, comments, created_at)
select * from (values
  ('Amara K.', 'AK', 'TTC', 'Day 3 of the two-week wait and I am losing my mind checking symptoms every hour. Anyone else obsessively googling right now?', false, 24, 9, now() - interval '2 hours'),
  ('Priya S.', 'PS', 'Pregnancy', 'Week 9 and the nausea is relentless. Ginger chews have been a lifesaver. What got you through first trimester sickness?', true, 41, 17, now() - interval '4 hours'),
  ('Jordan M.', 'JM', 'Mental Health', 'Had a really hard day today. Third failed IUI and I just needed to say it out loud somewhere that is not inside my own head. Thank you for reading.', false, 68, 22, now() - interval '6 hours'),
  ('Devon R.', 'DR', 'Baby Care', 'Our little one finally slept through the night for the first time. 6 months of 2am wakeups and I could cry from relief. It does get better.', false, 53, 14, now() - interval '9 hours'),
  ('Naomi T.', 'NT', 'Postpartum', 'Nobody warned me how lonely the fourth trimester could feel. If you are in it too, you are not alone and it is okay to ask for help.', false, 89, 31, now() - interval '1 day'),
  ('Camille B.', 'CB', 'TTC', 'Got our BFP this morning after 14 months of trying. Please do not lose hope, I know how heavy this wait can feel.', false, 132, 46, now() - interval '1 day')
) as seed(author_name, initials, topic, body, is_question, likes, comments, created_at)
where not exists (select 1 from public.community_posts);
*/

-- ============================================================
-- Belly photo journal
-- ============================================================
-- Photos themselves stay as local file paths (same tradeoff as
-- baby_profiles.photo_path) — only which week has a photo, and where to
-- find it on this device, is persisted.

create table if not exists public.belly_photos (
  week int primary key check (week between 1 and 42),
  photo_path text not null,
  updated_at timestamptz not null default now()
);

alter table public.belly_photos enable row level security;

drop policy if exists "Allow anon read" on public.belly_photos;
create policy "Allow anon read" on public.belly_photos for select using (true);
drop policy if exists "Allow anon insert" on public.belly_photos;
create policy "Allow anon insert" on public.belly_photos for insert with check (true);
drop policy if exists "Allow anon update" on public.belly_photos;
create policy "Allow anon update" on public.belly_photos for update using (true) with check (true);
drop policy if exists "Allow anon delete" on public.belly_photos;
create policy "Allow anon delete" on public.belly_photos for delete using (true);

-- Pregnancy weight history (kg input is converted to pounds by the app).
create table if not exists public.pregnancy_weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  recorded_on date not null,
  weight_lb numeric(6, 1) not null check (weight_lb between 60 and 400),
  created_at timestamptz not null default now(),
  unique (user_id, recorded_on)
);

alter table public.pregnancy_weight_entries enable row level security;
drop policy if exists "Users can read own pregnancy weights" on public.pregnancy_weight_entries;
create policy "Users can read own pregnancy weights" on public.pregnancy_weight_entries
  for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own pregnancy weights" on public.pregnancy_weight_entries;
create policy "Users can insert own pregnancy weights" on public.pregnancy_weight_entries
  for insert with check (auth.uid() = user_id);
drop policy if exists "Users can update own pregnancy weights" on public.pregnancy_weight_entries;
create policy "Users can update own pregnancy weights" on public.pregnancy_weight_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
