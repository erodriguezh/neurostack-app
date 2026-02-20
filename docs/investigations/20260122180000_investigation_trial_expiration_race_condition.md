# DEPRECATED

> **This investigation is deprecated.** The race condition described here was resolved
> by the RevenueCat event-driven architecture and client-side transition detection.
> The pg_cron approach was removed entirely. Retained for historical context only.

# Investigation: Trial Expiration Modal Race Condition

**Created:** 2026-01-22
**Status:** Deprecated
**References:**
- Modal Spec: `docs/specs/20260120120000_spec_trial_expiration_modal.md`
- Cronjob Spec: `docs/specs/20260122150000_spec_trial_expiration_cronjob.md`
- HomeViewModel: `lib/home/home_view_model.dart`
- HomeView: `lib/home/home_view.dart`
- TrialPeriod: `lib/features/user/domain/value_objects/trial_period.dart`

---

## Summary

The current design has a race condition where users whose trial expires between cron runs (scheduled at 03:17 and 15:17 UTC) will see the trial expiration modal **repeatedly on every app launch** until either the cron runs or they make a choice. This investigation analyzes the root cause and recommends a solution.

---

## Symptoms

| Scenario | User Experience |
|----------|-----------------|
| Trial expires at 10:00 UTC, user opens app at 10:30 | Modal shows |
| User force-quits without choosing, reopens at 11:00 | Modal shows **again** |
| User force-quits again, reopens at 12:00 | Modal shows **again** |
| Cron runs at 15:17 UTC, user opens app at 15:30 | No modal (silently transitioned to free) |

---

## Investigation Log

### Phase 1: Understanding Client-Side Logic

**Hypothesis:** The modal repeat is caused by in-memory-only session flag.

**Findings:**
- `HomeViewModel._hasShownExpiredModal` (line 67) is an in-memory boolean
- Resets to `false` on every app launch (new ViewModel instance)
- `isTrialOrPremiumExpired()` (lines 250-261) checks:
  ```dart
  final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
      (user.trialPeriod?.isExpired(now) ?? false);
  ```

**Evidence:**
- `lib/home/home_view_model.dart:67` - `bool _hasShownExpiredModal = false;`
- `lib/home/home_view_model.dart:250-256` - `isTrialOrPremiumExpired()` method

**Conclusion:** **Confirmed.** The guard is per-session only, not persisted.

---

### Phase 2: Understanding Cron Behavior

**Hypothesis:** Cron transition removes the modal trigger by changing status to `free`.

**Findings:**
- Cron updates `subscription_status = 'free'` when `trial_ends_at < NOW()`
- After cron runs, client sees `status == free`, so `isTrialExpired` check fails
- Users who never open the app during the gap get **silent transition** (no modal ever)

**Evidence:**
- `docs/specs/20260122150000_spec_trial_expiration_cronjob.md:45-54` - UPDATE action
- `lib/home/home_view_model.dart:252` - `subscriptionStatus == SubscriptionStatus.trial` check

**Conclusion:** **Confirmed.** Cron creates two distinct user experiences:
1. Users who open app before cron: see modal (possibly repeatedly)
2. Users who open app after cron: no modal (silent transition)

---

### Phase 3: Analyzing Design Options

#### Option A: Keep Current Logic (Dual Trigger)

| Pros | Cons |
|------|------|
| No changes needed | Modal repeats until cron or choice |
| Cron acts as cleanup | Inconsistent UX (some users see modal, some don't) |

**Verdict:** Does not meet "show only once" requirement.

---

#### Option B: Remove Client-Side Trigger (Cron Only)

| Pros | Cons |
|------|------|
| Simple, no race condition | Users never see modal (silent transition) |
| Consistent experience | Loses "required decision point" UX |

**Verdict:** Does not meet "immediate trigger" requirement.

---

#### Option C: Add Server-Side Acknowledgment Flag

**Schema addition:**
```sql
trial_expiration_acknowledged_at timestamptz null
```

**Modal trigger becomes:**
```dart
// Show modal only if trial ended AND not yet acknowledged
final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
    (user.trialPeriod?.isExpired(now) ?? false) &&
    user.trialExpirationAcknowledgedAt == null;
```

| Pros | Cons |
|------|------|
| Works across devices | Requires migration + DTO changes |
| Durable "once only" | More complex |
| Works with or without cron | Backend dependency |

**Verdict:** Best for cross-device durability, but adds complexity.

---

#### Option D: Add Client-Side Persistence (SharedPreferences)

**New interface:**
```dart
abstract interface class TrialExpirationDecisionStore {
  Future<bool> isResolved({
    required String userId,
    required DateTime trialStartDate,
  });
  Future<void> markResolved({
    required String userId,
    required DateTime trialStartDate,
  });
}
```

**Key format:** `trial_expired_resolved:<userId>:<trialStartDate.toIso8601String()>`

| Pros | Cons |
|------|------|
| Simple implementation | Not durable across reinstalls |
| Works offline | Not cross-device |
| No backend changes | Local storage only |

**Verdict:** Sufficient for single-device UX, simple to implement.

---

#### Option E: Increase Cron Frequency

| Pros | Cons |
|------|------|
| Reduces gap to ~1 hour | Still not immediate |
| No code changes | Doesn't work offline |
| | Users in gap still repeat |

**Verdict:** Complementary only, not a solution.

---

## Root Cause

The race condition exists because:

1. **Client-side expiration detection** is immediate (computed from `trialPeriod.endDate`)
2. **Server-side status transition** is delayed (cron runs 2x daily)
3. **"Already shown" guard** is in-memory only (resets on app restart)

The fundamental issue is that the "decision completed" state is not persisted anywhere.

---

## Recommendations

### Recommended Solution: Option D (Client-Side Persistence)

**Why this option:**
- Meets "immediate trigger" requirement (client computes expiration)
- Meets "once only per relaunch" requirement (persisted to SharedPreferences)
- Works offline
- Minimal complexity (no backend changes)
- Sufficient for MVP (cross-device not required initially)

**Implementation summary:**

1. **Create `TrialExpirationDecisionStore`** - SharedPreferences-backed store
2. **Inject into `HomeViewModel`** - Check before triggering modal
3. **Mark resolved on decision** - After "Continue with Free" or successful subscription
4. **Key by trial instance** - `userId + trialStartDate` ensures new trials show modal

### Optional Enhancement: Add Server-Side Flag

If cross-device "once only" becomes a requirement:
- Add `trial_expiration_acknowledged_at` column
- Update when user makes decision
- Use as authoritative source, fall back to local store when offline

---

## Decision Matrix

| Requirement | Option A | Option B | Option C | Option D | Option E |
|-------------|----------|----------|----------|----------|----------|
| Immediate trigger | ✅ | ❌ | ✅ | ✅ | ❌ |
| Show once per relaunch | ❌ | ✅ | ✅ | ✅ | ❌ |
| Works offline | ✅ | ❌ | ⚠️ | ✅ | ❌ |
| Cross-device durability | ❌ | ✅ | ✅ | ❌ | ❌ |
| Minimal complexity | ✅ | ✅ | ❌ | ✅ | ✅ |

**Legend:** ✅ = Meets, ❌ = Does not meet, ⚠️ = Partial

---

## Files to Modify (Option D Implementation)

### New Files

| File | Purpose |
|------|---------|
| `lib/paywall/data/trial_expiration_decision_store.dart` | SharedPreferences-backed store |
| `test/paywall/data/trial_expiration_decision_store_test.dart` | Unit tests |

### Modified Files

| File | Changes |
|------|---------|
| `lib/home/home_view_model.dart` | Inject store, gate `_maybeTriggerExpiredModal()`, add `markTrialExpiredDecisionResolved()` |
| `lib/home/home_view.dart` | Call `markResolved` after decision |
| `lib/config/locator_config.dart` | Register `TrialExpirationDecisionStore` |

---

## Spec Updates Required

### Trial Expiration Modal Spec

Add to "Trigger Conditions" section:
```markdown
| Condition | Source |
|-----------|--------|
| Decision not yet resolved for this trial | `TrialExpirationDecisionStore.isResolved()` |
```

Add new section:
```markdown
## Decision Resolution

The modal trigger includes a persistence guard to ensure "once only" behavior:

| Event | Action |
|-------|--------|
| "Continue with Free" selected | Mark resolved immediately |
| "Keep Everything" → Subscribe success | Mark resolved after refresh |
| App reinstall | Decision store cleared, modal may show again |

**Store key format:** `trial_expired_resolved:<userId>:<trialStartDate>`
```

### Trial Expiration Cronjob Spec

Add note under "App Launch (Post-Expiration)" data flow:
```markdown
**Note:** If user has already resolved the decision via the modal, the cron transition
is purely for data consistency. The modal will not re-show because the decision store
already has a resolution record for that trial instance.
```

---

## Preventive Measures

1. **Document the "decision completed" concept** in ubiquitous language
2. **Add integration test** for relaunch scenario (mock SharedPreferences)
3. **Consider cross-device requirement** before shipping to production
4. **Monitor cron job health** to ensure silent transitions work as fallback