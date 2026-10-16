-- Baby Care ownership, full CRUD policies, and query indexes.
-- Safe to run directly against an existing BabyBloom database. Missing Baby
-- Care tables are created before ownership and CRUD policies are applied.

create extension if not exists pgcrypto;

create table if not exists public.baby_care_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  baby_id uuid not null
    references public.baby_profiles (id) on delete cascade,
  kind text not null check (kind in ('feeding', 'diaper', 'sleep')),
  occurred_at timestamptz not null default now(),
  duration_minutes integer
    check (duration_minutes is null or duration_minutes >= 0),
  amount numeric(8, 1) check (amount is null or amount >= 0),
  details text not null default '',
  created_at timestamptz not null default now()
);

alter table public.baby_profiles
  add column if not exists user_id uuid references auth.users (id) on delete cascade;
alter table public.baby_profiles alter column user_id set default auth.uid();

-- A development database commonly has one account and older baby rows with no
-- owner. Claim those rows only when ownership is unambiguous; never guess in a
-- multi-user project.
do $$
declare
  only_user uuid;
begin
  if (select count(*) from auth.users) = 1 then
    select id into only_user from auth.users limit 1;
    update public.baby_profiles set user_id = only_user where user_id is null;
  end if;
end $$;

create index if not exists baby_profiles_user_id_idx
  on public.baby_profiles (user_id, created_at);
create index if not exists growth_entries_baby_date_idx
  on public.growth_entries (baby_id, date desc);
create index if not exists milestones_baby_achieved_date_idx
  on public.milestones (baby_id, achieved_date desc);
create unique index if not exists milestones_baby_title_key
  on public.milestones (baby_id, title);
create index if not exists baby_care_logs_baby_occurred_at_idx
  on public.baby_care_logs (baby_id, occurred_at desc);

alter table public.baby_profiles enable row level security;
drop policy if exists "Allow anon read" on public.baby_profiles;
drop policy if exists "Allow anon insert" on public.baby_profiles;
drop policy if exists "Allow anon update" on public.baby_profiles;
drop policy if exists "Allow anon delete" on public.baby_profiles;
drop policy if exists "Users can read own baby profiles" on public.baby_profiles;
drop policy if exists "Users can insert own baby profiles" on public.baby_profiles;
drop policy if exists "Users can update own baby profiles" on public.baby_profiles;
drop policy if exists "Users can delete own baby profiles" on public.baby_profiles;
create policy "Users can read own baby profiles" on public.baby_profiles
  for select using (auth.uid() = user_id);
create policy "Users can insert own baby profiles" on public.baby_profiles
  for insert with check (auth.uid() = user_id);
create policy "Users can update own baby profiles" on public.baby_profiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own baby profiles" on public.baby_profiles
  for delete using (auth.uid() = user_id);

alter table public.growth_entries enable row level security;
drop policy if exists "Allow anon read" on public.growth_entries;
drop policy if exists "Allow anon insert" on public.growth_entries;
drop policy if exists "Allow anon update" on public.growth_entries;
drop policy if exists "Allow anon delete" on public.growth_entries;
drop policy if exists "Users can read own growth entries" on public.growth_entries;
drop policy if exists "Users can insert own growth entries" on public.growth_entries;
drop policy if exists "Users can update own growth entries" on public.growth_entries;
drop policy if exists "Users can delete own growth entries" on public.growth_entries;
create policy "Users can read own growth entries" on public.growth_entries
  for select using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can insert own growth entries" on public.growth_entries
  for insert with check (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can update own growth entries" on public.growth_entries
  for update using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  )) with check (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can delete own growth entries" on public.growth_entries
  for delete using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));

alter table public.milestones enable row level security;
drop policy if exists "Allow anon read" on public.milestones;
drop policy if exists "Allow anon insert" on public.milestones;
drop policy if exists "Allow anon update" on public.milestones;
drop policy if exists "Allow anon delete" on public.milestones;
drop policy if exists "Users can read own milestones" on public.milestones;
drop policy if exists "Users can insert own milestones" on public.milestones;
drop policy if exists "Users can update own milestones" on public.milestones;
drop policy if exists "Users can delete own milestones" on public.milestones;
create policy "Users can read own milestones" on public.milestones
  for select using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can insert own milestones" on public.milestones
  for insert with check (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can update own milestones" on public.milestones
  for update using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  )) with check (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));
create policy "Users can delete own milestones" on public.milestones
  for delete using (exists (
    select 1 from public.baby_profiles b
    where b.id = baby_id and b.user_id = auth.uid()
  ));

alter table public.baby_care_logs enable row level security;
drop policy if exists "Users can read own baby care logs" on public.baby_care_logs;
drop policy if exists "Users can insert own baby care logs" on public.baby_care_logs;
drop policy if exists "Users can update own baby care logs" on public.baby_care_logs;
drop policy if exists "Users can delete own baby care logs" on public.baby_care_logs;
create policy "Users can read own baby care logs" on public.baby_care_logs
  for select using (
    auth.uid() = user_id and exists (
      select 1 from public.baby_profiles b
      where b.id = baby_id and b.user_id = auth.uid()
    )
  );
create policy "Users can update own baby care logs" on public.baby_care_logs
  for update using (
    auth.uid() = user_id and exists (
      select 1 from public.baby_profiles b
      where b.id = baby_id and b.user_id = auth.uid()
    )
  ) with check (
    auth.uid() = user_id and exists (
      select 1 from public.baby_profiles b
      where b.id = baby_id and b.user_id = auth.uid()
    )
  );

-- Keep new inserts explicitly tied to a baby owned by the same account.
create policy "Users can insert own baby care logs" on public.baby_care_logs
  for insert with check (
    auth.uid() = user_id and exists (
      select 1 from public.baby_profiles b
      where b.id = baby_id and b.user_id = auth.uid()
    )
  );
create policy "Users can delete own baby care logs" on public.baby_care_logs
  for delete using (
    auth.uid() = user_id and exists (
      select 1 from public.baby_profiles b
      where b.id = baby_id and b.user_id = auth.uid()
    )
  );
