-- Public post comments. Any signed-in user can read and participate.

create table if not exists public.community_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  author_name text not null,
  body text not null check (char_length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists community_comments_post_created_at_idx
  on public.community_comments (post_id, created_at);

create or replace function public.update_community_comment_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.community_posts set comments = comments + 1 where id = new.post_id;
    return new;
  end if;
  update public.community_posts set comments = greatest(comments - 1, 0) where id = old.post_id;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists community_comments_update_count on public.community_comments;
create trigger community_comments_update_count
  after insert or delete on public.community_comments
  for each row execute function public.update_community_comment_count();

alter table public.community_comments enable row level security;
create policy "Authenticated users can read comments" on public.community_comments
  for select to authenticated using (true);
create policy "Authenticated users can add comments" on public.community_comments
  for insert to authenticated with check (auth.uid() = user_id);
