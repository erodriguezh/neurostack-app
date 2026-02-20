-- ============================================================================
-- RevenueCat Webhook Bookkeeping Columns Migration
-- ============================================================================
-- This migration adds columns required for webhook idempotency and conflict
-- resolution. These columns are REQUIRED for Phase 9 webhook implementation.
--
-- Columns:
--   - subscription_updated_at: Timestamp of last subscription status change
--     (used for monotonicity checks to prevent stale updates)
--   - subscription_source: Source of the last update (e.g., 'revenuecat-webhook')
--   - rc_last_event_id: Last processed RevenueCat event ID (for idempotency)
-- ============================================================================

-- ============================================================================
-- 1. ADD WEBHOOK BOOKKEEPING COLUMNS
-- ============================================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_updated_at timestamptz NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_source text NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_last_event_id text NULL;
