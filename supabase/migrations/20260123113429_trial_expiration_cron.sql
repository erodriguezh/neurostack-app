-- ============================================================================
-- Trial Expiration Cron Migration
-- ============================================================================
-- This migration creates the trial expiration function and schedules it
-- to run twice daily via pg_cron.
--
-- Depends on: 20260123092258_trial_expiration_columns.sql
-- - Requires trial_ends_at and trial_expired_at columns
-- - Requires idx_users_trial_expiration partial index
-- ============================================================================

-- ============================================================================
-- 1. CREATE EXPIRE_TRIALS FUNCTION
-- ============================================================================
-- This function finds all users who:
-- - Have subscription_status = 'trial'
-- - Have not yet been processed (trial_expired_at IS NULL)
-- - Have an expired trial (trial_ends_at < NOW())
--
-- It transitions them to 'free' tier and records the processing timestamp.
-- Returns the count of users processed for monitoring/logging.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.expire_trials()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  expired_count integer;
BEGIN
  UPDATE public.users
  SET subscription_status = 'free',
      trial_expired_at = NOW()
  WHERE subscription_status = 'trial'
    AND trial_expired_at IS NULL
    AND trial_ends_at < NOW();

  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;

COMMENT ON FUNCTION public.expire_trials() IS
  'Cron function that transitions expired trial users to free tier. Returns count of users processed.';

-- Revoke public execute to prevent unauthorized RPC calls
-- pg_cron runs as superuser and can still invoke this function
REVOKE ALL ON FUNCTION public.expire_trials() FROM PUBLIC;

-- ============================================================================
-- 2. ENABLE PG_CRON EXTENSION
-- ============================================================================
-- pg_cron requires Supabase Pro plan
-- The extension is typically pre-installed but may need to be enabled
-- Note: Do NOT specify WITH SCHEMA - let pg_cron use its default schema
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- 3. SCHEDULE CRON JOBS (IDEMPOTENT)
-- ============================================================================
-- Run twice daily at offset minutes to avoid thundering herd:
-- - Morning: 03:17 UTC
-- - Evening: 15:17 UTC
--
-- Job names prefixed with 'neurostack-' for easy identification
-- Uses DO block to unschedule existing jobs first (idempotent)
-- ============================================================================
DO $$
DECLARE
  jid bigint;
BEGIN
  -- Morning job: unschedule if exists, then schedule
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'neurostack-expire-trials-morning';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;
  PERFORM cron.schedule(
    'neurostack-expire-trials-morning',
    '17 3 * * *',
    'SELECT public.expire_trials()'
  );

  -- Evening job: unschedule if exists, then schedule
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'neurostack-expire-trials-evening';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;
  PERFORM cron.schedule(
    'neurostack-expire-trials-evening',
    '17 15 * * *',
    'SELECT public.expire_trials()'
  );
END $$;
