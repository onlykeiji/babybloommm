-- Community groups, automatic membership, and member-only conversations.

create table if not exists public.community_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  topic text not null check (topic in ('TTC', 'Pregnancy', 'Baby Care', 'Postpartum', 'Mental Health')),
  description text not null,
  member_count integer not null default 0 check (member_count >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.group_memberships (
  group_id uuid not null references public.community_groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.community_groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  author_name text not null,
  body text not null check (char_length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

-- These are the available groups, not fake membership or post data.
insert into public.community_groups (name, topic, description) values
  ('TTC Warriors', 'TTC', 'supporting each other'),
  ('First-Time Moms', 'Baby Care', 'sharing firsts'),
  ('Pregnancy Circle', 'Pregnancy', 'sharing the journey'),
  ('Postpartum Circle', 'Postpartum', 'here day and night')
on conflict (name) do nothing;

create or replace function public.update_group_member_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.community_groups set member_count = member_count + 1 where id = new.group_id;
    return new;
  end if;
  update public.community_groups set member_count = greatest(member_count - 1, 0) where id = old.group_id;
  return old;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists group_memberships_update_count on public.group_memberships;
create trigger group_memberships_update_count
  after insert or delete on public.group_memberships
  for each row execute function public.update_group_member_count();

alter table public.community_groups enable row level security;
alter table public.group_memberships enable row level security;
alter table public.group_messages enable row level security;

create policy "Authenticated users can view groups" on public.community_groups
  for select to authenticated using (true);
create policy "Users can view own memberships" on public.group_memberships
  for select using (auth.uid() = user_id);
create policy "Users can join groups" on public.group_memberships
  for insert with check (auth.uid() = user_id);
create policy "Members can read group messages" on public.group_messages
  for select using (exists (select 1 from public.group_memberships m where m.group_id = group_messages.group_id and m.user_id = auth.uid()));
create policy "Members can send group messages" on public.group_messages
  for insert with check (auth.uid() = user_id and exists (select 1 from public.group_memberships m where m.group_id = group_messages.group_id and m.user_id = auth.uid()));

create or replace function public.community_metrics()
returns jsonb as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  return jsonb_build_object(
    'member_count', (select count(*) from public.profiles),
    'posts_today', (select count(*) from public.community_posts where created_at >= current_date),
    'my_group_count', (select count(*) from public.group_memberships where user_id = auth.uid())
  );
end;
$$ language plpgsql security definer set search_path = public;

grant execute on function public.community_metrics() to authenticated;
