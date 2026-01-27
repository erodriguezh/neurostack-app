# fn-32-3ph Paywall Modal - Phase 1.1: Update handle_new_user() Trigger

## Overview
Update the Supabase `handle_new_user()` trigger to create new users with `subscription_status = 'free'` instead of `'trial'`. This aligns with the RevenueCat integration where trials are managed by RevenueCat, not Supabase.

## Scope
- Create a new migration file: `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_new_users_free.sql`
- Replace the existing `handle_new_user()` function to set `subscription_status = 'free'`
- Set `trial_period` and `trial_ends_at` to `NULL` (no longer used for new users)

## Approach
Create a `CREATE OR REPLACE FUNCTION` migration that updates the trigger to:
1. Set `subscription_status` to `'free'` (was `'trial'`)
2. Set `trial_period` to `NULL` (was computed)
3. Set `trial_ends_at` to `NULL` (was computed)

This ensures new users start in the free tier and can upgrade via RevenueCat paywall.

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] New migration file exists at `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_new_users_free.sql`
- [ ] Migration uses `CREATE OR REPLACE FUNCTION` for `handle_new_user()`
- [ ] New users get `subscription_status = 'free'`
- [ ] `trial_period` and `trial_ends_at` are set to `NULL`
- [ ] Migration follows existing conventions in `supabase/migrations/`

## References
- `plan_paywall_modal.md` - Phase 1.1
- `docs/specs/20260123220000_spec_paywall_modal.md`
- Existing trigger: check current `handle_new_user()` implementation in migrations
