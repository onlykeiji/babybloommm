-- Daily baby-care events: feeds, diapers, and sleep periods.
create table if not exists public.baby_care_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  baby_id uuid not null references public.baby_profiles (id) on delete cascade,
  kind text not null check (kind in ('feeding', 'diaper', 'sleep')),
  occurred_at timestamptz not null default now(),
  duration_minutes int check (duration_minutes is null or duration_minutes >= 0),
  amount numeric(6, 1) check (amount is null or amount >= 0),
  details text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists baby_care_logs_baby_occurred_at_idx
  on public.baby_care_logs (baby_id, occurred_at desc);

alter table public.baby_care_logs enable row level security;
create policy "Users can read own baby care logs" on public.baby_care_logs
  for select using (auth.uid() = user_id);
create policy "Users can insert own baby care logs" on public.baby_care_logs
  for insert with check (auth.uid() = user_id);
create policy "Users can delete own baby care logs" on public.baby_care_logs
  for delete using (auth.uid() = user_id);
