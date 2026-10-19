-- UPS Events admin: database setup.
-- Run once in Supabase (SQL Editor -> New query -> paste -> Run). Safe to run again.

-- 1. Who can use the admin page. To add an admin: create the user under
--    Authentication -> Users, then add their email to this table (Table Editor -> admins).
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins a
    where lower(a.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- 2. Events. Field names match fromRow() in index.html.
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name        text not null,
  venue       text not null,
  category    text not null default 'Festivals',
  space       text,
  occasion    text,
  client      text,
  date        date,
  year        int,
  summary     text not null default '',
  description text not null default '',
  highlights  text[] not null default '{}',
  photos      jsonb not null default '[]',   -- [{ id, full, small, w, h, c, alt }], paths inside the media bucket
  videos      jsonb not null default '[]',   -- [{ id, path, poster, title, duration }]
  cover       text,                          -- id of the cover photo
  layout      text not null default 'auto',
  showcase    int check (showcase between 1 and 6),  -- position among the big home page showcases
  published   boolean not null default false,
  on_front    boolean not null default false,        -- in the home page slideshow
  in_gallery  boolean not null default true,
  in_films    boolean not null default true,
  builtin     boolean not null default false,        -- an edit of the built-in event with this slug
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- added after the first setup; harmless when the column is already there
alter table public.events add column if not exists builtin boolean not null default false;

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists events_touch on public.events;
create trigger events_touch before update on public.events
  for each row execute function public.touch_updated_at();

alter table public.events enable row level security;
grant select on public.events to anon, authenticated;
grant insert, update, delete on public.events to authenticated;

-- edits of built-in events are readable even when unpublished, so the site knows to hide those events
drop policy if exists "Published events are public" on public.events;
create policy "Published events are public" on public.events
  for select to anon, authenticated
  using (published or builtin or (select public.is_admin()));

drop policy if exists "Admins manage events" on public.events;
create policy "Admins manage events" on public.events
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- 3. Photo and film storage: anyone can view, only admins can upload or delete.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 52428800,
        array['image/webp', 'image/jpeg', 'image/png', 'video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Admins read media" on storage.objects;
create policy "Admins read media" on storage.objects
  for select to authenticated
  using (bucket_id = 'media' and (select public.is_admin()));

drop policy if exists "Admins upload media" on storage.objects;
create policy "Admins upload media" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'media' and (select public.is_admin()));

drop policy if exists "Admins change media" on storage.objects;
create policy "Admins change media" on storage.objects
  for update to authenticated
  using (bucket_id = 'media' and (select public.is_admin()))
  with check (bucket_id = 'media' and (select public.is_admin()));

drop policy if exists "Admins delete media" on storage.objects;
create policy "Admins delete media" on storage.objects
  for delete to authenticated
  using (bucket_id = 'media' and (select public.is_admin()));
