-- ============================================================================
-- Trial Expiration Columns Migration
-- ============================================================================
-- This migration adds support for trial expiration processing:
-- - CHECK constraint for subscription_status enum values
-- - trial_ends_at column for explicit expiration timestamp
-- - trial_expired_at column for audit tracking of cron processing
-- - Partial index for efficient cron queries
-- - Backfill existing users with computed trial_ends_at
-- - Update auth trigger to set trial_ends_at on signup
-- ============================================================================

-- ============================================================================
-- 1. ADD CHECK CONSTRAINT FOR SUBSCRIPTION_STATUS
-- ============================================================================
-- Use NOT VALID to avoid table scan + lock, then validate separately
ALTER TABLE public.users
ADD CONSTRAINT chk_subscription_status
CHECK (subscription_status IN (
  'trial', 'free', 'premiumMonthly', 'premiumAnnual', 'premiumLifetime', 'expired', 'grace'
)) NOT VALID;

ALTER TABLE public.users
VALIDATE CONSTRAINT chk_subscription_status;

-- Update comment to reflect valid enum values
COMMENT ON COLUMN public.users.subscription_status IS
  'Enum stored as text: trial, free, premiumMonthly, premiumAnnual, premiumLifetime, expired, grace';

-- ============================================================================
-- 2. ADD TRIAL EXPIRATION COLUMNS
-- ============================================================================
ALTER TABLE public.users
ADD COLUMN trial_ends_at timestamptz NULL;

ALTER TABLE public.users
ADD COLUMN trial_expired_at timestamptz NULL;

COMMENT ON COLUMN public.users.trial_ends_at IS
  'Explicit timestamp when trial period ends. Computed as created_at + 7 days on signup.';

COMMENT ON COLUMN public.users.trial_expired_at IS
  'Audit timestamp recording when the cron job transitioned user from trial to free tier.';

-- ============================================================================
-- 3. ADD PARTIAL INDEX FOR CRON QUERY PERFORMANCE
-- ============================================================================
CREATE INDEX idx_users_trial_expiration
ON public.users (trial_ends_at)
WHERE subscription_status = 'trial' AND trial_expired_at IS NULL;

-- ============================================================================
-- 4. BACKFILL EXISTING USERS
-- ============================================================================
-- Compute trial_ends_at from trial_period JSONB for existing users
UPDATE public.users
SET trial_ends_at = (trial_period->>'start_date')::timestamptz + INTERVAL '7 days'
WHERE trial_period IS NOT NULL
  AND trial_ends_at IS NULL;

-- ============================================================================
-- 5. UPDATE AUTH TRIGGER TO SET trial_ends_at ON SIGNUP
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (
    id,
    subscription_status,
    trial_period,
    trial_ends_at,
    protocol_ids,
    onboarding_completed,
    created_at
  ) VALUES (
    new.id,
    'trial',
    jsonb_build_object('start_date', new.created_at::text),
    new.created_at + INTERVAL '7 days',
    '[]'::jsonb,
    false,
    new.created_at
  );
  RETURN new;
END;
$$;
