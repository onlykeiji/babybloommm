-- Medications, appointments, and vaccine logs had no user_id column and used
-- `using (true)` RLS policies, so every signed-in account read and wrote the
-- same shared rows. This scopes each table to its owning user, matching
-- pregnancy_weight_entries and daily_logs.

alter table public.medication_reminders
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
-- Existing rows had no owner, so remove them rather than assigning them to an
-- arbitrary account.
delete from public.medication_reminders where user_id is null;
alter table public.medication_reminders alter column user_id set not null;

alter table public.medication_reminders enable row level security;
drop policy if exists "Allow anon read" on public.medication_reminders;
drop policy if exists "Allow anon insert" on public.medication_reminders;
drop policy if exists "Allow anon update" on public.medication_reminders;
drop policy if exists "Allow anon delete" on public.medication_reminders;
create policy "Users can read own medications" on public.medication_reminders
  for select using (auth.uid() = user_id);
create policy "Users can insert own medications" on public.medication_reminders
  for insert with check (auth.uid() = user_id);
create policy "Users can update own medications" on public.medication_reminders
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own medications" on public.medication_reminders
  for delete using (auth.uid() = user_id);

alter table public.health_appointments
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
delete from public.health_appointments where user_id is null;
alter table public.health_appointments alter column user_id set not null;

alter table public.health_appointments enable row level security;
drop policy if exists "Allow anon read" on public.health_appointments;
drop policy if exists "Allow anon insert" on public.health_appointments;
drop policy if exists "Allow anon update" on public.health_appointments;
drop policy if exists "Allow anon delete" on public.health_appointments;
create policy "Users can read own appointments" on public.health_appointments
  for select using (auth.uid() = user_id);
create policy "Users can insert own appointments" on public.health_appointments
  for insert with check (auth.uid() = user_id);
create policy "Users can update own appointments" on public.health_appointments
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own appointments" on public.health_appointments
  for delete using (auth.uid() = user_id);

alter table public.vaccine_log_entries
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
delete from public.vaccine_log_entries where user_id is null;
alter table public.vaccine_log_entries alter column user_id set not null;

alter table public.vaccine_log_entries enable row level security;
drop policy if exists "Allow anon read" on public.vaccine_log_entries;
drop policy if exists "Allow anon insert" on public.vaccine_log_entries;
drop policy if exists "Allow anon update" on public.vaccine_log_entries;
drop policy if exists "Allow anon delete" on public.vaccine_log_entries;
create policy "Users can read own vaccine logs" on public.vaccine_log_entries
  for select using (auth.uid() = user_id);
create policy "Users can insert own vaccine logs" on public.vaccine_log_entries
  for insert with check (auth.uid() = user_id);
create policy "Users can update own vaccine logs" on public.vaccine_log_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own vaccine logs" on public.vaccine_log_entries
  for delete using (auth.uid() = user_id);
