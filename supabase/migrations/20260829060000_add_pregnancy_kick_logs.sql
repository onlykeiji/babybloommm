-- Store every pregnancy kick tap as an individual, user-owned event.

create table if not exists public.pregnancy_kick_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists pregnancy_kick_logs_user_occurred_at_idx
  on public.pregnancy_kick_logs (user_id, occurred_at desc);

alter table public.pregnancy_kick_logs enable row level security;
drop policy if exists "Users can read own pregnancy kick logs"
  on public.pregnancy_kick_logs;
drop policy if exists "Users can insert own pregnancy kick logs"
  on public.pregnancy_kick_logs;
drop policy if exists "Users can delete own pregnancy kick logs"
  on public.pregnancy_kick_logs;

create policy "Users can read own pregnancy kick logs"
  on public.pregnancy_kick_logs for select to authenticated
  using (auth.uid() = user_id);
create policy "Users can insert own pregnancy kick logs"
  on public.pregnancy_kick_logs for insert to authenticated
  with check (auth.uid() = user_id);
create policy "Users can delete own pregnancy kick logs"
  on public.pregnancy_kick_logs for delete to authenticated
  using (auth.uid() = user_id);
