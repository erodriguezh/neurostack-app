# fn-33-6ay Paywall Modal - Phase 1.2: Add Webhook Bookkeeping Columns

## Overview

Add database columns required for webhook idempotency and conflict resolution. These columns are REQUIRED for Phase 9 webhook implementation.

## Scope

- Create new Supabase migration file
- Add three columns to `users` table for RevenueCat webhook tracking

## Approach

Create migration file `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_webhook_columns.sql` with:

```sql
-- Add columns for webhook idempotency and conflict resolution
-- REQUIRED: Phase 9 webhook depends on these columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_updated_at timestamptz NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_source text NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_last_event_id text NULL;
```

## Column Purposes

- `subscription_updated_at`: Timestamp of last subscription status change (for monotonicity)
- `subscription_source`: Source of the last update (e.g., 'revenuecat-webhook')
- `rc_last_event_id`: Last processed RevenueCat event ID (for idempotency)

## Quick commands

- `flutter analyze`
- `flutter test`

## Acceptance

- [ ] Migration file created with proper timestamp naming
- [ ] All three columns added with correct types (timestamptz, text, text)
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Changes committed

## References

- `docs/specs/20260123220000_spec_paywall_modal.md`
- `plan_paywall_modal.md` (Phase 1.2)
