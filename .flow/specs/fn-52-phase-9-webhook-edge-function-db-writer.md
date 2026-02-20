# Phase 9: Webhook Edge Function (DB Writer)

**Source:** `plan_paywall_modal.md` Phase 9

## Overview
Create the RevenueCat webhook Edge Function - the ONLY writer of subscription status to Supabase DB. Enforces "webhook is DB writer" design principle.

## Scope
- SQL migration: `apply_revenuecat_event()` SECURITY DEFINER RPC function
- Edge Function: `supabase/functions/revenuecat-webhook/index.ts`
- Authorization header verification (shared secret), UUID validation, status mapping, event handling

## Approach
1. Create SECURITY DEFINER RPC migration (monotonicity + idempotency)
2. Create Edge Function with full event handling
3. Manual: set secrets, deploy, configure webhook in RevenueCat dashboard

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] `apply_revenuecat_event()` migration applied successfully
- [ ] Edge Function handles all RevenueCat events per Phase 9.2 table
- [ ] Authorization header verification (RevenueCat does not support HMAC; uses configurable shared secret in Authorization header per RC docs)
- [ ] UUID validation for app_user_id
- [ ] TRANSFER updates both users
- [ ] Trial vs paid expiration distinction
- [ ] CANCELLATION = NO CHANGE
- [ ] Only service_role can call RPC

## References
- `plan_paywall_modal.md` Phase 9
- `docs/specs/20260123220000_spec_paywall_modal.md`
