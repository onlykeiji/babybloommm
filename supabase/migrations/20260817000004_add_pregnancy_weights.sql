create table if not exists public.pregnancy_weight_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  recorded_on date not null,
  weight_lb numeric(6, 1) not null check (weight_lb between 60 and 400),
  created_at timestamptz not null default now(),
  unique (user_id, recorded_on)
);

alter table public.pregnancy_weight_entries enable row level security;
create policy "Users can read own pregnancy weights" on public.pregnancy_weight_entries
  for select using (auth.uid() = user_id);
create policy "Users can insert own pregnancy weights" on public.pregnancy_weight_entries
  for insert with check (auth.uid() = user_id);
create policy "Users can update own pregnancy weights" on public.pregnancy_weight_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
