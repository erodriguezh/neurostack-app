-- ============================================================================
-- Update handle_new_user() Trigger: Remove Trial Columns
-- ============================================================================
-- Phase 11.2: Remove trial_period and trial_ends_at from the INSERT statement.
-- CRITICAL: Must run BEFORE Phase 11.3 drops these columns, otherwise the
-- trigger will fail with "column does not exist" errors on new user signup.
--
-- After this migration, new users are created with only:
--   id, subscription_status='free', protocol_ids='[]', onboarding_completed=false, created_at
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
    protocol_ids,
    onboarding_completed,
    created_at
  ) VALUES (
    new.id,
    'free',
    '[]'::jsonb,
    false,
    new.created_at
  );
  RETURN new;
END;
$$;
