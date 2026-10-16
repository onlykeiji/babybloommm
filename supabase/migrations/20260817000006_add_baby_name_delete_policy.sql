-- Run this if 20260817000005_add_baby_name_entries.sql was already applied.
drop policy if exists "Users can delete own baby names" on public.baby_name_entries;
create policy "Users can delete own baby names" on public.baby_name_entries
  for delete using (auth.uid() = user_id);
