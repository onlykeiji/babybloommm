-- One Baby Care profile per account and author-only post editing.
-- Resolve any existing duplicate profiles manually before applying this
-- migration so no baby or related care history is deleted automatically.

create unique index if not exists baby_profiles_one_per_user_key
  on public.baby_profiles (user_id)
  where user_id is not null;

drop policy if exists "Authors can update their own posts" on public.community_posts;
create policy "Authors can update their own posts" on public.community_posts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
