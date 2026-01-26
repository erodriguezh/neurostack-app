## Phase 6: Trial Expiration Cronjob (Supabase Backend)

**Spec:** `docs/specs/20260122150000_spec_trial_expiration_cronjob.md`
**Investigation:** `docs/investigations/20260122180000_investigation_trial_expiration_race_condition.md`

---

### 6.1 Migration: Add columns + CHECK constraint + update trigger [DONE]

**New file:** `supabase/migrations/20260123092258_trial_expiration_columns.sql`

**Schema changes:**
- Add CHECK constraint for `subscription_status` (fixing undocumented enum):
    ```sql
    ALTER TABLE public.users
    ADD CONSTRAINT chk_subscription_status
    CHECK (subscription_status IN ('trial', 'free', 'premiumMonthly', 'premiumAnnual', 'expired', 'grace'));
    ```
- Update comment to match:
    ```sql
    COMMENT ON COLUMN public.users.subscription_status IS
      'Enum stored as text: trial, free, premiumMonthly, premiumAnnual, expired, grace';
    ```
- Add `trial_ends_at timestamptz NULL` column to `public.users`
    - Ref: `supabase/migrations/20251204192228_initial_schema.sql:103-110` (users table)
- Add `trial_expired_at timestamptz NULL` column to `public.users`
    - Audit timestamp for cron processing
- Add partial index for cron query performance:
    ```sql
    CREATE INDEX idx_users_trial_expiration
    ON public.users (trial_ends_at)
    WHERE subscription_status = 'trial' AND trial_expired_at IS NULL;
    ```

**Backfill existing users:**
```sql
UPDATE public.users
SET trial_ends_at = (trial_period->>'start_date')::timestamptz + INTERVAL '7 days'
WHERE trial_period IS NOT NULL
  AND trial_ends_at IS NULL;
```
- Ref: `supabase/migrations/20251230160000_auth_trigger_and_rls.sql:21` (trial_period JSONB structure)

**Update auth trigger:**
- Modify `handle_new_user()` to compute `trial_ends_at` on signup:
    ```sql
    trial_ends_at = new.created_at + INTERVAL '7 days'
    ```
- Ref: `supabase/migrations/20251230160000_auth_trigger_and_rls.sql:5-28` (existing trigger)

---

### 6.2 Migration: Cron function + schedule [DONE]

**New file:** `supabase/migrations/20260123113429_trial_expiration_cron.sql`

**Create function:**
```sql
CREATE OR REPLACE FUNCTION public.expire_trials()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  expired_count integer;
BEGIN
  UPDATE public.users
  SET subscription_status = 'free',
      trial_expired_at = NOW()
  WHERE subscription_status = 'trial'
    AND trial_expired_at IS NULL
    AND trial_ends_at < NOW();

  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;
```

**Schedule with pg_cron:**
- Enable `pg_cron` extension (requires Supabase Pro)
- Schedule 2x daily: `03:17 UTC` and `15:17 UTC` (offset minutes to avoid thundering herd)
- Job names: `neurostack-expire-trials-morning`, `neurostack-expire-trials-evening`
    ```sql
    SELECT cron.schedule('neurostack-expire-trials-morning', '17 3 * * *', 'SELECT public.expire_trials()');
    SELECT cron.schedule('neurostack-expire-trials-evening', '17 15 * * *', 'SELECT public.expire_trials()');
    ```

---

### 6.3 Flutter: Update TrialPeriod domain [DONE]

**File:** `lib/features/user/domain/value_objects/trial_period.dart`

**Changes:**
- Change `endDate` from computed getter to stored field
    - Ref: `lib/features/user/domain/value_objects/trial_period.dart:41-42` (current getter)
- Update `@internal` factory to accept `endDate` parameter:
    ```dart
    @internal
    const factory TrialPeriod({
      required DateTime startDate,
      required DateTime endDate,
    }) = _TrialPeriod;
    ```
- Keep `TrialPeriod.startNow()` — computes end date for NEW trials
    - Ref: `lib/features/user/domain/value_objects/trial_period.dart:33` (existing factory)
- Keep `TrialPeriod.fromStartDate()` — computes end date (backwards compat)
    - Ref: `lib/features/user/domain/value_objects/trial_period.dart:37-38` (existing factory)
- Add `TrialPeriod.fromDates()` — **only safe constructor for DB hydration**:
    ```dart
    /// Creates a trial period with explicit dates from database.
    /// This is the ONLY safe constructor for DB hydration.
    /// Use [startNow] or [fromStartDate] for creating new trials.
    factory TrialPeriod.fromDates({
      required DateTime startDate,
      required DateTime endDate,
    }) => TrialPeriod(startDate: startDate, endDate: endDate);
    ```

**Invariant preserved:**
- **INV-M2:** Trial duration = 7 days (computed on create, stored on read)

---

### 6.4 Flutter: Update TrialPeriodDto [DONE]

**File:** `lib/features/user/data/dtos/trial_period_dto.dart`

**Changes:**
- Add `endDate` field to mirror domain needs:
    ```dart
    const factory TrialPeriodDto({
      @JsonKey(name: 'start_date', fromJson: _stringFromJson)
      required String startDate,
      @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson)
      String? endDate,
    }) = _TrialPeriodDto;
    ```
- Update `toDomain()` to use both dates:
    ```dart
    Either<DomainFailure, TrialPeriod> toDomain() {
      try {
        final parsedStartDate = DateTime.parse(startDate);
        final parsedEndDate = endDate != null
            ? DateTime.parse(endDate!)
            : parsedStartDate.add(const Duration(days: TrialPeriod.trialDurationDays));
        return right(TrialPeriod.fromDates(
          startDate: parsedStartDate,
          endDate: parsedEndDate,
        ));
      } catch (e) {
        return left(DomainFailure(
          code: 'Dto.InvalidDateFormat',
          message: 'Failed to parse trial dates: $e',
        ));
      }
    }
    ```
- Update `fromDomain()` to include end date:
    ```dart
    factory TrialPeriodDto.fromDomain(TrialPeriod trial) {
      return TrialPeriodDto(
        startDate: trial.startDate.toIso8601String(),
        endDate: trial.endDate.toIso8601String(),
      );
    }
    ```

---

### 6.5 Flutter: Update UserDto [DONE]

**File:** `lib/features/user/data/dtos/user_dto.dart`

**Changes:**
- Add `trialEndsAt` field as **denormalized query index** (not source of truth):
    ```dart
    @JsonKey(name: 'trial_ends_at', fromJson: _nullableDateTimeFromJson)
    DateTime? trialEndsAt, // For SQL queries only, not used in toDomain()
    ```
    - Ref: `lib/features/user/data/dtos/user_dto.dart:37` (sibling to `trialPeriod`)
- `toDomain()` reads **only from `trialPeriod`** (source of truth):
    - Ref: `lib/features/user/data/dtos/user_dto.dart:79-91` (current trial parsing)
    - No changes needed here — `TrialPeriodDto.toDomain()` handles fallback
- `fromDomain()` writes to both fields for consistency:
    ```dart
    trialEndsAt: user.trialPeriod?.endDate,
    ```
- Add helper:
    ```dart
    DateTime? _nullableDateTimeFromJson(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }
    ```

**Design note:** `trial_ends_at` column exists for efficient SQL queries (cron, analytics).
`trialPeriod` JSONB remains the source of truth per **INV-B6** (historical data preserved).

---

### 6.6 Run codegen [DONE]

**Command:** `dart run build_runner build --delete-conflicting-outputs`

**Files regenerated:**
- `lib/features/user/domain/value_objects/trial_period.freezed.dart`
- `lib/features/user/data/dtos/trial_period_dto.freezed.dart`
- `lib/features/user/data/dtos/trial_period_dto.g.dart`
- `lib/features/user/data/dtos/user_dto.freezed.dart`
- `lib/features/user/data/dtos/user_dto.g.dart`

---

### 6.7 Update tests [DONE]

**TrialPeriod tests:**
- **File:** `test/features/user/domain/value_objects/trial_period_test.dart`
- Add: `fromDates()` factory test — creates with explicit dates
- Add: `endDate` stored field test — verify not recomputed

**TrialPeriodDto tests:**
- **File:** `test/features/user/data/dtos/trial_period_dto_test.dart`
- Add: `toDomain()` with `end_date` present — uses DB value
- Add: `toDomain()` with `end_date` null — falls back to computed
- Add: `fromDomain()` round-trip — `endDate` serialized

**UserDto tests:**
- **File:** `test/features/user/data/dtos/user_dto_test.dart`
- Add: `trialEndsAt` serialization test — denormalized field written
- Add: `toDomain()` ignores `trialEndsAt` — uses `trialPeriod` only

**Test factories:**
- **File:** `test/factories/user_factory.dart`
- Update: `createTrialUser()` to accept optional `trialEndsAt` (if needed for DTO tests)

---

### 6.8 Flutter: Add TrialExpirationDecisionStore (Race Condition Fix) [DONE]

**Problem:** Users whose trial expires between cron runs see the modal repeatedly on every app launch.

**Solution:** Persist "decision resolved" state to SharedPreferences.

**New file:** `lib/paywall/data/trial_expiration_decision_store.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persists trial expiration decision state to prevent repeated modal display.
///
/// Key format: `trial_expired_resolved:<userId>:<trialStartDate.toIso8601String()>`
abstract interface class TrialExpirationDecisionStore {
  /// Returns true if the user has already resolved the trial expiration decision
  /// for this specific trial instance.
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  });

  /// Marks the trial expiration decision as resolved for this trial instance.
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  });
}

class SharedPrefsTrialExpirationDecisionStore implements TrialExpirationDecisionStore {
  SharedPrefsTrialExpirationDecisionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'trial_expired_resolved';

  String _key(String userId, DateTime trialStartDate) =>
      '$_keyPrefix:$userId:${trialStartDate.toIso8601String()}';

  @override
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    return _prefs.getBool(_key(userId, trialStartDate)) ?? false;
  }

  @override
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  }) async {
    await _prefs.setBool(_key(userId, trialStartDate), true);
  }
}
```

**Modified file:** `lib/config/locator_config.dart`
- Register `TrialExpirationDecisionStore`:
    ```dart
    locator.registerLazySingleton<TrialExpirationDecisionStore>(
      () => SharedPrefsTrialExpirationDecisionStore(locator<SharedPreferences>()),
    );
    ```

**Modified file:** `lib/home/home_view_model.dart`
- Add dependency:
    ```dart
    final TrialExpirationDecisionStore? _trialExpirationDecisionStore;
    ```
- Update `_maybeTriggerExpiredModal()` to check store before showing:
    ```dart
    Future<void> _maybeTriggerExpiredModal(User user) async {
      if (_hasShownExpiredModal) return;

      final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
          (user.trialPeriod?.isExpired(DateTime.now()) ?? false);
      final isPremiumExpired = user.subscriptionStatus == SubscriptionStatus.expired;

      if (!isTrialExpired && !isPremiumExpired) return;

      // Check if already resolved (persisted across app restarts)
      if (isTrialExpired && user.trialPeriod != null) {
        final alreadyResolved = await _trialExpirationDecisionStore?.isResolved(
          userId: user.id,
          trialStartDate: user.trialPeriod!.startDate,
        ) ?? false;
        if (alreadyResolved) return;
      }

      _hasShownExpiredModal = true;
      state.value = state.value.copyWith(showTrialExpiredModal: true);
    }
    ```
- Add method to mark decision resolved:
    ```dart
    Future<void> markTrialExpiredDecisionResolved() async {
      final user = state.value.user;
      if (user?.trialPeriod == null) return;

      await _trialExpirationDecisionStore?.markResolved(
        userId: user!.id,
        trialStartDate: user.trialPeriod!.startDate,
      );
    }
    ```

**Modified file:** `lib/home/home_view.dart`
- Inject store into ViewModel
- Call `markTrialExpiredDecisionResolved()` after user makes decision:
    ```dart
    switch (choice) {
      case TrialExpiredChoice.keepEverything:
        await _viewModel.markTrialExpiredDecisionResolved();
        _viewModel.goToPaywall();
      case TrialExpiredChoice.continueWithFree:
        await _viewModel.markTrialExpiredDecisionResolved();
        _viewModel.handleUseFreeTier();
      case null:
        break;
    }
    ```

**New test file:** `test/paywall/data/trial_expiration_decision_store_test.dart`
- Test: `isResolved` returns false initially
- Test: `markResolved` then `isResolved` returns true
- Test: Different trial instances are independent
- Test: Different users are independent

---

### 6.9 Verification steps [DONE - Flutter only]

**Backend:** (Manual - requires Supabase Pro)
1. Apply migrations to local Supabase: `supabase db reset`
2. Verify columns exist: `SELECT trial_ends_at, trial_expired_at FROM users LIMIT 1;`
3. Verify CHECK constraint: `INSERT INTO users (id, subscription_status) VALUES (gen_random_uuid(), 'invalid');` should fail
4. Create test user, verify `trial_ends_at` computed by trigger
5. Manually run `SELECT expire_trials();` on expired trial user
6. Verify cron jobs scheduled: `SELECT * FROM cron.job WHERE jobname LIKE 'neurostack-%';`

**Flutter:**
1. Run codegen: `dart run build_runner build --delete-conflicting-outputs`
2. Run analyze: `flutter analyze`
3. Run tests: `flutter test test/features/user/ test/paywall/`
4. Manual test: fetch user with `trial_ends_at` column, verify `TrialPeriod.endDate` matches
5. Manual test: trigger modal, force-quit, reopen — modal should NOT reappear

---

### 6.10 Monitoring queries (for ops)

```sql
-- Check cron job status
SELECT * FROM cron.job WHERE jobname LIKE 'neurostack-expire-trials%';

-- Recent expirations
SELECT id, trial_ends_at, trial_expired_at
FROM public.users
WHERE trial_expired_at IS NOT NULL
ORDER BY trial_expired_at DESC LIMIT 20;

-- Pending expirations (should be 0 after cron runs)
SELECT COUNT(*) FROM public.users
WHERE subscription_status = 'trial'
  AND trial_expired_at IS NULL
  AND trial_ends_at < NOW();
```

---

### 6.11 Rollback plan

If issues arise:
1. Unschedule cron jobs (extension stays for other jobs):
    ```sql
    SELECT cron.unschedule('neurostack-expire-trials-morning');
    SELECT cron.unschedule('neurostack-expire-trials-evening');
    ```
2. Columns are additive; no data loss if migration reverted
3. Flutter app handles missing `trial_ends_at` gracefully (computes from `start_date`)
4. `TrialExpirationDecisionStore` can be disabled by returning `false` from `isResolved()`

---

## File Summary

### New Files
| File | Purpose |
|------|---------|
| `supabase/migrations/YYYYMMDDHHMMSS_trial_expiration_columns.sql` | Schema changes + backfill + trigger update |
| `supabase/migrations/YYYYMMDDHHMMSS_trial_expiration_cron.sql` | Cron function + schedule |
| `lib/paywall/data/trial_expiration_decision_store.dart` | SharedPreferences-backed decision persistence |
| `test/paywall/data/trial_expiration_decision_store_test.dart` | Unit tests |

### Modified Files
| File | Changes |
|------|---------|
| `lib/features/user/domain/value_objects/trial_period.dart` | `endDate` as field, `fromDates()` factory |
| `lib/features/user/data/dtos/trial_period_dto.dart` | Add `endDate` field |
| `lib/features/user/data/dtos/user_dto.dart` | Add `trialEndsAt` denormalized field |
| `lib/home/home_view_model.dart` | Inject store, gate modal, add `markResolved()` |
| `lib/home/home_view.dart` | Inject store, call `markResolved()` on decision |
| `lib/config/locator_config.dart` | Register `TrialExpirationDecisionStore` |
| `test/factories/user_factory.dart` | Update for new trial structure |

---

## Review Changes Applied

From Carmack-level plan review (2026-01-22):

1. ✅ **Schema:** Added CHECK constraint for `subscription_status` enum
2. ✅ **Schema:** Fixed documentation comment to include `trial` status
3. ✅ **Race condition:** Added `TrialExpirationDecisionStore` (Option D from investigation)
4. ✅ **Backfill:** Added WHERE clause for `trial_period IS NOT NULL`
5. ✅ **Index:** Optimized to single column with full predicate in WHERE
6. ✅ **expire_trials():** Explicit `RETURNS integer` type
7. ✅ **TrialPeriod:** Documented `fromDates()` as only safe DB hydration constructor
8. ✅ **Test path:** Fixed to `test/factories/user_factory.dart`
9. ✅ **TrialPeriodDto:** Expanded to include `endDate`
10. ✅ **UserDto:** `trial_ends_at` as denormalized index, `toDomain()` uses `trialPeriod` only
11. ✅ **Cron naming:** Prefixed with `neurostack-`
12. ✅ **Rollback:** Only unschedule jobs, don't drop extension
