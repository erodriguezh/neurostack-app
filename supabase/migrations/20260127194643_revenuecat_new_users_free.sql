-- ============================================================================
-- RevenueCat New Users Free Migration
-- ============================================================================
-- This migration updates the handle_new_user() trigger to create new users
-- with subscription_status = 'free' instead of 'trial'.
--
-- With RevenueCat integration, trials are managed by RevenueCat, not Supabase.
-- New users start in the free tier and can upgrade via the RevenueCat paywall.
-- ============================================================================

-- ============================================================================
-- 1. UPDATE AUTH TRIGGER TO SET subscription_status = 'free'
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
    'free',
    NULL,
    NULL,
    '[]'::jsonb,
    false,
    new.created_at
  );
  RETURN new;
END;
$$;
