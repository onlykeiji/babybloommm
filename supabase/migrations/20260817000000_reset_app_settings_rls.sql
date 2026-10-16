-- Run this once in the Supabase SQL editor. It removes every existing
-- policy on app_settings (whatever they currently are — including any
-- stale/duplicate ones left over from before the per-account migration)
-- and recreates exactly the three intended policies, so there's no chance
-- of a mismatched leftover policy silently filtering out a user's own row.

do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'app_settings'
  loop
    execute format('drop policy %I on public.app_settings', pol.policyname);
  end loop;
end $$;

alter table public.app_settings enable row level security;

create policy "Users can read own settings" on public.app_settings
  for select using (auth.uid() = user_id);
create policy "Users can insert own settings" on public.app_settings
  for insert with check (auth.uid() = user_id);
create policy "Users can update own settings" on public.app_settings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create unique index if not exists app_settings_user_id_key
  on public.app_settings (user_id);

-- daily_logs went through the same migration pattern and could have the
-- same stale-policy problem waiting to surface later (period logging on
-- the family-planning side) — reset it the same way while we're in here.
do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'daily_logs'
  loop
    execute format('drop policy %I on public.daily_logs', pol.policyname);
  end loop;
end $$;

alter table public.daily_logs enable row level security;

create policy "Users can read own daily logs" on public.daily_logs
  for select using (auth.uid() = user_id);
create policy "Users can insert own daily logs" on public.daily_logs
  for insert with check (auth.uid() = user_id);
create policy "Users can update own daily logs" on public.daily_logs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
