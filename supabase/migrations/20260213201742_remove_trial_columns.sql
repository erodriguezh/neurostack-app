-- ============================================================================
-- Remove Trial Columns Migration
-- ============================================================================
-- RevenueCat is now the source of truth for trial state.
-- Prerequisites completed:
--   - Phase 11.1: pg_cron jobs removed
--   - Phase 11.2: handle_new_user() trigger updated (no longer references trial columns)
--   - Phase 10.4: UserDto no longer serializes trial_ends_at
-- ============================================================================

-- 1. Drop the partial index that references trial columns
DROP INDEX IF EXISTS idx_users_trial_expiration;

-- 2. Drop the trial columns (IF EXISTS for idempotency)
ALTER TABLE public.users DROP COLUMN IF EXISTS trial_ends_at;
ALTER TABLE public.users DROP COLUMN IF EXISTS trial_expired_at;
ALTER TABLE public.users DROP COLUMN IF EXISTS trial_period;
