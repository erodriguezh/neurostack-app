-- ============================================================================
-- NeuroStack Initial Schema
-- ============================================================================
-- This migration creates the core tables for the NeuroStack application:
-- - protocols: Neuroscience protocols with evidence-based research
-- - research_citations: Scientific citations backing each protocol
-- - sessions: User activity logs for protocol completion
-- - users: User profiles with subscription and trial management
-- ============================================================================

-- ============================================================================
-- PROTOCOLS TABLE
-- ============================================================================
create table public.protocols (
                                  id bigint generated always as identity primary key,
                                  name text not null,
                                  target jsonb not null,
                                  category text not null,
                                  evidence_level text not null,
                                  created_at timestamptz not null default now(),
                                  deleted_at timestamptz
);

comment on table public.protocols is
  'Neuroscience protocols with evidence-based targets. Each protocol includes '
  'frequency recommendations, intensity levels, and research backing. '
  'Soft deletion via deleted_at timestamp.';

comment on column public.protocols.target is
  'JSONB structure: { "frequency": { "min_per_week": 3, "max_per_week": 4 }, '
  '"duration_seconds": 1200, "intensity": "108°F" }';

comment on column public.protocols.category is
  'Enum stored as text: exercise, heatTherapy, coldTherapy, supplementation, etc.';

comment on column public.protocols.evidence_level is
  'Enum stored as text: preliminary, moderate, strong, proven';

-- Indexes for common query patterns
create index idx_protocols_category
    on public.protocols (category);

create index idx_protocols_active
    on public.protocols (deleted_at)
    where deleted_at is null;

-- ============================================================================
-- RESEARCH CITATIONS TABLE
-- ============================================================================
create table public.research_citations (
                                           id bigint generated always as identity primary key,
                                           protocol_id bigint not null references public.protocols (id) on delete cascade,
                                           authors text not null,
                                           year int not null,
                                           title text not null,
                                           journal text not null,
                                           doi text,
                                           url text,
                                           constraint year_range check (year between 1900 and 2100)
    );

comment on table public.research_citations is
  'Scientific research citations backing protocol recommendations. '
  'Each protocol must have at least one citation (enforced at domain level).';

-- Index for protocol lookups
create index idx_research_citations_protocol_id
    on public.research_citations (protocol_id);

-- ============================================================================
-- SESSIONS TABLE
-- ============================================================================
create table public.sessions (
                                 id bigint generated always as identity primary key,
                                 protocol_id bigint not null references public.protocols (id),
                                 user_id uuid not null references auth.users (id),
                                 completed_at timestamptz not null,
                                 duration_seconds int,
                                 notes text,
                                 constraint duration_positive check (duration_seconds > 0)
);

comment on table public.sessions is
  'User activity logs for protocol completion. Used for streak calculation, '
  'calendar views, and progress tracking. Sessions are immutable after creation.';

-- Indexes for common query patterns
create index idx_sessions_protocol_id
    on public.sessions (protocol_id);

create index idx_sessions_user_id
    on public.sessions (user_id);

create index idx_sessions_completed_at
    on public.sessions (completed_at desc);

create index idx_sessions_user_date_range
    on public.sessions (user_id, completed_at);

-- ============================================================================
-- USERS TABLE
-- ============================================================================
create table public.users (
                              id uuid primary key references auth.users (id) on delete cascade,
                              subscription_status text not null default 'free',
                              trial_period jsonb,
                              protocol_ids jsonb not null default '[]'::jsonb,
                              onboarding_completed boolean not null default false,
                              created_at timestamptz not null default now()
);

comment on table public.users is
  'User profiles extending Supabase auth.users. Manages subscription state, '
  'trial periods, active protocol stack, and onboarding progress. '
  'ID matches auth.users for seamless authentication integration.';

comment on column public.users.subscription_status is
  'Enum stored as text: free, expired, premiumMonthly, premiumAnnual, premiumLifetime';

comment on column public.users.trial_period is
  'JSONB structure: { "start_date": "2025-01-01T00:00:00Z" }. '
  'Trial duration calculated as 14 days from start_date at domain level.';

comment on column public.users.protocol_ids is
  'JSON array of protocol IDs representing user''s active stack. '
  'Free users limited to 2, premium unlimited (enforced at domain level).';

-- Index for common query patterns
create index idx_users_subscription_status
    on public.users (subscription_status);

create index idx_users_onboarding
    on public.users (onboarding_completed);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS on all tables
alter table public.protocols enable row level security;
alter table public.research_citations enable row level security;
alter table public.sessions enable row level security;
alter table public.users enable row level security;

-- Protocols: Public read, admin write
create policy "Protocols are viewable by everyone"
  on public.protocols for select
                                     using (true);

create policy "Protocols are insertable by authenticated users"
  on public.protocols for insert
  with check (auth.role() = 'authenticated');

create policy "Protocols are updatable by authenticated users"
  on public.protocols for update
                                            using (auth.role() = 'authenticated');

-- Research citations: Public read, follows protocol permissions
create policy "Citations are viewable by everyone"
  on public.research_citations for select
                                              using (true);

create policy "Citations are insertable by authenticated users"
  on public.research_citations for insert
  with check (auth.role() = 'authenticated');

-- Sessions: Users can only access their own sessions
create policy "Users can view their own sessions"
  on public.sessions for select
                                           using (auth.uid() = user_id);

create policy "Users can insert their own sessions"
  on public.sessions for insert
  with check (auth.uid() = user_id);

-- Users: Users can only access their own profile
create policy "Users can view their own profile"
  on public.users for select
                                        using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.users for update
                                 using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.users for insert
  with check (auth.uid() = id);