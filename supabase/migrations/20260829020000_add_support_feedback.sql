create table if not exists public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  category text not null check (category in ('question', 'technical', 'account', 'feedback')),
  subject text not null check (char_length(trim(subject)) between 3 and 120),
  message text not null check (char_length(trim(message)) between 10 and 4000),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved')),
  created_at timestamptz not null default now()
);

create table if not exists public.app_ratings (
  user_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  feedback text not null default '' check (char_length(feedback) <= 1000),
  updated_at timestamptz not null default now()
);

create index if not exists support_requests_user_created_idx
  on public.support_requests (user_id, created_at desc);

alter table public.support_requests enable row level security;
drop policy if exists "Users can create own support requests" on public.support_requests;
drop policy if exists "Users can read own support requests" on public.support_requests;
create policy "Users can create own support requests" on public.support_requests
  for insert with check (auth.uid() = user_id);
create policy "Users can read own support requests" on public.support_requests
  for select using (auth.uid() = user_id);

alter table public.app_ratings enable row level security;
drop policy if exists "Users can read own rating" on public.app_ratings;
drop policy if exists "Users can insert own rating" on public.app_ratings;
drop policy if exists "Users can update own rating" on public.app_ratings;
create policy "Users can read own rating" on public.app_ratings
  for select using (auth.uid() = user_id);
create policy "Users can insert own rating" on public.app_ratings
  for insert with check (auth.uid() = user_id);
create policy "Users can update own rating" on public.app_ratings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
