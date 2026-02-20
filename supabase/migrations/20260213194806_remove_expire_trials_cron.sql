-- ============================================================================
-- Remove Trial Expiration Cron Jobs and Function
-- ============================================================================
-- RevenueCat now manages trial expiration, so the pg_cron jobs and the
-- expire_trials() function are no longer needed.
--
-- Undoes: 20260123113429_trial_expiration_cron.sql
-- ============================================================================

-- ============================================================================
-- 1. UNSCHEDULE CRON JOBS (IDEMPOTENT)
-- ============================================================================
-- Uses DO block with jobid lookup so the migration is safe to run even if
-- the jobs have already been removed.
-- ============================================================================
DO $$
DECLARE
  jid bigint;
BEGIN
  -- Morning job
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'neurostack-expire-trials-morning';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;

  -- Evening job
  SELECT jobid INTO jid FROM cron.job WHERE jobname = 'neurostack-expire-trials-evening';
  IF jid IS NOT NULL THEN
    PERFORM cron.unschedule(jid);
  END IF;
END $$;

-- ============================================================================
-- 2. DROP EXPIRE_TRIALS FUNCTION
-- ============================================================================
DROP FUNCTION IF EXISTS public.expire_trials();
