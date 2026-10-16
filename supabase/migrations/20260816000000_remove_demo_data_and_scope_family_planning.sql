-- Run this once in the Supabase SQL editor for an existing BabyBloom project.
-- It removes the known demonstration rows, then makes Family Planning data
-- private to the authenticated account. Do not run it if the database already
-- contains real user records you intend to keep.

delete from public.growth_entries;
delete from public.milestones;
delete from public.baby_profiles where name = 'Baby Mia';
delete from public.medication_reminders
  where name in ('Prenatal Vitamin', 'Folic Acid');
delete from public.health_appointments
  where title = '20-week anatomy scan';
delete from public.community_posts
  where author_name in ('Amara K.', 'Priya S.', 'Jordan M.', 'Devon R.', 'Naomi T.', 'Camille B.');

alter table public.app_settings
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
-- The original demo table used one fixed UUID for every settings row. Each
-- user now needs a generated row ID so their settings can be inserted.
alter table public.app_settings alter column id set default gen_random_uuid();
-- The former single shared row was demonstration configuration. Removing it
-- lets the app create defaults for each user when they first open settings.
delete from public.app_settings where user_id is null;
alter table public.app_settings alter column user_id set not null;
create unique index if not exists app_settings_user_id_key
  on public.app_settings (user_id);

alter table public.daily_logs
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
alter table public.daily_logs alter column user_id set default auth.uid();
-- Existing logs had no owner, so remove them rather than assigning them to an
-- arbitrary account.
delete from public.daily_logs where user_id is null;
alter table public.daily_logs drop constraint if exists daily_logs_log_date_key;
create unique index if not exists daily_logs_user_id_log_date_key
  on public.daily_logs (user_id, log_date);

alter table public.app_settings enable row level security;
drop policy if exists "Allow anon read" on public.app_settings;
drop policy if exists "Allow anon update" on public.app_settings;
drop policy if exists "Users can read own settings" on public.app_settings;
drop policy if exists "Users can insert own settings" on public.app_settings;
drop policy if exists "Users can update own settings" on public.app_settings;
create policy "Users can read own settings" on public.app_settings
  for select using (auth.uid() = user_id);
create policy "Users can insert own settings" on public.app_settings
  for insert with check (auth.uid() = user_id);
create policy "Users can update own settings" on public.app_settings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.daily_logs enable row level security;
drop policy if exists "Allow anon read" on public.daily_logs;
drop policy if exists "Allow anon insert" on public.daily_logs;
drop policy if exists "Allow anon update" on public.daily_logs;
drop policy if exists "Users can read own daily logs" on public.daily_logs;
drop policy if exists "Users can insert own daily logs" on public.daily_logs;
drop policy if exists "Users can update own daily logs" on public.daily_logs;
create policy "Users can read own daily logs" on public.daily_logs
  for select using (auth.uid() = user_id);
create policy "Users can insert own daily logs" on public.daily_logs
  for insert with check (auth.uid() = user_id);
create policy "Users can update own daily logs" on public.daily_logs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
