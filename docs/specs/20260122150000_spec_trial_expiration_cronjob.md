# Spec: Trial Expiration Cronjob

**Created:** 2026-01-22
**Status:** Draft
**References:**
- Related: `docs/specs/20260120120000_spec_trial_expiration_modal.md`
- Schema: `supabase/migrations/20251204192228_initial_schema.sql`
- Auth Trigger: `supabase/migrations/20251230160000_auth_trigger_and_rls.sql`
- User Domain: `lib/features/user/domain/entities/user.dart`
- TrialPeriod VO: `lib/features/user/domain/value_objects/trial_period.dart`

---

## Overview

A Supabase pg_cron job that automatically transitions users from `trial` to `free` subscription status when their 7-day trial period expires. This backend process ensures the trial expiration modal only triggers once per user, and preserves historical trial data for analytics.

---

## Problem Statement

Without backend expiration:
1. Trial expiration is only detected client-side when app launches
2. Users with `subscription_status = 'trial'` and expired `trial_period` trigger the modal on every app launch until they manually choose
3. No audit trail of when trials expired
4. Query complexity: must compute `start_date + 7 days` on every read

---

## Solution

### Schema Changes

| Column | Type | Purpose |
|--------|------|---------|
| `trial_ends_at` | `timestamptz` | Pre-computed end date for efficient cron queries |
| `trial_expired_at` | `timestamptz` | Audit timestamp when cron processed the transition |

### Cron Behavior

- **Frequency:** 2x daily (03:17 and 15:17 UTC)
- **Query:** `WHERE subscription_status = 'trial' AND trial_expired_at IS NULL AND trial_ends_at < NOW()`
- **Action:** `SET subscription_status = 'free', trial_expired_at = NOW()`
- **Idempotency:** `trial_expired_at IS NULL` prevents re-processing

---

## Invariants

| ID | Rule | Enforcement |
|----|------|-------------|
| **INV-M2** | Premium Trial MUST last exactly 7 days | `trial_ends_at = created_at + 7 days` computed by auth trigger |
| **INV-B6** | Trial expiration MUST preserve historical data | `trial_period` JSONB retained; only `subscription_status` changes |
| **INV-B7** | Cron MUST be idempotent | `trial_expired_at IS NULL` check prevents double-processing |
| **INV-B8** | Timezone MUST be UTC | All timestamps stored/compared in UTC |

---

## Data Flow

### New User Signup
```
auth.users INSERT
    ↓
handle_new_user() trigger
    ↓
public.users INSERT with:
  - subscription_status = 'trial'
  - trial_period = { "start_date": created_at }
  - trial_ends_at = created_at + 7 days
  - trial_expired_at = NULL
```

### Trial Expiration (Day 8+)
```
pg_cron (03:17 or 15:17 UTC)
    ↓
expire_trials() function
    ↓
UPDATE users WHERE:
  - subscription_status = 'trial'
  - trial_expired_at IS NULL
  - trial_ends_at < NOW()
    ↓
SET:
  - subscription_status = 'free'
  - trial_expired_at = NOW()
```

### App Launch (Post-Expiration)
```
Flutter app launch
    ↓
Fetch user from Supabase
    ↓
subscription_status = 'free' (already transitioned)
    ↓
isTrialExpired check: status != 'trial' → false
    ↓
Modal does NOT trigger
```

---

## Schema Details

### users Table (updated)

```sql
-- Existing columns
id uuid PRIMARY KEY
subscription_status text NOT NULL DEFAULT 'free'
trial_period jsonb
protocol_ids jsonb NOT NULL DEFAULT '[]'
onboarding_completed boolean NOT NULL DEFAULT false
created_at timestamptz NOT NULL DEFAULT now()

-- New columns
trial_ends_at timestamptz        -- Computed: created_at + 7 days
trial_expired_at timestamptz     -- Set by cron when transitioned
```

### Index for Cron Query

```sql
CREATE INDEX idx_users_trial_expiration
ON public.users (subscription_status, trial_ends_at)
WHERE subscription_status = 'trial';
```

---

## Flutter Integration

### TrialPeriod Value Object

**Current:** `endDate` is a computed getter
```dart
// lib/features/user/domain/value_objects/trial_period.dart:41-42
DateTime get endDate => startDate.add(const Duration(days: trialDurationDays));
```

**Change:** `endDate` becomes a stored field
```dart
const factory TrialPeriod({
  required DateTime startDate,
  required DateTime endDate,  // Now stored, read from DB
}) = _TrialPeriod;
```

### UserDto

**Current:** No `trial_ends_at` field
```dart
// lib/features/user/data/dtos/user_dto.dart:37
@JsonKey(name: 'trial_period') TrialPeriodDto? trialPeriod,
```

**Change:** Add top-level column mapping
```dart
@JsonKey(name: 'trial_ends_at', fromJson: _nullableStringFromJson)
String? trialEndsAt,
```

### Trial Expiration Check (unchanged)

```dart
// lib/home/home_view_model.dart:250-256
final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
    (user.trialPeriod?.isExpired(now) ?? false);
```

After cron runs: `subscriptionStatus == 'free'` → first condition fails → modal doesn't trigger.

---

## Migration Files

### Migration 1: Add columns + update trigger

**File:** `supabase/migrations/YYYYMMDDHHMMSS_trial_expiration_columns.sql`

- Add `trial_ends_at` column
- Add `trial_expired_at` column
- Create partial index for cron query
- Backfill existing users: `trial_ends_at = (trial_period->>'start_date')::timestamptz + INTERVAL '7 days'`
- Update `handle_new_user()` to compute `trial_ends_at` on signup

### Migration 2: Cron function + schedule

**File:** `supabase/migrations/YYYYMMDDHHMMSS_trial_expiration_cron.sql`

- Create `expire_trials()` function
- Enable `pg_cron` extension
- Schedule jobs at 03:17 and 15:17 UTC

---

## Monitoring

### Query: Check cron job health
```sql
SELECT * FROM cron.job WHERE jobname LIKE 'expire-trials%';
```

### Query: Recent expirations
```sql
SELECT id, trial_ends_at, trial_expired_at
FROM public.users
WHERE trial_expired_at IS NOT NULL
ORDER BY trial_expired_at DESC
LIMIT 20;
```

### Query: Pending expirations
```sql
SELECT COUNT(*)
FROM public.users
WHERE subscription_status = 'trial'
  AND trial_expired_at IS NULL
  AND trial_ends_at < NOW();
```

---

## Test Scenarios

### Backend Tests (SQL)

| Scenario | Setup | Expected |
|----------|-------|----------|
| Expired trial processed | User with `trial_ends_at = NOW() - 1 day` | Status → `free`, `trial_expired_at` set |
| Active trial not processed | User with `trial_ends_at = NOW() + 1 day` | No change |
| Already processed not re-processed | User with `trial_expired_at` already set | No change |
| Premium user not affected | User with `subscription_status = 'premiumMonthly'` | No change |

### Flutter Tests

| Scenario | Test File | Expected |
|----------|-----------|----------|
| DTO parses `trial_ends_at` | `test/features/user/data/dtos/user_dto_test.dart` | `TrialPeriod.endDate` matches DB value |
| DTO handles missing `trial_ends_at` | `test/features/user/data/dtos/user_dto_test.dart` | Falls back to computed `startDate + 7 days` |
| Domain `fromDates()` factory | `test/features/user/domain/value_objects/trial_period_test.dart` | Creates with explicit dates |

---

## Out of Scope

- Email notifications on trial expiration (future: Edge Function)
- Analytics events for trial expiration (future: Edge Function or trigger)
- Re-trial offers (future: different subscription status)
- Grace period before expiration (MVP: hard cutoff at midnight UTC Day 8)

---

## Dependencies

| Dependency | Requirement |
|------------|-------------|
| Supabase Pro plan | Required for `pg_cron` extension |
| Superuser access | Required to `CREATE EXTENSION pg_cron` |

---

## Rollback Plan

If issues arise:
1. Disable cron jobs: `SELECT cron.unschedule('expire-trials-morning'); SELECT cron.unschedule('expire-trials-evening');`
2. Columns are additive; no data loss if migration reverted
3. Flutter app handles missing `trial_ends_at` gracefully (computes from `start_date`)
