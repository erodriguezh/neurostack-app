-- ============================================================================
-- RevenueCat Webhook RPC Migration
-- ============================================================================
-- Creates the apply_revenuecat_event() SECURITY DEFINER function that the
-- revenuecat-webhook Edge Function calls to update subscription status.
--
-- Design:
--   - Atomic conditional UPDATE with monotonicity + idempotency
--   - Validates subscription_status against allowed values
--   - Only callable by service_role (prevents privilege escalation)
--   - SECURITY DEFINER with empty search_path for safety
--
-- Dependencies:
--   - 20260127202238_revenuecat_webhook_columns.sql (adds subscription_updated_at,
--     subscription_source, rc_last_event_id columns)
--   - 20260123092258_trial_expiration_columns.sql (adds chk_subscription_status
--     CHECK constraint)
-- ============================================================================

-- ============================================================================
-- 1. CREATE SECURITY DEFINER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION public.apply_revenuecat_event(
  p_user_id uuid,
  p_event_id text,
  p_occurred_at timestamptz,
  p_subscription_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Guard against NULL arguments (prevents silent no-ops that break
  -- idempotency/monotonicity semantics)
  IF p_user_id IS NULL OR p_event_id IS NULL
     OR p_occurred_at IS NULL OR p_subscription_status IS NULL THEN
    RAISE EXCEPTION 'apply_revenuecat_event: null argument';
  END IF;

  -- Validate status before attempting update (prevents retry storms on bad data)
  -- NOTE: includes premiumLifetime for forward-compat with chk_subscription_status
  IF p_subscription_status NOT IN (
    'free','trial','premiumMonthly','premiumAnnual','premiumLifetime','expired','grace'
  ) THEN
    RAISE EXCEPTION 'invalid subscription_status: %', p_subscription_status;
  END IF;

  -- Atomic conditional update with monotonicity + idempotency
  -- 1. Skip if same event already processed (idempotency via rc_last_event_id)
  -- 2. Only apply if newer than last update (monotonicity via subscription_updated_at)
  -- 3. Tie-break: same timestamp with different event_id = last arrival wins
  UPDATE public.users
  SET
    subscription_status = p_subscription_status,
    subscription_updated_at = p_occurred_at,
    subscription_source = 'revenuecat-webhook',
    rc_last_event_id = p_event_id
  WHERE id = p_user_id
    AND rc_last_event_id IS DISTINCT FROM p_event_id
    AND (
      subscription_updated_at IS NULL
      OR p_occurred_at > subscription_updated_at
      OR (p_occurred_at = subscription_updated_at
          AND rc_last_event_id IS DISTINCT FROM p_event_id)
    );
END;
$$;

-- ============================================================================
-- 2. RESTRICT ACCESS TO SERVICE_ROLE ONLY
-- ============================================================================
-- CRITICAL: Only service_role can call this function.
-- Prevents privilege escalation from clients with anon/authenticated keys.
REVOKE ALL ON FUNCTION public.apply_revenuecat_event(uuid, text, timestamptz, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.apply_revenuecat_event(uuid, text, timestamptz, text) FROM anon;
REVOKE ALL ON FUNCTION public.apply_revenuecat_event(uuid, text, timestamptz, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.apply_revenuecat_event(uuid, text, timestamptz, text) TO service_role;
