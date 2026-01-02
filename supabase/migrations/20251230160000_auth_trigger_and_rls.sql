-- Auth trigger: Create public.users row on auth.users insert
-- Enforces 7-day trial with start_date from auth.users.created_at

-- Function to handle new user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.users (
    id,
    subscription_status,
    trial_period,
    protocol_ids,
    onboarding_completed,
    created_at
  ) values (
    new.id,
    'trial',
    jsonb_build_object('start_date', new.created_at::text),
    '[]'::jsonb,
    false,
    new.created_at
  );
  return new;
end;
$$;

-- Trigger on auth.users insert
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- RLS Policies for users table
alter table public.users enable row level security;

drop policy if exists "Users can read own profile" on public.users;
create policy "Users can read own profile"
  on public.users for select
  using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

-- RLS Policies for sessions table
alter table public.sessions enable row level security;

drop policy if exists "Users can read own sessions" on public.sessions;
create policy "Users can read own sessions"
  on public.sessions for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own sessions" on public.sessions;
create policy "Users can insert own sessions"
  on public.sessions for insert
  with check (auth.uid() = user_id);

-- RLS Policies for protocols table (read-only for all authenticated users)
alter table public.protocols enable row level security;

drop policy if exists "Authenticated users can read protocols" on public.protocols;
create policy "Authenticated users can read protocols"
  on public.protocols for select
  to authenticated
  using (true);

-- Remove any write policies for protocols (admin-only via service role)
drop policy if exists "Users can insert protocols" on public.protocols;
drop policy if exists "Users can update protocols" on public.protocols;

-- RLS Policies for research_citations table (read-only for all authenticated users)
alter table public.research_citations enable row level security;

drop policy if exists "Authenticated users can read citations" on public.research_citations;
create policy "Authenticated users can read citations"
  on public.research_citations for select
  to authenticated
  using (true);

-- Remove any write policies for citations (admin-only via service role)
drop policy if exists "Users can insert citations" on public.research_citations;
drop policy if exists "Users can update citations" on public.research_citations;
