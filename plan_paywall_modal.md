# Implementation Plan: RevenueCat Paywall Integration

**Spec:** `docs/specs/20260123220000_spec_paywall_modal.md`
**UI Design:** `docs/best_practices/design/screen-prompts/06-paywall-modal.md`

---

## Design Principles

1. **RevenueCat is the authority** for entitlement state (fast, works offline with cache)
2. **Supabase stores a durable mirror** for analytics/server logic via webhook
3. **Webhook is the DB writer** - client does NOT write subscription state to Supabase
4. **Safe intermediate states** - each phase can be deployed independently without breaking the app
5. **Constructor injection** - services receive dependencies via constructor, not `locator<>` calls
6. **SDK types at boundary** - internal app-owned models expose state; SDK types stay in adapter layer
7. **Singletons for SDK wrappers** - RevenueCat services are app-lifetime singletons (not per-resolve factories)
8. **Time as dependency** - pure resolvers accept `DateTime now` param; services may inject `Clock` (choose per layer for testability)
9. **Unknown vs None** - distinguish "RC unavailable" from "RC says no entitlement"
10. **User-scoped snapshots** - snapshot is only authoritative when `appUserId == currentUser.id`
11. **Never clobber known state** - don't overwrite known entitlement with transient null/error

---

## Supported Platforms

| Platform | purchases_flutter | purchases_ui_flutter | Notes |
|----------|------------------|---------------------|-------|
| iOS | ✅ Full | ✅ Full | Primary target |
| Android | ✅ Full | ✅ Full | Primary target |
| macOS | ✅ Full | ⚠️ Verify | May need custom paywall UI |
| Web | ❌ Stub | ❌ N/A | No-op client returns null |

**macOS support:** Verify `purchases_ui_flutter` supports macOS before implementation. If not supported:
- Use `purchases_flutter` for purchase + entitlement (works)
- Build custom paywall UI for macOS (or share with web fallback)

**Web builds:** Use conditional imports to provide a no-op `RevenueCatClient` that returns `null` (unknown) for web. The resolver treats `null` as "fallback to Supabase DB status" - this prevents incorrectly downgrading premium users who happen to use web.

---

## New User Flow Summary

```
1. Install app → none (onboarding/auth only)
2. Register → free (2 protocol limit)
3. Upgrade → 7-day trial starts (requires payment method)
4. 24h before trial ends → soft reminder
5. Trial expires → Trial Expiration Modal
6. Choose free → free (2 protocol limit)
```

---

## Canonical Constants (Define Once, Reference Everywhere)

```dart
// lib/paywall/paywall_constants.dart

/// Entitlement ID (must match RevenueCat dashboard exactly)
const kNeurostackProEntitlementId = 'Neurostack Pro';

/// Product IDs (must match App Store Connect / Google Play Console)
const kProductMonthly = 'neurostack_monthly';  // $7.99/mo, 7-day trial
const kProductYearly = 'neurostack_yearly';    // $59.99/yr, 7-day trial
```

---

## Phase 0: Manual Setup & Copy Alignment (BLOCKER)

### 0.1 App Store Connect / Google Play Console [DONE]
- [ ] Create subscription products:
  - `neurostack_monthly` ($7.99/mo, 7-day trial)
  - `neurostack_yearly` ($59.99/yr, 7-day trial)

### 0.2 RevenueCat Dashboard [DONE]
- [ ] Create project and add App Store / Play Store apps
- [ ] Configure products and create Offering
- [ ] Design paywall in Paywall Builder
- [ ] Create entitlement "Neurostack Pro" (exact casing matters)
- [ ] Note **per-platform** API keys for environment config

### 0.3 Update Onboarding Copy (CRITICAL - contradicts new model) [DONE]
- **File:** `lib/features/onboarding/presentation/widgets/screens/offer_screen.dart`
- **Changes:**
  - Replace "No credit card required" (RevenueCat trials require payment method) for something that makes sense to the new payment model strategy and is appealing to a new user.
  - Change "Start my free trial" → "Start free" or "Continue"
  - Add disclaimer if keeping trial language: "7-day trial with subscription (payment method required)"

### 0.4 Update Ubiquitous Language [DONE]
- **File:** `docs/ubiquitous-language.md`
- **Changes:**
  - Mark INV-U3 as DEPRECATED: "Trial MUST auto-activate on first app launch"
  - Mark INV-M3 as DEPRECATED: "Premium Trial MUST NOT require credit card"
  - Update INV-M2: "Premium Trial MUST last exactly 7 days **from subscription start**"
  - Add INV-P1: "Paywall dismissal without purchase returns to previous screen"
  - Add INV-P2: "Successful purchase updates UI immediately via RevenueCat (optimistic)"
  - Add INV-P3: "Webhook is source of truth for DB; client uses RevenueCat for UI gating"
  - Add INV-P4: "Trial reminder shown max once per 24h period"
  - Add INV-P5: "`app_user_id` must match Supabase `auth.uid`"
  - Add INV-P6: "New users MUST start with `free` status (not `trial`)"

---

## Phase 1: Backend - Make New Users `free` (BLOCKER)

This phase ensures the DB creates users correctly BEFORE any Flutter changes.

### 1.1 Update `handle_new_user()` Trigger (CRITICAL) [DONE]
- **New File:** `supabase/migrations/20260127194643_revenuecat_new_users_free.sql`
- **Rationale:** Current trigger creates users as `trial`; must change to `free` to match INV-P6
- **Changes:**
  ```sql
  -- Update handle_new_user to create users as 'free' instead of 'trial'
  -- RevenueCat manages trials, not Supabase
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
      'free',              -- Changed from 'trial'
      NULL,                -- No longer used
      NULL,                -- No longer used
      '[]'::jsonb,
      false,
      new.created_at
    );
    RETURN new;
  END;
  $$;
  ```

### 1.2 Add Webhook Bookkeeping Columns (REQUIRED for Phase 9) [DONE]
- **New File:** `supabase/migrations/20260127202238_revenuecat_webhook_columns.sql`
- **Changes:**
  ```sql
  -- Add columns for webhook idempotency and conflict resolution
  -- REQUIRED: Phase 9 webhook depends on these columns
  ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_updated_at timestamptz NULL;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_source text NULL;
  ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_last_event_id text NULL;
  ```

### 1.3 Fix Enum Mismatch (CRITICAL) [DONE]
- **File:** `lib/features/user/domain/enums/subscription_status.dart`
- **Problem:** DB CHECK constraint includes `grace` but Dart enum doesn't.
- **Actual:** `grace` enum already existed. Updated `isPremium` getter to include `grace`.
- **Changes:**
  2. Add `grace` for billing issues:
     ```dart
     /// Billing issue, payment retry in progress (RevenueCat grace period)
     grace(protocolLimit: null, canAccessPremium: true),
     ```
  3. Update `isPremium` getter to include lifetime and grace:
     ```dart
     bool get isPremium => this == premiumMonthly ||
                           this == premiumAnnual ||
                           this == grace;  // Still has access during grace
     ```

### 1.4 Update DB CHECK Constraint [DONE - Already Exists]
- **New File:** Not needed - constraint already exists in `20260123092258_trial_expiration_columns.sql`
- **Note:** Existing CHECK includes `grace` already
- **Original Changes (not applied):**
  ```sql
  -- Add grace to subscription_status CHECK constraint
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_subscription_status_check;
  ALTER TABLE users ADD CONSTRAINT users_subscription_status_check CHECK (
    subscription_status IN ('free', 'trial', 'premiumMonthly', 'premiumAnnual', 'expired', 'grace')
  );
  ```

---

## Phase 2: SDK Setup & Configuration

### 2.2 Add Dependencies [DONE]
- **File:** `pubspec.yaml`
- **Changes:** Add `purchases_flutter` and `purchases_ui_flutter` (latest stable)
- **Command:** `flutter pub add purchases_flutter purchases_ui_flutter`
- **Actual:** Added `purchases_flutter: ^9.10.7` and `purchases_ui_flutter: ^9.10.7`

### 2.3 Create Internal Models (SDK Types at Boundary) [DONE]
- **New File:** `lib/paywall/domain/entitlement_snapshot.dart`
- **Purpose:** App-owned model replacing direct `CustomerInfo` usage
- **Pattern:** Simple immutable class (use @freezed only if codebase already uses it broadly)
- **CRITICAL:** Distinguish "RC unavailable/unknown" (`null`) from "RC says no entitlement" (`.none()`)
- **Interface:**
  ```dart
  /// Internal representation of RevenueCat entitlement state
  /// Keeps SDK types at the adapter boundary
  ///
  /// IMPORTANT: Use nullable EntitlementSnapshot? to distinguish:
  /// - null = RC unavailable (web stub, not configured, hard SDK failure) → fallback to DB
  ///   NOTE: Mobile SDK provides cached CustomerInfo offline, so offline ≠ null
  /// - EntitlementSnapshot.none() = RC says user has no entitlement → authoritative
  class EntitlementSnapshot {
    /// CRITICAL: Track which user this snapshot belongs to
    /// Only authoritative when appUserId == currentUser.id
    final String? appUserId;

    final bool hasProEntitlement;
    final bool isTrialPeriod;
    final bool isInGracePeriod;  // Billing issue, payment retry in progress
    final String? productId;
    final DateTime? expirationDate;
    final String? originalTransactionId;
    final DateTime? latestPurchaseDate;

    /// CRITICAL: Track last period type even when expired
    /// Needed to distinguish "trial expired → free" vs "paid expired → expired"
    final EntitlementPeriodType? lastPeriodType;

    const EntitlementSnapshot({
      required this.appUserId,
      required this.hasProEntitlement,
      required this.isTrialPeriod,
      required this.isInGracePeriod,
      required this.productId,
      required this.expirationDate,
      required this.originalTransactionId,
      required this.latestPurchaseDate,
      required this.lastPeriodType,
    });

    /// Known state: user has NEVER had entitlement
    /// Note: appUserId should be set to current user when constructing
    factory EntitlementSnapshot.none({required String appUserId}) =>
      EntitlementSnapshot(
        appUserId: appUserId,
        hasProEntitlement: false,
        isTrialPeriod: false,
        isInGracePeriod: false,
        productId: null,
        expirationDate: null,
        originalTransactionId: null,
        latestPurchaseDate: null,
        lastPeriodType: null,
      );

    /// Check if this snapshot belongs to the given user
    bool isForUser(String userId) => appUserId == userId;

    /// Was this a trial that expired? (for trial-expired modal)
    bool get wasTrialThatExpired =>
      !hasProEntitlement && lastPeriodType == EntitlementPeriodType.trial;

    /// Was this a paid subscription that expired? (for "resubscribe" UX)
    /// NOTE: "intro" is treated as paid (discounted paid period, not free trial)
    /// This maps churned intro users to "expired" status for "resubscribe" messaging
    bool get wasPaidThatExpired =>
      !hasProEntitlement && (
        lastPeriodType == EntitlementPeriodType.normal ||
        lastPeriodType == EntitlementPeriodType.intro
      );
  }

  /// Period types from RevenueCat
  /// - trial: Free trial period (7 days, no charge)
  /// - intro: Intro offer (discounted paid period - treated as "paid" for churn UX)
  /// - normal: Regular billing period
  enum EntitlementPeriodType { trial, intro, normal }

  /// Result of paywall presentation
  enum PaywallOutcome { purchased, cancelled, error }
  ```

### 2.4 Create RevenueCatClient Interface [DONE]
- **New File:** `lib/paywall/data/revenuecat_client.dart`
- **Pattern:** Interface for testability (tests use fake, prod uses SDK)
- **CRITICAL:** Return type must be nullable to distinguish "unknown" from "known none"
- **Interface:**
  ```dart
  abstract class RevenueCatClient {
    Future<void> configure(String apiKey);
    Future<void> logIn(String userId);
    Future<void> logOut();

    /// Returns null if RC unavailable (web stub, not configured, hard SDK failure)
    /// Returns EntitlementSnapshot if RC responded (may be .none() = no entitlement)
    /// NOTE: Mobile SDK provides cached CustomerInfo offline - offline ≠ null
    /// Only return null for true unavailability, not transient network issues
    Future<EntitlementSnapshot?> getEntitlementSnapshot();

    Future<PaywallOutcome> presentPaywall();

    /// Restore purchases (device change, reinstall, family sharing)
    /// CRITICAL for subscription correctness after launch
    Future<void> restorePurchases();

    /// Stream of entitlement changes (for real-time UI updates)
    /// Web stub: empty stream (never emits)
    Stream<EntitlementSnapshot> get entitlementChanges;
  }
  ```

### 2.5 Create RevenueCatClient Implementations [DONE]
- **New File:** `lib/paywall/data/revenuecat_client_mobile.dart`
  - Wraps `purchases_flutter` SDK
  - **CRITICAL:** Store `_currentUserId` set by `logIn()`, cleared by `logOut()`
  - Registers `Purchases.addCustomerInfoUpdateListener`
  - Maps `CustomerInfo` → `EntitlementSnapshot` using stored `_currentUserId`
  - If `_currentUserId` is null, don't emit from listener (or emit null)
  ```dart
  class RevenueCatClientMobile implements RevenueCatClient {
    String? _currentUserId;  // Track logged-in user for listener callbacks
    final _entitlementController = StreamController<EntitlementSnapshot>.broadcast();
    bool _listenerSetup = false;

    @override
    Future<void> configure(String apiKey) async {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      // CRITICAL: Setup listener exactly once during configure
      if (!_listenerSetup) {
        _setupListener();
        _listenerSetup = true;
      }
    }

    @override
    Future<void> logIn(String userId) async {
      // CRITICAL: Set _currentUserId AFTER successful logIn to prevent
      // listener from emitting snapshots for a failed identification
      await Purchases.logIn(userId);
      _currentUserId = userId;
    }

    @override
    Future<void> logOut() async {
      _currentUserId = null;
      await Purchases.logOut();
    }

    void _setupListener() {
      Purchases.addCustomerInfoUpdateListener((info) {
        // CRITICAL: Only emit if we have an identified user
        if (_currentUserId != null) {
          final snapshot = _mapCustomerInfo(info, _currentUserId!);
          if (snapshot != null) {
            _entitlementController.add(snapshot);
          }
        }
      });
    }
  }
  ```
  - **CRITICAL:** Read BOTH active AND all entitlements to detect "trial ended" state
- **CRITICAL:** Verify actual SDK field names for period type and billing issue (varies by SDK version)
    ```dart
    EntitlementSnapshot? _mapCustomerInfo(CustomerInfo info, String identifiedUserId) {
      // CRITICAL: Use the identified user ID we passed to logIn(), NOT originalAppUserId
      // originalAppUserId is the anonymous/original ID, not the current logged-in user
      // We already know who we identified as, so use that directly
      final appUserId = identifiedUserId;

      // Check active first
      final active = info.entitlements.active[kNeurostackProEntitlementId];
      if (active != null) {
        // VERIFY: actual SDK field for period type (may be different)
        final periodType = _mapPeriodType(active.periodType);
        // VERIFY: actual SDK field for billing issue/grace (may be separate field)
        final isGrace = active.billingIssueDetectedAt != null;

        return EntitlementSnapshot(
          appUserId: appUserId,
          hasProEntitlement: true,
          isTrialPeriod: periodType == EntitlementPeriodType.trial,
          isInGracePeriod: isGrace,
          productId: active.productIdentifier,
          expirationDate: active.expirationDate,
          // NOTE: originalTransactionId intentionally left null
          // Decision store uses expirationDate-based key as fallback (Phase 7.1)
          // Only set this if you find a confirmed stable SDK field
          originalTransactionId: null,
          latestPurchaseDate: active.latestPurchaseDate,
          lastPeriodType: periodType,
        );
      }

      // No active entitlement - check if they HAD one (for expired modal)
      final all = info.entitlements.all[kNeurostackProEntitlementId];
      if (all != null) {
        // CRITICAL: Preserve lastPeriodType for "trial expired vs paid expired"
        final lastPeriodType = _mapPeriodType(all.periodType);

        return EntitlementSnapshot(
          appUserId: appUserId,
          hasProEntitlement: false,
          isTrialPeriod: false,
          isInGracePeriod: false,
          productId: all.productIdentifier,
          expirationDate: all.expirationDate,
          // VERIFY: same transaction ID field as above
          originalTransactionId: null,  // Populate from actual SDK field
          latestPurchaseDate: all.latestPurchaseDate,
          lastPeriodType: lastPeriodType,  // CRITICAL for UX decision
        );
      }

      return EntitlementSnapshot.none(appUserId: appUserId);
    }

    EntitlementPeriodType? _mapPeriodType(dynamic sdkPeriodType) {
      // VERIFY: actual SDK enum values - this is pseudocode
      if (sdkPeriodType == null) return null;  // Unknown - don't guess

      final typeStr = sdkPeriodType.toString().toLowerCase();
      if (typeStr.contains('trial')) return EntitlementPeriodType.trial;
      if (typeStr.contains('intro')) return EntitlementPeriodType.intro;
      if (typeStr.contains('normal')) return EntitlementPeriodType.normal;

      // CRITICAL: Return null for unknown types, not a default
      // Downstream logic must treat null as "don't know if trial or paid"
      return null;
    }
    ```
- **New File:** `lib/paywall/data/revenuecat_client_stub.dart`
  - No-op implementation for web
  - `getEntitlementSnapshot()` returns `null` (NOT `.none()`) to indicate "unknown"
  - Stream emits nothing (empty stream)
- **New File:** `lib/paywall/data/revenuecat_client_factory.dart`
  - Uses conditional imports to return appropriate implementation
  ```dart
  RevenueCatClient createRevenueCatClient() {
    // Uses conditional import: revenuecat_client_mobile.dart vs stub
    return RevenueCatClientImpl();
  }
  ```

### 2.6 Create RevenueCatService [DONE]
- **New File:** `lib/paywall/data/revenuecat_service.dart`
- **Pattern:** Follow `SessionSyncService` at `lib/features/session/data/services/session_sync_service.dart`
- **Constructor Injection:** Receives `RevenueCatClient` via constructor
- **CRITICAL:** Use nullable ValueNotifier to distinguish "unknown" from "known none"
- **Responsibilities:**
  - Initialize SDK with API key via `String.fromEnvironment('REVENUECAT_API_KEY')` (loaded from `env/env.json` at build time)
  - Expose `entitlementSnapshot` as `ValueNotifier<EntitlementSnapshot?>` (null = unknown)
  - `identify(userId)` / `logout()` methods - **queue until init() completes** (prevents race)
  - `presentPaywall()` method with **guard against multiple presentations**
  - `refreshEntitlement()` method for explicit refresh after paywall
  - Internal `_isPresenting` flag to prevent duplicate paywall UI
  - Internal `_initCompleter` to gate identify/logout until SDK configured
  ```dart
  class RevenueCatService {
    final RevenueCatClient _client;
    final ValueNotifier<EntitlementSnapshot?> entitlementSnapshot;  // null = unknown
    bool _isPresenting = false;
    bool _initStarted = false;  // CRITICAL: Idempotency guard
    StreamSubscription? _entitlementSubscription;
    final Completer<void> _initCompleter = Completer<void>();
    String? _identifiedUserId;  // Track which user we're identified as

    RevenueCatService(this._client)
      : entitlementSnapshot = ValueNotifier(null);  // Start as unknown

    /// Safe to call multiple times - subsequent calls return same future
    Future<void> init() async {
      // CRITICAL: Idempotency - don't double-subscribe or double-complete
      if (_initStarted) {
        return _initCompleter.future;
      }
      _initStarted = true;

      try {
        // 1. Select platform-appropriate API key
        final apiKey = _selectPlatformKey();

        // 2. Configure SDK (MUST complete before anything else)
        await _client.configure(apiKey);

        // 3. Subscribe to entitlement changes for real-time UI updates
        // CRITICAL: Only update if for identified user (ignore anonymous emissions)
        _entitlementSubscription = _client.entitlementChanges.listen((snapshot) {
          if (_identifiedUserId != null && snapshot.appUserId == _identifiedUserId) {
            _updateSnapshotIfBetter(snapshot);
          }
        });

        // 4. ONLY complete after configure() succeeds
        _initCompleter.complete();
      } catch (e) {
        _initCompleter.completeError(e);
        rethrow;
      }
    }

    /// CRITICAL: Never clobber known state with null/error
    void _updateSnapshotIfBetter(EntitlementSnapshot? newSnapshot) {
      if (newSnapshot != null) {
        entitlementSnapshot.value = newSnapshot;
      }
      // If newSnapshot is null, keep existing (don't downgrade known → unknown)
    }

    /// Queues until init() completes to prevent race conditions
    /// CRITICAL: Seeds initial snapshot after identify
    Future<void> identify(String userId) async {
      await _initCompleter.future;  // Wait for SDK to be configured
      await _client.logIn(userId);
      _identifiedUserId = userId;

      // Seed initial snapshot after identify (don't rely on stream)
      await refreshEntitlement();
    }

    Future<void> logout() async {
      await _initCompleter.future;
      _identifiedUserId = null;
      entitlementSnapshot.value = null;  // Clear on logout
      await _client.logOut();
    }

    /// CRITICAL: Gate on init AND identification
    /// Purchases on anonymous user can cause entitlement ownership issues
    Future<PaywallOutcome> presentPaywall() async {
      // Wait for init (or fail if init failed)
      try {
        await _initCompleter.future;
      } catch (_) {
        return PaywallOutcome.error;  // SDK not configured
      }

      // CRITICAL: Must be identified before purchasing
      if (_identifiedUserId == null) {
        return PaywallOutcome.error;  // Not identified, can't purchase safely
      }

      if (_isPresenting) return PaywallOutcome.cancelled;
      _isPresenting = true;
      try {
        final result = await _client.presentPaywall();
        // Refresh entitlement after paywall closes
        await refreshEntitlement();
        return result;
      } finally {
        _isPresenting = false;
      }
    }

    /// CRITICAL: Gate on init + never clobber known state + never throw
    /// Safe to call from lifecycle callbacks - swallows all exceptions
    Future<void> refreshEntitlement() async {
      try {
        await _initCompleter.future;
        final newSnapshot = await _client.getEntitlementSnapshot();
        _updateSnapshotIfBetter(newSnapshot);  // Only update if non-null
      } catch (e) {
        // Swallow exceptions - lifecycle refresh must never crash/spam errors
        _logger.fine('refreshEntitlement failed: $e');
      }
    }

    /// Restore purchases (device change, reinstall, family sharing)
    /// CRITICAL: This is the #1 subscription correctness issue after launch
    /// Must be exposed in Settings UI as "Restore Purchases" action
    Future<void> restorePurchases() async {
      try {
        await _initCompleter.future;
      } catch (_) {
        return;  // SDK not configured
      }
      if (_identifiedUserId == null) return;  // Must be identified
      await _client.restorePurchases();
      await refreshEntitlement();
    }
  }
  ```

### 2.7 Register in DI (SINGLETONS - Not Factories) [DONE]
- **File:** `lib/config/locator_config.dart`
- **Location:** After line 97 (TrialExpirationDecisionStore)
- **CRITICAL:** Must be singletons to prevent duplicate SDK listeners/configure calls
- **Changes:**
  ```dart
  // SINGLETON - RevenueCat services must be app-lifetime
  // Using factory: () creates new instances per resolve - WRONG
  // Use singleton registration (exact syntax depends on your DI library)
  Module<RevenueCatClient>(
    singleton: true,  // or lazy singleton pattern
    factory: () => createRevenueCatClient(),
  ),
  Module<RevenueCatService>(
    singleton: true,
    factory: () => RevenueCatService(locator<RevenueCatClient>()),
  ),
  ```

---

## Phase 3: Subscription Status Resolver (Centralized Policy)

Single source of truth for UI gating decisions. Prevents duplicate logic across Home/Library.

### 3.1 Create SubscriptionStatusResolver [DONE]
- **New File:** `lib/paywall/domain/subscription_status_resolver.dart`
- **Pattern:** Pure functions, easily testable, uses app-owned `EntitlementSnapshot`
- **Time pattern:** Keep resolver pure - callers pass `DateTime now` (no Clock injection)
- **CRITICAL:** Snapshot only authoritative when `appUserId == user.id`
- **Responsibilities:**
  ```dart
  /// Pure resolver - no injected dependencies, callers supply `now`
  class SubscriptionStatusResolver {
    /// Returns effective status for UI gating
    /// - If snapshot is null (RC unavailable) → fallback to user.subscriptionStatus
    /// - If snapshot.appUserId != user.id (wrong user) → fallback to user.subscriptionStatus
    /// - If snapshot is for correct user → use RC state (authoritative)
    SubscriptionStatus resolveEffectiveStatus({
      required User user,
      required EntitlementSnapshot? snapshot,
    }) {
      // CRITICAL: Only treat as authoritative if for current user
      if (snapshot == null || !snapshot.isForUser(user.id)) {
        return user.subscriptionStatus;  // Fallback to DB
      }
      return mapSnapshotToStatus(snapshot);
    }

    /// Check if trial reminder should show (within 24h of expiration)
    /// Callers must pass `now` (e.g., clock.now() or DateTime.now())
    bool shouldShowTrialReminder({
      required EntitlementSnapshot? snapshot,
      required DateTime now,
    });

    /// Check if trial expired modal should show
    /// CRITICAL: Use EFFECTIVE STATUS (resolver output), not raw snapshot
    /// Handles RC unavailable (web/failure) by falling back to DB status
    /// CALL ORDER: load lastSeen → compute currentEffective → decide modal → persist newLastSeen
    bool shouldShowTrialExpiredModal({
      required SubscriptionStatus currentEffectiveStatus,  // From resolveEffectiveStatus()
      required SubscriptionStatus? lastSeenStatus,  // From decision store
      required EntitlementSnapshot? snapshot,  // Optional secondary signal
    }) {
      // Primary: Detect status transition trial → free/expired
      // Works even when RC unavailable (uses effective status which falls back to DB)
      if (lastSeenStatus == SubscriptionStatus.trial &&
          (currentEffectiveStatus == SubscriptionStatus.free ||
           currentEffectiveStatus == SubscriptionStatus.expired)) {
        return true;  // Trial ended, show modal
      }

      // Secondary: RC's wasTrialThatExpired (if periodType available and RC working)
      if (snapshot?.wasTrialThatExpired == true) {
        return true;
      }

      return false;
    }

    /// Map EntitlementSnapshot to SubscriptionStatus
    /// CRITICAL: Explicit precedence rules for all states
    SubscriptionStatus mapSnapshotToStatus(EntitlementSnapshot snapshot) {
      // 1. No entitlement at all
      if (!snapshot.hasProEntitlement) {
        // Check if was trial vs paid for expired state distinction
        if (snapshot.wasTrialThatExpired) return SubscriptionStatus.free;
        if (snapshot.wasPaidThatExpired) return SubscriptionStatus.expired;
        return SubscriptionStatus.free;  // Never had entitlement
      }

      // 2. Has entitlement - determine type
      // CRITICAL: Grace takes precedence (billing issue during active subscription)
      if (snapshot.isInGracePeriod) return SubscriptionStatus.grace;

      // 3. Active subscription - check if trial or paid
      if (snapshot.isTrialPeriod) return SubscriptionStatus.trial;

      // 4. Paid subscription - determine monthly vs yearly
      if (snapshot.productId == kProductMonthly) return SubscriptionStatus.premiumMonthly;
      if (snapshot.productId == kProductYearly) return SubscriptionStatus.premiumAnnual;

      // 5. Fallback for unknown product - LOG LOUDLY (should never happen in prod)
      // TODO: Add new product IDs here when expanding subscription tiers
      _logger.warning('Unknown productId: ${snapshot.productId} - defaulting to premiumMonthly');
      return SubscriptionStatus.premiumMonthly;
    }
  }
  ```

### 3.2 Register in DI [DONE]
- **File:** `lib/config/locator_config.dart`
- **Changes:** Add `Module<SubscriptionStatusResolver>`

---

## Phase 4: Auth & Startup Integration (Constructor Injection)

### 4.1 Update StartupViewModel Constructor (INIT ORDER CRITICAL) [DONE]
- **File:** `lib/startup/startup_view_model.dart`
- **CRITICAL:** Initialize RevenueCat BEFORE Auth to prevent race condition
- **Problem:** Auth rehydration calls `identify()` - SDK must be configured first
- **Solution:** RevenueCatService.identify() queues until init() completes (see Phase 2.6)
- **Changes:** Add `RevenueCatService` as constructor parameter
  ```dart
  class StartupViewModel extends ChangeNotifier {
    final AuthService _authService;
    final RevenueCatService _revenueCatService;  // NEW
    final AppLifecycleService _appLifecycleService;  // CRITICAL: Force construction

    StartupViewModel(this._authService, this._revenueCatService, this._appLifecycleService);

    Future<void> init() async {
      // CRITICAL: AppLifecycleService must be constructed to register observer
      // DI lazy loading won't call addObserver until resolved - force it here
      // (The constructor parameter already forces resolution)

      // CRITICAL: Init RevenueCat FIRST (before auth rehydration triggers identify)
      try {
        await _revenueCatService.init();
      } catch (e) {
        _logger.warning('RevenueCat init failed: $e');
        // Continue - app works without RC, just can't show paywall
        // identify() calls will fail gracefully (queued on failed completer)
      }

      await _authService.init();  // This may trigger identify() via rehydration
    }
  }
  ```

### 4.2 Update AuthService Constructor [DONE]
- **File:** `lib/features/auth/data/auth_service.dart`
- **Changes:** Add `RevenueCatService` as constructor parameter (best-effort calls)
  ```dart
  class AuthService {
    final RevenueCatService _revenueCatService;  // NEW

    AuthService(/* existing params */, this._revenueCatService);

    Future<void> _rehydrateFromSession(...) async {
      // ... existing logic ...
      try {
        await _revenueCatService.identify(data.user.id);
      } catch (e) {
        _logger.warning('RevenueCat identify failed: $e');
      }
    }

    Future<void> logout() async {
      try {
        await _revenueCatService.logout();
      } catch (_) {}
      // ... existing logic ...
    }
  }
  ```

### 4.3 Update DI Registration [DONE]
- **File:** `lib/config/locator_config.dart`
- **Changes:** Update `AuthService` and `StartupViewModel` registrations to inject `RevenueCatService`

---

## Phase 5: Paywall Presentation (Navigation Fix)

### 5.1 Update PaywallView (CRITICAL - Navigation Semantics + Error Handling) [DONE]
- **File:** `lib/paywall/paywall_view.dart`
- **Problem:** Current `navigateToHome()` uses `replaceAll`, breaking modal return flow
- **Fix:** Paywall must use `back()` when done (RouterService has no `pop(result)`)
- **CRITICAL:** Show error UI on `PaywallOutcome.error` to prevent navigation loops
- **Changes:**
  ```dart
  @override
  void initState() {
    super.initState();
    _presentPaywall();
  }

  Future<void> _presentPaywall() async {
    final outcome = await widget.viewModel.presentPaywall();
    if (!mounted) return;

    // CRITICAL: Handle error case to prevent loops
    // If paywall errors (not identified, SDK failed), don't just pop
    // Show a one-shot error message so user knows what happened
    if (outcome == PaywallOutcome.error) {
      // Use root messenger to ensure snackbar survives route pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to show upgrade options. Please try again later.')),
      );
      // Brief delay ensures snackbar renders before navigation
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    // Always navigate back - let caller handle what happens next
    // RouterService.back() is the correct method (no pop(result) API)
    locator<RouterService>().back();
  }
  ```
- **Caller responsibility:** HomeViewModel/LibraryViewModel should NOT auto-reopen paywall on error.
  Check for error state and require user action to retry.

### 5.2 Update PaywallViewModel [DONE]
- **File:** `lib/paywall/paywall_view_model.dart`
- **Changes:**
  - Constructor inject `RevenueCatService`
  - Add `presentPaywall()` method that delegates to service
  - Remove `navigateToHome()` - view handles navigation

### 5.3 Add Restore Purchases Entry Point (CRITICAL for Launch) [DONE]
- **File:** Settings view (e.g., `lib/settings/settings_view.dart`)
- **Rationale:** #1 subscription correctness issue after launch - users reinstall/change devices
- **Changes:**
  - Add "Restore Purchases" button/list tile in settings
  - On tap: call `_revenueCatService.restorePurchases()`
  - Show loading indicator during restore
  - Show success/failure feedback
  ```dart
  ListTile(cla
    leading: const Icon(Icons.restore),
    title: const Text('Restore Purchases'),
    onTap: () async {
      setState(() => _isRestoring = true);
      try {
        await widget.viewModel.restorePurchases();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to restore purchases. Try again later.')),
        );
      } finally {
        if (mounted) setState(() => _isRestoring = false);
      }
    },
  ),
  ```

---

## Phase 6: Home/Library Gating Updates

### 6.1 Update HomeViewModel [DONE]
- **File:** `lib/home/home_view_model.dart`
- **Changes:**
  - Constructor inject `SubscriptionStatusResolver` and `RevenueCatService`
  - Listen to `_revenueCatService.entitlementSnapshot` for real-time updates
  - Replace `user.trialPeriod?.isExpired()` with resolver
  - Replace `isTrialOrPremiumExpired()` with `_resolver.shouldShowTrialExpiredModal()`
  - Add `showTrialReminder` state from `_resolver.shouldShowTrialReminder()`

### 6.2 Remove Subscription Status DB Writes (CRITICAL) [DONE]
- **File:** `lib/home/home_view_model.dart`
- **Problem:** `handleUseFreeTier()` currently writes `SubscriptionStatus.free` to Supabase, conflicting with "webhook is DB writer" principle
- **Changes:**
  - Remove `await _userRepository.updateSubscriptionStatus(...)` calls
  - Keep decision store marking (local persistence)
  - Keep protocol deactivation logic
  - Let webhook handle DB subscription_status changes
  ```dart
  Future<void> handleUseFreeTier() async {
    // Mark decision in local store (still needed for modal suppression)
    await _decisionStore.markExpirationResolved(...);

    // Deactivate excess protocols (still needed)
    await _deactivateExcessProtocols();

    // DO NOT write subscription_status to Supabase
    // Webhook is the only DB writer for subscription state
  }
  ```

### 6.3 Update HomeViewState [DONE]
- **File:** `lib/home/home_state.dart`
- **Changes:** Add `showTrialReminder: bool` field

### 6.4 Update HomeView [DONE]
- **File:** `lib/home/home_view.dart`
- **Changes:** Show TrialReminderAlert when `state.showTrialReminder`
- **Actual:**
  - Created `lib/paywall/widgets/trial_reminder_alert.dart` — amber dismissible banner with "Your trial ends soon" + "Upgrade Now" button
  - Added `dismissTrialReminder()` to `HomeViewModel`
  - Wired alert into `_buildSlivers()` between status banner and header
  - Extracted shared `DismissButton` to `lib/core/ui/widgets/dismiss_button.dart` (de-duped from `HomeStatusBanner`)
  - Review fixes: wrapped `goToPaywall()` in closure, added conditional top padding, updated copy for `<24h` window accuracy

### 6.5 Update LibraryViewModel [DONE]
- **File:** `lib/library/library_view_model.dart`
- **Changes:**
  - Constructor inject `SubscriptionStatusResolver` and `RevenueCatService`
  - Use `_resolver.resolveEffectiveStatus()` for protocol locking
- **Actual:**
  - Added `SubscriptionStatusResolver` and `RevenueCatService` as required constructor params
  - Replaced `user.getEffectiveStatus(DateTime.now())` with `_resolver.resolveEffectiveStatus(user:, snapshot:)` in `_buildCards()`
  - Added `_entitlementListener` to listen to `revenueCatService.entitlementSnapshot` for real-time UI updates (locked/unlocked cards)
  - Added `_handleEntitlementChange()` method (triggers non-loading refresh, matching HomeViewModel pattern)
  - Updated `dispose()` to remove entitlement listener
  - Updated `LibraryView` to pass `subscriptionStatusResolver` and `revenueCatService` from locator
  - No DI registration changes needed (resolver and service already registered as singletons)

### 6.5.1 Refactor: Extract shared patterns, purify _buildCards, add tests [DONE]
- **Files:**
  - `lib/core/abstractions/entitlement_listener_mixin.dart` (new)
  - `lib/core/abstractions/connectivity_listener_mixin.dart` (new)
  - `lib/library/library_view_model.dart` (refactored)
  - `lib/home/home_view_model.dart` (refactored)
  - `test/library/library_view_model_test.dart` (new, 11 tests)
- **Changes:**
  - Extracted `EntitlementListenerMixin` to de-duplicate entitlement listener setup/teardown between Home and Library view models
  - Extracted `ConnectivityListenerMixin` to de-duplicate connectivity listener setup/teardown between Home and Library view models
  - Purified `_buildCards` in LibraryViewModel: receives `EntitlementSnapshot?` as parameter instead of reading `_revenueCatService.entitlementSnapshot.value` directly
  - Added 11 LibraryViewModel unit tests covering: resolver-based locking (free, premium, trial, expired, RC override), entitlement change triggers refresh, connectivity changes (offline, online reload, no-op), init states (loaded, empty)

---

## Phase 7: Trial Expiration Decision Store (Re-keying)

### 7.0 Add Status Transition Tracking (CRITICAL for Modal Detection) [DONE]
- **File:** `lib/paywall/data/trial_expiration_decision_store.dart`
- **Rationale:** RC's `entitlements.all.periodType` may be null/missing on some platforms
- **Pattern:** Track status transitions client-side as primary detection, not SDK metadata
- **Key:** `lastSeenEffectiveStatus:<userId>`
- **Changes:**
  ```dart
  /// Persist last-seen effective status to detect transitions (survives restarts)
  Future<void> saveLastSeenStatus({
    required String userId,
    required SubscriptionStatus status,
  }) async {
    await _prefs.setString('lastSeenEffectiveStatus:$userId', status.name);
  }

  /// Get last-seen status (for modal transition detection)
  /// CRITICAL: Handles enum rename/removal gracefully (returns null on failure)
  Future<SubscriptionStatus?> getLastSeenStatus(String userId) async {
    final name = _prefs.getString('lastSeenEffectiveStatus:$userId');
    if (name == null) return null;
    try {
      return SubscriptionStatus.values.byName(name);
    } catch (_) {
      // Stored value doesn't match current enum (old app version, future rename)
      // Fail-safe: return null and let modal show if needed
      return null;
    }
  }
  ```
- **Integration:** Call `saveLastSeenStatus()` whenever effective status changes (HomeViewModel)

### 7.1 Update TrialExpirationDecisionStore (CRITICAL)
- **File:** `lib/paywall/data/trial_expiration_decision_store.dart`
- **Problem:** Currently keys by `trialStartDate` which won't exist under RevenueCat
- **Solution:** Key by RevenueCat-stable identifiers with fallback hierarchy
- **Changes:**
  ```dart
  /// Stable key for decision persistence
  /// Fallback hierarchy (use first available):
  /// 1. originalTransactionId (most stable, survives renewals)
  /// 2. latestPurchaseDate.toIso8601String() (fallback if #1 unavailable)
  /// 3. expirationDate.toIso8601String() (last resort)
  /// Returns null if can't compute stable key (non-cacheable)
  String? _buildDecisionKey({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
  }) {
    final txnId = snapshot.originalTransactionId;
    if (txnId != null) return '$userId:$entitlementId:$txnId';

    final purchaseDate = snapshot.latestPurchaseDate;
    if (purchaseDate != null) return '$userId:$entitlementId:purchase:${purchaseDate.toIso8601String()}';

    final expDate = snapshot.expirationDate;
    if (expDate != null) return '$userId:$entitlementId:exp:${expDate.toIso8601String()}';

    // Can't compute stable key - return null to indicate non-cacheable
    // This prevents incorrectly suppressing future legitimate modals
    return null;
  }

  /// IMPORTANT: If _buildDecisionKey returns null, do NOT mark as resolved
  /// Let the modal show again next time (fail safe)

  /// Check if expiration has been resolved for this subscription period
  /// Returns false if key can't be computed (fail safe - show modal)
  Future<bool> isSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
  }) async {
    final key = _buildDecisionKey(userId: userId, entitlementId: entitlementId, snapshot: snapshot);
    if (key == null) return false;  // Non-cacheable, always show modal
    // ... check SharedPreferences for key
  }

  /// Mark expiration as resolved
  /// Does nothing if key can't be computed (non-cacheable)
  Future<void> markSubscriptionExpirationResolved({
    required String userId,
    required String entitlementId,
    required EntitlementSnapshot snapshot,
    required ExpirationDecision decision,
  }) async {
    final key = _buildDecisionKey(userId: userId, entitlementId: entitlementId, snapshot: snapshot);
    if (key == null) return;  // Non-cacheable, can't persist
    // ... save to SharedPreferences
  }
  ```

---

## Phase 8: Trial Reminder System

### 8.1 Create Trial Reminder Alert Widget
- **New File:** `lib/paywall/widgets/trial_reminder_alert.dart`
- **UI:** Dismissible banner with "Trial expires tomorrow" + "Upgrade Now" button

### 8.2 Create TrialReminderService
- **New File:** `lib/paywall/data/trial_reminder_service.dart`
- **Constructor:** `TrialReminderService(this._resolver, this._prefs, this._clock)`
- **CRITICAL:** Inject Clock for testability (per Design Principle #8)
- **Responsibilities:**
  - Track last reminder shown date (SharedPreferences)
  - **User-scoped storage key:** `trialReminder:lastShownAt:<userId>:<entitlementId>`
  - Prevent showing more than once per day (INV-P4)
  - Uses `_resolver.shouldShowTrialReminder(snapshot: snapshot, now: _clock.now())`
  - Respects expiration decision store (if user already chose free, suppress reminders)

### 8.3 Register in DI
- **File:** `lib/config/locator_config.dart`
- **Changes:** Add `Module<TrialReminderService>`

### 8.4 Refresh on App Resume
- **File:** `lib/core/utils/app_lifecycle_service.dart` (use existing service)
- **Rationale:** Users can change subscription in App Store/Play Store settings; don't rely only on SDK listener
- **Pattern:** Keep lifecycle wiring in dedicated service, not in view models
- **Changes:**
  ```dart
  // In AppLifecycleService (or create if doesn't exist)
  class AppLifecycleService with WidgetsBindingObserver {
    final RevenueCatService _revenueCatService;

    AppLifecycleService(this._revenueCatService) {
      WidgetsBinding.instance.addObserver(this);
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.resumed) {
        _revenueCatService.refreshEntitlement();
      }
    }

    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
    }
  }
  ```
- **DI:** Register in `locator_config.dart` after RevenueCatService

---

## Phase 9: Webhook Edge Function (DB Writer) [DONE]

### 9.1 Create Edge Function [DONE]
- **New File:** `supabase/functions/revenuecat-webhook/index.ts`
- **CRITICAL:** This is the ONLY writer of subscription status to Supabase
- **Signature Verification (CRITICAL):**
  - Compute HMAC over **raw request body** (use `await req.text()`, NOT `await req.json()`)
  - Compare to `X-RevenueCat-Signature` header per RevenueCat docs
  - Re-encoding JSON after parsing will break signature verification
- **app_user_id Validation (CRITICAL):**
  - RevenueCat `app_user_id` is a string; our RPC expects UUID
  - **MUST validate UUID format** before calling RPC to prevent retry storms
  - If `app_user_id` is not a valid UUID → return `200 OK` with "ignored" + log warning
  - This enforces INV-P5 ("app_user_id must match Supabase auth.uid")
  ```typescript
  const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!UUID_REGEX.test(event.app_user_id)) {
    console.warn(`Invalid app_user_id format: ${event.app_user_id}`);
    return new Response(JSON.stringify({ status: 'ignored', reason: 'invalid_user_id' }), { status: 200 });
  }
  ```
- **Database Access (CRITICAL - SERVICE ROLE ONLY):**
  - **Chosen approach:** Use `SECURITY DEFINER` Postgres function callable ONLY by `service_role`
  - Create `apply_revenuecat_event(...)` function that enforces monotonicity + idempotency
  - **CRITICAL:** Edge Function MUST use `SUPABASE_SERVICE_ROLE_KEY` (stored as function secret)
  - RPC is NOT callable by `anon`/`authenticated` - prevents privilege escalation from clients

### 9.1.1 Create SECURITY DEFINER Function [DONE]
- **New File:** `supabase/migrations/20260212192846_revenuecat_webhook_rpc.sql`
- **Changes:**
  ```sql
  -- Secure RPC for webhook to update subscription status
  -- CRITICAL: Only callable by service_role (Edge Function uses service key)
  CREATE OR REPLACE FUNCTION apply_revenuecat_event(
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
    -- Validate status before attempting update (prevents retry storms on bad data)
    IF p_subscription_status NOT IN ('free','trial','premiumMonthly','premiumAnnual','expired','grace') THEN
      RAISE EXCEPTION 'invalid subscription_status: %', p_subscription_status;
    END IF;

    -- Atomic conditional update with monotonicity + idempotency
    -- Tie-break: if timestamps match but event_id differs, apply the new event
    UPDATE public.users
    SET
      subscription_status = p_subscription_status,
      subscription_updated_at = p_occurred_at,
      subscription_source = 'revenuecat-webhook',
      rc_last_event_id = p_event_id
    WHERE id = p_user_id
      AND (rc_last_event_id IS NULL OR rc_last_event_id != p_event_id)
      AND (
        subscription_updated_at IS NULL
        OR p_occurred_at > subscription_updated_at
        OR (p_occurred_at = subscription_updated_at AND rc_last_event_id IS DISTINCT FROM p_event_id)
      );
  END;
  $$;

  -- CRITICAL: Only service_role can call this function
  -- Prevents privilege escalation from clients with anon key
  REVOKE ALL ON FUNCTION apply_revenuecat_event(uuid, text, timestamptz, text) FROM PUBLIC;
  REVOKE ALL ON FUNCTION apply_revenuecat_event(uuid, text, timestamptz, text) FROM anon;
  REVOKE ALL ON FUNCTION apply_revenuecat_event(uuid, text, timestamptz, text) FROM authenticated;
  GRANT EXECUTE ON FUNCTION apply_revenuecat_event(uuid, text, timestamptz, text) TO service_role;
  ```
- **Idempotency Strategy:**
  1. Verify webhook signature (HMAC over raw body)
  2. Extract event ID from payload
  3. **Call RPC using service role key** (stored as `SUPABASE_SERVICE_ROLE_KEY` function secret)
  4. RPC uses **atomic conditional UPDATE** with tie-break for timestamp precision:
     ```sql
     UPDATE users
     SET
       subscription_status = $status,
       subscription_updated_at = $event_occurred_at,
       subscription_source = 'revenuecat-webhook',
       rc_last_event_id = $event_id
     WHERE id = $user_id
       AND (rc_last_event_id IS NULL OR rc_last_event_id != $event_id)
       AND (
         subscription_updated_at IS NULL
         OR $event_occurred_at > subscription_updated_at
         OR ($event_occurred_at = subscription_updated_at AND rc_last_event_id IS DISTINCT FROM $event_id)
       );
     ```
  5. Return 200 OK even if no rows updated (idempotent)

### 9.2 Status Mapping (Canonical) [DONE]
| RevenueCat State | App SubscriptionStatus | Notes |
|------------------|------------------------|-------|
| No entitlement (never had) | `free` | New user default |
| Active + periodType=TRIAL | `trial` | During 7-day trial |
| Active + monthly product | `premiumMonthly` | Paying monthly |
| Active + yearly product | `premiumAnnual` | Paying yearly |
| Trial expired, no conversion | `free` | Chose not to pay |
| Paid subscription expired | `expired` | Lapsed subscriber (distinct UX) |
| Billing issue (grace period) | `grace` | Payment retry in progress |

**Note:** `expired` vs `free` distinction:
- `expired` = was a paying subscriber, now lapsed (show "resubscribe" messaging)
- `free` = never paid or explicitly chose free tier (show "upgrade" messaging)

### 9.3 Disable JWT Verification (CRITICAL) [DONE]
- **New File:** `supabase/functions/revenuecat-webhook/config.toml`
- **CRITICAL:** RevenueCat won't send a Supabase JWT - must disable verification
- **Note:** Use the exact Supabase Functions config format for your CLI version
- **Changes:**
  ```toml
  # Simple format (common in newer CLI versions)
  verify_jwt = false
  ```
- **Alternative:** Set via deploy command: `supabase functions deploy revenuecat-webhook --no-verify-jwt`

### 9.4 Add Secrets [MANUAL - TODO]
- **Commands:**
  ```sh
  supabase secrets set REVENUECAT_WEBHOOK_SECRET=xxx
  supabase secrets set SUPABASE_SERVICE_ROLE_KEY=xxx  # CRITICAL for RPC call
  ```

### 9.5 Deploy Function [MANUAL - TODO]
- **Command:** `supabase functions deploy revenuecat-webhook`

### 9.6 Configure Webhook in RevenueCat [MANUAL - TODO]
- [ ] Add webhook URL: `https://<project>.supabase.co/functions/v1/revenuecat-webhook`
- [ ] Set shared secret
- [ ] Enable ALL relevant lifecycle events with explicit handling:

| Event | subscription_status change | Notes |
|-------|---------------------------|-------|
| `INITIAL_PURCHASE` | → trial/premiumMonthly/premiumAnnual | Based on period_type |
| `RENEWAL` | → premiumMonthly/premiumAnnual | Keep premium |
| `CANCELLATION` | **NO CHANGE** | Still active until period end |
| `BILLING_ISSUE` | → grace | Payment retry in progress |
| `EXPIRATION` | → free or expired | See Phase 9.7 for trial vs paid |
| `PRODUCT_CHANGE` | → new plan type | Upgrade/downgrade |
| `UNCANCELLATION` | **NO CHANGE** | User re-enabled auto-renew (no DB change needed) |
| `TRANSFER` | **Update BOTH users** | See Phase 9.8 |
| `BILLING_ISSUE_RESOLVED` | → premiumMonthly/premiumAnnual | Recovery from grace |

**CRITICAL:** CANCELLATION does NOT mean entitlement ended. User is still premium until EXPIRATION.

### 9.7 TRANSFER Event Handling (CRITICAL) [DONE]
- **Problem:** TRANSFER moves entitlement between app_user_ids. "No change" leaves wrong user premium.
- **CRITICAL REQUIREMENT:** Field names in example are illustrative - implement against exact RevenueCat webhook JSON schema.
  - Add fixture JSON file: `test/fixtures/revenuecat_transfer_event.json`
  - Add unit test verifying TRANSFER parsing matches actual payload structure
- **Solution:** Update BOTH old and new users in webhook with UUID validation:
  ```typescript
  // VERIFY: actual field names from RevenueCat webhook documentation
  // transferred_from, transferred_to, product_id are examples - check actual schema
  async function handleTransfer(event: RevenueCatEvent): Promise<Response> {
    let from: string | null = event.transferred_from ?? null;
    let to: string | null = event.transferred_to ?? null;
    const product_id = event.product_id;

    // CRITICAL: Validate UUIDs for BOTH transfer IDs (same hostile-input safety as app_user_id)
    if (from && !UUID_REGEX.test(from)) {
      console.warn(`Invalid transferred_from UUID: ${from}`);
      from = null;
    }
    if (to && !UUID_REGEX.test(to)) {
      console.warn(`Invalid transferred_to UUID: ${to}`);
      to = null;
    }

    // Guard: Ignore self-transfers (shouldn't happen but be safe)
    if (from && to && from === to) {
      return okIgnored('self_transfer');
    }

    // Guard: If both are invalid/missing, nothing to do
    if (!from && !to) {
      return okIgnored('no_valid_transfer_ids');
    }

    // 1. Revoke from old user (DETERMINISTIC RULE for revoke status)
    if (from) {
      // CRITICAL: Query current status BEFORE updating to determine correct revoke status
      const { data: fromUser } = await supabase
        .from('users')
        .select('subscription_status')
        .eq('id', from)
        .single();

      // Deterministic mapping:
      // - Was premium*/grace → set 'expired' (was paying, show "resubscribe" UX)
      // - Was trial/free/unknown → set 'free' (never paid or safe default)
      let revokeStatus = 'free';
      const wasPaying = ['premiumMonthly', 'premiumAnnual', 'grace']
        .includes(fromUser?.subscription_status);
      if (wasPaying) {
        revokeStatus = 'expired';
      }

      await supabase.rpc('apply_revenuecat_event', {
        p_user_id: from,
        p_event_id: `${event.id}_from`,
        p_occurred_at: event.event_timestamp,
        p_subscription_status: revokeStatus,
      });
    }

    // 2. Grant to new user
    if (to) {
      const status = determineStatusFromProduct(product_id, event.period_type);
      await supabase.rpc('apply_revenuecat_event', {
        p_user_id: to,
        p_event_id: `${event.id}_to`,
        p_occurred_at: event.event_timestamp,
        p_subscription_status: status,
      });
    }

    return ok();
  }
  ```

### 9.8 Trial vs Paid Expiration Rule (CRITICAL) [DONE]
- **Problem:** EXPIRATION event doesn't inherently distinguish trial vs paid
- **Solution:** Use payload fields to determine:
  ```typescript
  function determineExpiredStatus(event: RevenueCatEvent): SubscriptionStatus {
    // Check if this was a trial period
    const wasTrial = event.period_type === 'TRIAL' ||
                     event.is_trial_period === true ||
                     (event.subscriber_attributes?.['$trial'] === 'true');

    if (wasTrial) {
      return 'free';  // Trial expired, never converted
    }

    // Paid subscription expired
    return 'expired';  // Lapsed subscriber, show "resubscribe" UX
  }
  ```
- **Fallback:** If `period_type` unavailable, check last known `subscription_status` in DB:
  - Was `trial` → map to `free`
  - Was `premiumMonthly/premiumAnnual` → map to `expired`

---

## Phase 10: Domain Layer Cleanup (AFTER Phases 1-9 Verified)

Only proceed after webhook + UI gating are stable.

### 10.1 Stop Using TrialPeriod for Gating [DONE]
- **Files:** All files that reference `user.trialPeriod`
- **Changes:** Simplified `getEffectiveStatus()` to return `subscriptionStatus` directly (removed `trialPeriod.isExpired()` check). Updated tests in user_test, check_eligibility_use_case_test, log_session_use_case_test. Updated docstrings on User class, data source, and repository.

### 10.2 Update User Entity [DONE]
- **File:** `lib/features/user/domain/entities/user.dart`
- **Changes:** Renamed `createWithTrial()` to `create()` with `subscriptionStatus: free` (INV-P6). Removed `currentTime` parameter from `getEffectiveStatus()`, `activateProtocol()`, and `canLogSession()`. Cascaded to all callers: HomeViewModel, LibraryViewModel, LogSessionViewModel, CheckEligibilityUseCase (+params), LogSessionUseCase. Updated UserBootstrapService to use `User.create()`. Updated UserFactory.createWithTrial() to createDefault(). Updated all tests.

### 10.3 Update UserBootstrapService [DONE]
- **File:** `lib/features/auth/data/user_bootstrap_service.dart`
- **Actual:** Already completed as part of Phase 10.2. Code at line 61 already uses `User.create(id: userId, createdAt: createdAt)`.

### 10.4 Update UserDto (BEFORE Dropping Columns) [DONE]
- **File:** `lib/features/user/data/dtos/user_dto.dart`
- **Actual:** Removed `trialEndsAt` field entirely from UserDto freezed class. `toJson()` no longer emits `trial_ends_at`. `fromJson()` gracefully ignores the legacy column if still present in DB responses. Removed `_nullableDateTimeFromJson` helper. Tests updated to verify omission and backward compatibility.

---

## Phase 11: Database Cleanup (AFTER Phase 10)

### 11.1 Remove pg_cron Job
- **New File:** `supabase/migrations/YYYYMMDDHHMMSS_remove_expire_trials_cron.sql`
- **IMPORTANT:** Verify exact job name from `20260123113429_trial_expiration_cron.sql` before writing this migration
- **Changes:**
  ```sql
  -- Remove trial expiration cron job (RevenueCat manages trials now)
  -- NOTE: Verify job name matches what was scheduled in the original migration
  SELECT cron.unschedule('expire-trials');
  DROP FUNCTION IF EXISTS expire_trials();
  ```

### 11.2 Update handle_new_user() Before Dropping Columns (CRITICAL)
- **New File:** `supabase/migrations/YYYYMMDDHHMMSS_update_handle_new_user_no_trial.sql`
- **CRITICAL:** Must run BEFORE dropping columns or trigger will fail
- **Changes:**
  ```sql
  -- Remove trial columns from handle_new_user INSERT
  -- Must be done BEFORE dropping the columns
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
      -- NOTE: trial_period, trial_ends_at removed
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
  ```

### 11.3 Drop Trial Columns (LAST)
- **New File:** `supabase/migrations/YYYYMMDDHHMMSS_remove_trial_columns.sql`
- **Prerequisite:** Phase 11.2 completed, UserDto no longer serializes these columns
- **Changes:**
  ```sql
  -- Remove trial columns (RevenueCat is source of truth)
  ALTER TABLE users DROP COLUMN IF EXISTS trial_ends_at;
  ALTER TABLE users DROP COLUMN IF EXISTS trial_expired_at;
  ALTER TABLE users DROP COLUMN IF EXISTS trial_period;
  ```

### 11.4 Delete TrialPeriod Value Object (OPTIONAL - After All Usage Removed)
- **File:** `lib/features/user/domain/value_objects/trial_period.dart`
- **Action:** Delete file and related tests
- **Note:** Only after verifying no code references remain

---

## Phase 12: Testing

### 12.1 Unit Tests
- **New File:** `test/paywall/data/revenuecat_service_test.dart`
  - SDK initialization with per-platform keys
  - Guard against multiple presentations
  - Customer identification flow
  - Entitlement listener updates ValueNotifier
- **New File:** `test/paywall/domain/subscription_status_resolver_test.dart`
  - EntitlementSnapshot → SubscriptionStatus mapping
  - `shouldShowTrialReminder()` timing logic
  - `shouldShowTrialExpiredModal()` detection
  - Offline fallback behavior (uses User.subscriptionStatus)
- **New File:** `test/paywall/data/trial_reminder_service_test.dart`
  - Reminder timing logic
  - Once-per-day enforcement
- **New File:** `test/paywall/domain/entitlement_snapshot_test.dart`
  - Decision key generation with fallback hierarchy

### 12.2 Widget Tests
- **New File:** `test/paywall/widgets/trial_reminder_alert_test.dart`
  - Alert renders correctly
  - Upgrade button navigates to paywall
  - Dismiss works

### 12.3 Integration Tests
- Sandbox purchase flow
- Trial → expiration → modal flow
- Webhook verification

---

## Verification Steps

1. **Build passes:** `flutter analyze`
2. **Tests pass:** `flutter test test/paywall/`
3. **Web builds:** Verify web target compiles with stub client
4. **Manual test - Fresh user:**
   - Install app → starts with `free` status
   - Tap locked protocol → paywall appears
   - Start subscription → 7-day trial starts, status becomes `trial`
5. **Manual test - Trial reminder:**
   - Set device time to 23h before trial end
   - Launch app → soft reminder alert appears
   - Dismiss → doesn't reappear same day
6. **Manual test - Trial expiration:**
   - Let trial expire (sandbox) → Trial Expiration Modal appears
   - Tap "Keep Everything" → RevenueCat paywall (to pay)
   - Tap "Continue with Free" → status becomes `free`
7. **Manual test - Webhook:**
   - Complete purchase → check Supabase users table updated
   - Cancel subscription → after period ends, status becomes `expired`
8. **Manual test - Real-time UI update:**
   - Complete purchase → UI updates immediately (no app restart)

---

## File Summary

### New Files
| File | Purpose |
|------|---------|
| `lib/paywall/paywall_constants.dart` | Canonical product/entitlement IDs |
| `lib/paywall/domain/entitlement_snapshot.dart` | App-owned entitlement model |
| `lib/paywall/data/revenuecat_client.dart` | Interface for testability |
| `lib/paywall/data/revenuecat_client_mobile.dart` | SDK implementation |
| `lib/paywall/data/revenuecat_client_stub.dart` | Web no-op implementation |
| `lib/paywall/data/revenuecat_client_factory.dart` | Conditional import factory |
| `lib/paywall/data/revenuecat_service.dart` | RevenueCat SDK wrapper |
| `lib/paywall/domain/subscription_status_resolver.dart` | Centralized gating policy |
| `lib/paywall/data/trial_reminder_service.dart` | 24h trial reminder logic |
| `lib/paywall/widgets/trial_reminder_alert.dart` | Soft reminder UI |
| `supabase/functions/revenuecat-webhook/index.ts` | Webhook handler (DB writer) |
| `supabase/functions/revenuecat-webhook/config.toml` | Disable JWT verification |
| `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_new_users_free.sql` | Fix trigger to create users as `free` |
| `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_webhook_columns.sql` | Idempotency columns |
| `supabase/migrations/YYYYMMDDHHMMSS_add_subscription_statuses.sql` | Add `grace` to CHECK constraint |
| `supabase/migrations/YYYYMMDDHHMMSS_revenuecat_webhook_rpc.sql` | SECURITY DEFINER RPC function |
| `supabase/migrations/YYYYMMDDHHMMSS_remove_expire_trials_cron.sql` | Remove old cron job |
| `supabase/migrations/YYYYMMDDHHMMSS_update_handle_new_user_no_trial.sql` | Update trigger before dropping columns |
| `supabase/migrations/YYYYMMDDHHMMSS_remove_trial_columns.sql` | Drop trial columns (LAST) |
| `test/fixtures/revenuecat_transfer_event.json` | TRANSFER webhook fixture for testing |

### Modified Files
| File | Changes |
|------|---------|
| `pubspec.yaml` | Add purchases_flutter, purchases_ui_flutter |
| `env/default.env.json` | Per-platform RC API keys (iOS, Android, macOS) |
| `lib/features/user/domain/entities/user.dart` | `create()` with free status |
| `lib/features/user/data/dtos/user_dto.dart` | Stop serializing trial columns |
| `lib/features/auth/data/user_bootstrap_service.dart` | Use `User.create()` |
| `lib/features/auth/data/auth_service.dart` | Constructor inject RC, identify/logout |
| `lib/config/locator_config.dart` | Register new services, update injections |
| `lib/startup/startup_view_model.dart` | Constructor inject RC, initialize |
| `lib/paywall/paywall_view.dart` | Present RC paywall, use back() |
| `lib/paywall/paywall_view_model.dart` | Constructor inject RC |
| `lib/paywall/data/trial_expiration_decision_store.dart` | Re-key with fallback hierarchy |
| `lib/home/home_view_model.dart` | Constructor inject resolver/RC, remove DB writes, listen to entitlement |
| `lib/home/home_state.dart` | Add showTrialReminder |
| `lib/home/home_view.dart` | Render trial reminder alert |
| `lib/library/library_view_model.dart` | Constructor inject resolver/RC |
| `lib/features/onboarding/presentation/widgets/screens/offer_screen.dart` | Update copy |
| `docs/ubiquitous-language.md` | Update/deprecate invariants |
| `docs/specs/20260123220000_spec_paywall_modal.md` | Update SDK reference section |

---

## Implementation Order (Safe Intermediate States)

```
Phase 0: Manual setup + copy alignment (BLOCKER)
    ↓
Phase 1: Backend trigger fix + enum mismatch (BLOCKER)
    ↓
Phase 2: SDK setup + environment config + internal models
    ↓
Phase 3: Subscription status resolver (centralized policy)
    ↓
Phase 4: Auth + startup integration (constructor injection)
    ↓
Phase 5: Paywall presentation (navigation fix - use back())
    ↓
Phase 6: Home/Library gating updates + remove DB writes
    ↓
Phase 7: Trial expiration decision store re-keying
    ↓
Phase 8: Trial reminder system
    ↓
Phase 9: Webhook (DB writer) ← Can parallel with 5-8
    ↓
Phase 10: Domain layer cleanup (AFTER 1-9 verified)
    ↓
Phase 11: Database cleanup (AFTER 10)
    ↓
Phase 12: Testing
```

---

## Review History

- **2026-01-24 (Round 1):** Carmack-level review identified 6 Critical, 5 Major, 4 Minor issues
  - Fixed: DB trigger creates `trial` → now creates `free`
  - Fixed: Per-platform API keys instead of single key
  - Fixed: DTO/column drop coordination
  - Fixed: Single source of truth (webhook writes DB, client uses RC)
  - Fixed: Paywall navigation (pop, not replaceAll)
  - Fixed: Decision store keying (RC identifiers)
  - Fixed: Staged TrialPeriod deprecation
  - Fixed: Centralized resolver (DRY)
  - Fixed: Webhook idempotency strategy
  - Added: Canonical constants for product/entitlement IDs
  - Added: Onboarding copy updates

- **2026-01-24 (Round 2):** Re-review identified 3 Critical, 7 Major, 2 Minor issues
  - Fixed: RouterService has `back()` not `pop(result)` - updated Phase 5
  - Fixed: Web/macOS platform support - added conditional imports and stub
  - Fixed: Existing DB writes in HomeViewModel conflict with webhook-only - added Phase 6.2
  - Fixed: No CustomerInfo listener - added entitlement stream and refresh
  - Fixed: Using `locator<>` in services - switched to constructor injection
  - Fixed: originalTransactionId may not exist - added fallback key hierarchy
  - Fixed: Webhook columns marked optional but required - now marked REQUIRED
  - Fixed: Webhook race conditions - specified atomic conditional UPDATE
  - Fixed: expired vs free mapping - clarified semantic difference
  - Fixed: SDK types leaking into domain - added EntitlementSnapshot model
  - Fixed: Spec still shows old SDK pattern - added Phase 0.5
  - Fixed: Cron job name assumption - added verification note

- **2026-01-24 (Round 3):** Re-review identified 3 Critical, 3 Major, 2 Minor issues
  - Fixed: Init order race - RevenueCat.init() now runs BEFORE Auth.init() + identify() queues until init completes
  - Fixed: Web stub returns `.none()` downgrading premium users - now returns `null` (unknown), resolver falls back to DB
  - Fixed: Webhook signature needs raw body, DB writes need service role - added explicit requirements
  - Fixed: DI factory creates multiple instances - now registered as singletons
  - Fixed: Resolver uses hidden DateTime.now() - now accepts `DateTime now` parameter for testability
  - Fixed: Expired trial detection needs non-active entitlements - added mapping code reading both active + all
  - Fixed: TrialReminderService storage not user-scoped - added key format with userId
  - Fixed: EntitlementSnapshot missing grace period - added `isInGracePeriod` field
  - Added: Design principles 7-9 (singletons, time as dependency, unknown vs none)
  - Added: Completer-based init gate in RevenueCatService

- **2026-01-24 (Round 4):** Re-review identified 4 Critical, 3 Major, 3 Minor issues
  - Fixed: Client interface returns non-null but stub needs null - made `getEntitlementSnapshot()` return `Future<EntitlementSnapshot?>`
  - Fixed: Dropping trial_ends_at breaks handle_new_user() - added Phase 11.2 to update trigger BEFORE dropping columns
  - Fixed: grace state missing from Dart enum and DB constraint - added Phase 1.3/1.4 with grace + DB migration
  - Fixed: Can't distinguish expired-trial vs expired-paid - added `lastPeriodType` field + helper getters to EntitlementSnapshot
  - Fixed: presentPaywall()/refreshEntitlement() not gated on init - added init gate with error handling
  - Fixed: Unknown key suppresses future modals - now returns null (non-cacheable) instead of ':unknown' key
  - Note: DI syntax pseudo-code acknowledged - implementer should use repo's actual DI idioms
  - Note: PeriodType.grace may not exist in SDK - verify against actual purchases_flutter API

- **2026-01-24 (Round 5):** Re-review identified 1 Critical, 9 Major, 2 Minor issues
  - Fixed: Snapshot can be for anonymous user - added `appUserId` field, ignore pre-identify emissions, resolver checks `isForUser()`
  - Fixed: Webhook needs verify_jwt = false - added Phase 9.3 with config.toml
  - Fixed: Mapping code didn't set lastPeriodType in expired case - updated mapping pseudocode
  - Fixed: init() never seeded initial snapshot - identify() now calls refreshEntitlement()
  - Fixed: refreshEntitlement() could clobber known with null - added _updateSnapshotIfBetter()
  - Fixed: _buildDecisionKey return type was String not String? - fixed signature and added null handling
  - Fixed: TrialReminderService hidden clock - now injects Clock and respects decision store
  - Fixed: Webhook missing trial vs paid distinction rule - added Phase 9.7 with explicit logic
  - Fixed: Webhook event coverage incomplete - expanded to include upgrades, transfers, etc.
  - Fixed: macOS purchases_ui_flutter support uncertain - updated platform table with verification note
  - Fixed: Old clients can't parse new enum values - added Phase 1.5 rollout constraint
  - Added: Design principles 10-11 (user-scoped snapshots, never clobber known state)
  - Added: _identifiedUserId tracking in RevenueCatService

- **2026-01-24 (Round 6):** Re-review identified 2 Critical, 5 Major, 3 Minor issues
  - Fixed: appUserId used originalAppUserId instead of identified user - now uses identifiedUserId param
  - Fixed: originalTransactionId mapped to purchase date string - added VERIFY notes for actual SDK field
  - Fixed: _mapPeriodType defaulted unknown to normal - now returns null for unknown
  - Fixed: Paywall could present before identification - added _identifiedUserId check
  - Fixed: init() completer could fire before configure() - made ordering explicit in code
  - Fixed: config.toml syntax uncertain - added alternative deploy flag approach
  - Fixed: CANCELLATION handling unclear - added explicit event table with NO CHANGE for cancellation
  - Added: Phase 8.4 for app resume entitlement refresh
  - Note: Phase numbering and file paths still need cleanup (doc consistency)

- **2026-01-24 (Round 7):** Re-review identified 2 Critical, 2 Major, 5 Minor issues
  - Fixed: Client needs _currentUserId for listener callbacks - added tracking field set by logIn(), cleared by logOut()
  - Fixed: Webhook needs explicit SECURITY DEFINER approach - added Phase 9.1.1 with RPC function and REVOKE/GRANT permissions
  - Fixed: originalTransactionId placeholder assignment - removed placeholders, set to null with VERIFY notes
  - Fixed: Phase 8.4 not using AppLifecycleService properly - refactored to use existing service pattern
  - Fixed: Clock injection redundant - simplified to pure resolver pattern where callers pass `now`
  - Fixed: Wrong file path reference - changed home_view_state.dart to home_state.dart
  - Note: Minor code fence and phase numbering issues remain (doc formatting)

- **2026-01-24 (Round 8):** Re-review identified 1 Critical, 5 Major, 3 Minor issues
  - Fixed: CRITICAL - Webhook RPC callable by any client (privilege escalation) - RPC now ONLY granted to service_role, Edge Function must use SUPABASE_SERVICE_ROLE_KEY
  - Fixed: logIn() set _currentUserId before SDK call - now set AFTER successful Purchases.logIn()
  - Fixed: Listener setup timing unspecified - now called once during configure() with guard flag
  - Fixed: Paywall error can cause navigation loops - added error snackbar and caller responsibility note
  - Fixed: Webhook timestamp tie can drop events - added tie-break rule (apply if different event_id at same timestamp)
  - Fixed: TRANSFER event handling was "TODO" - added Phase 9.7 with explicit update-both-users logic
  - Fixed: BILLING_ISSUE_RESOLVED event missing - added to event table for grace recovery
  - Fixed: Duplicate method declarations in Phase 7.1 - removed duplicates
  - Fixed: Broken code fence around PaywallOutcome - merged into single fence
  - Fixed: Phase numbering duplicates (9.4, 9.7/9.8, 11.3) - renumbered uniquely

- **2026-01-24 (Round 9):** Re-review identified 0 Critical, 4 Major, 3 Minor, 1 Nitpick issues
  - Fixed: Missing restore purchases path - added restorePurchases() to client/service + Phase 5.3 Settings entry point
  - Fixed: AppLifecycleService not instantiated by lazy DI - added as constructor param to StartupViewModel
  - Fixed: grace mapping rules undefined - added explicit mapSnapshotToStatus() with precedence rules
  - Fixed: TRANSFER field names speculative - added fixture requirement + VERIFY notes
  - Fixed: RPC doesn't validate status (retry storms) - added IF check with RAISE EXCEPTION
  - Fixed: Design Principle #8 inconsistent - updated to "Time as explicit parameter" pattern
  - Fixed: Paywall snackbar may not render before back() - added 300ms delay on error
  - Note: DI snippets still use pseudo-DSL (implementer should adapt to repo's actual pattern)

- **2026-01-24 (Round 10):** Re-review identified 0 Critical, 5 Major, 2 Minor issues - **SHIP with polish**
  - Fixed: refreshEntitlement() can throw from lifecycle callbacks - now swallows/logs all exceptions
  - Fixed: "Offline returns null" contradicts cache principle - updated doc to clarify mobile returns cached data
  - Fixed: init() not idempotent - added _initStarted guard, subsequent calls return same future
  - Fixed: Expired "intro" periods treated as "not paid" - intro now maps to "expired" (paid churn UX)
  - Fixed: Webhook needs UUID validation - added UUID_REGEX check before RPC call, return 200 + "ignored"
  - Fixed: mapSnapshotToStatus silently guesses for unknown products - added loud warning log
  - Fixed: File Summary missing migrations - added all migration files including RPC and TRANSFER fixture

- **2026-01-24 (Round 11):** Re-review identified 0 Critical, 2 Major, 3 Minor, 1 Nitpick - **Final polish**
  - Fixed: Trial-expired modal relies on brittle RC periodType - added transition-based detection (lastSeenStatus → free)
  - Fixed: TRANSFER needs UUID validation for BOTH from/to IDs - added validation, self-transfer guard
  - Fixed: EntitlementSnapshot doc still says "offline = null" - clarified mobile caches work offline
  - Fixed: UNCANCELLATION references nonexistent "cancellation flag" - removed flag reference
  - Note: Paywall snackbar timing and DI pseudo-DSL remain as implementation details for repo adaptation

- **2026-01-24 (Round 12):** Re-review identified 0 Critical, 2 Major, 1 Minor, 1 Nitpick
  - Fixed: shouldShowTrialExpiredModal uses effective status (resolver output), not raw snapshot
  - Fixed: Documented CALL ORDER (load lastSeen → compute effective → decide → persist)
  - Fixed: TRANSFER revoke status now deterministic - query current row, map premium/grace→expired, else→free
  - Note: Paywall snackbar and DI pseudo-DSL are repo-specific adaptations (not plan defects)

- **2026-01-24 (Round 13):** **SHIP** - 0 Critical, 0 Major, 2 Minor
  - Fixed: Design Principle #8 clarified to allow both explicit param and injected Clock per layer
  - Fixed: getLastSeenStatus now wraps byName in try/catch (handles enum rename/removal gracefully)
  - Remaining repo-specific: Paywall error surfacing strategy, DI snippet adaptation
