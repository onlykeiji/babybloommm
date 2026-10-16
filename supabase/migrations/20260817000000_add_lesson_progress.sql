-- Run this after 20260816000000_remove_demo_data_and_scope_family_planning.sql.
-- It persists completed lessons per authenticated account.

create table if not exists public.lesson_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  lesson_title text not null check (char_length(trim(lesson_title)) > 0),
  completed_at timestamptz not null default now(),
  unique (user_id, lesson_title)
);

alter table public.lesson_completions enable row level security;

drop policy if exists "Users can read own lesson completions" on public.lesson_completions;
drop policy if exists "Users can insert own lesson completions" on public.lesson_completions;
drop policy if exists "Users can update own lesson completions" on public.lesson_completions;

create policy "Users can read own lesson completions"
  on public.lesson_completions for select using (auth.uid() = user_id);
create policy "Users can insert own lesson completions"
  on public.lesson_completions for insert with check (auth.uid() = user_id);
create policy "Users can update own lesson completions"
  on public.lesson_completions for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
