-- Tracks which user authored each community post, so the app can show a
-- delete button for a user's own posts that actually persists across
-- sessions (previously tracked client-side in memory only) and so the
-- database itself only allows a post to be deleted by its author.

alter table public.community_posts
  add column if not exists user_id uuid references auth.users (id) on delete cascade;

drop policy if exists "Allow anon insert" on public.community_posts;
create policy "Authenticated users can insert their own posts" on public.community_posts
  for insert to authenticated with check (auth.uid() = user_id);

-- Likes are a shared counter anyone can bump today (see CommunityStore.setLiked),
-- so the update policy stays open — only delete is scoped to the author.
drop policy if exists "Allow anon delete" on public.community_posts;
create policy "Authors can delete their own posts" on public.community_posts
  for delete using (auth.uid() = user_id);
