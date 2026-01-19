-- Ensure UUID generation is available for server-side defaults.
create extension if not exists "pgcrypto";

-- Migrate sessions.id from bigint identity to UUID for client-generated IDs.
alter table public.sessions add column id_uuid uuid;

update public.sessions
   set id_uuid = gen_random_uuid()
 where id_uuid is null;

alter table public.sessions alter column id_uuid set not null;

alter table public.sessions drop constraint sessions_pkey;

alter table public.sessions rename column id to legacy_id;
alter table public.sessions rename column id_uuid to id;

alter table public.sessions alter column id set default gen_random_uuid();

alter table public.sessions add primary key (id);

create unique index if not exists idx_sessions_legacy_id
  on public.sessions (legacy_id);
