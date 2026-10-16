-- Persist one like per post for each authenticated account.

create table if not exists public.community_post_likes (
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists community_post_likes_user_id_idx
  on public.community_post_likes (user_id, created_at desc);

alter table public.community_post_likes enable row level security;
drop policy if exists "Users can read community likes" on public.community_post_likes;
drop policy if exists "Users can add their own community likes" on public.community_post_likes;
drop policy if exists "Users can remove their own community likes" on public.community_post_likes;
create policy "Users can read community likes" on public.community_post_likes
  for select to authenticated using (true);
create policy "Users can add their own community likes" on public.community_post_likes
  for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can remove their own community likes" on public.community_post_likes
  for delete to authenticated using (auth.uid() = user_id);

create or replace function public.sync_community_post_like_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_post_id uuid := coalesce(new.post_id, old.post_id);
begin
  update public.community_posts
  set likes = (
    select count(*)::integer from public.community_post_likes
    where post_id = affected_post_id
  )
  where id = affected_post_id;
  return coalesce(new, old);
end;
$$;

drop trigger if exists sync_community_post_like_count_trigger on public.community_post_likes;
create trigger sync_community_post_like_count_trigger
after insert or delete on public.community_post_likes
for each row execute function public.sync_community_post_like_count();

-- Legacy counters have no account ownership, so synchronize them to the new
-- table once. This guarantees displayed totals are accurate going forward.
update public.community_posts
set likes = (
  select count(*)::integer from public.community_post_likes l
  where l.post_id = community_posts.id
);
