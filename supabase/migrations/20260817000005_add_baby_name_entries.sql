create table if not exists public.baby_name_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  gender text not null check (gender in ('boy', 'girl', 'unisex')),
  origin text not null default '',
  meaning text not null default '',
  created_at timestamptz not null default now(),
  unique (user_id, name)
);

alter table public.baby_name_entries enable row level security;
create policy "Users can read own baby names" on public.baby_name_entries
  for select using (auth.uid() = user_id);
create policy "Users can insert own baby names" on public.baby_name_entries
  for insert with check (auth.uid() = user_id);
create policy "Users can update own baby names" on public.baby_name_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own baby names" on public.baby_name_entries
  for delete using (auth.uid() = user_id);
