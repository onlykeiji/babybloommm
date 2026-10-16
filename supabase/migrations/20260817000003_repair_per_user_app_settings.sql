-- Repairs an existing project where app_settings was created as one shared
-- demo row. Run this in Supabase SQL Editor before testing pregnancy setup.

create extension if not exists pgcrypto;

alter table public.app_settings
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
alter table public.app_settings alter column id set default gen_random_uuid();

-- The old shared/demo row has no owner and cannot be safely assigned to a
-- real account. The app recreates an account's settings row automatically.
delete from public.app_settings where user_id is null;
alter table public.app_settings alter column user_id set not null;
create unique index if not exists app_settings_user_id_key
  on public.app_settings (user_id);

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
