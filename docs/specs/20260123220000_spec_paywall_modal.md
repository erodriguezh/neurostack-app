# Spec: Paywall Modal (RevenueCat Integration)

**Created:** 2026-01-23
**Status:** Draft
**UI Design:** `docs/best_practices/design/screen-prompts/06-paywall-modal.md`

---

## Overview

Full migration to RevenueCat for subscription and trial management. RevenueCat manages:
- Subscription products (monthly, yearly)
- Free trial (7 days attached to subscription, requires payment method)
- Entitlement checking ("Neurostack Pro")
- Native paywall UI (designed in RevenueCat dashboard)

---

## New User Flow

```
1. User installs app
   └── Status: none (can only see onboarding/auth)

2. User registers
   └── Status: free (limited to 2 protocols)

3. User taps "Upgrade" → Paywall
   └── Starts subscription with 7-day trial
   └── Status: trial (full access)

4. 24h before trial ends
   └── Soft reminder alert (dismissible)

5. Trial ends without payment
   └── Trial Expiration Modal (blocking)
   └── Choice: "Keep Premium" (pay) or "Continue Free"

6. User chooses free
   └── Status: free (limited to 2 protocols)
```

---

## Subscription Model

### Products
| Product ID | Price | Trial | Entitlement |
|------------|-------|-------|-------------|
| `neurostack_monthly` | $7.99/mo | 7 days | Neurostack Pro |
| `neurostack_yearly` | $59.99/yr | 7 days | Neurostack Pro |

### Entitlement Mapping
| RevenueCat State | App SubscriptionStatus |
|------------------|------------------------|
| No entitlement | `free` |
| Active + periodType=TRIAL | `trial` |
| Active + monthly product | `premiumMonthly` |
| Active + yearly product | `premiumAnnual` |
| Expired (was active) | `expired` |
| Billing issue (grace) | `grace` |

---

## Invariant Changes

### Removed Invariants

| Code | Old Rule | Reason |
|------|----------|--------|
| INV-U3 | Trial MUST auto-activate on first app launch | Trial now starts on subscription, not registration |
| INV-M3 | Premium Trial MUST NOT require credit card | RevenueCat trials require payment method |

### Modified Invariants

| Code | Old Rule | New Rule |
|------|----------|----------|
| INV-M2 | Premium Trial MUST last exactly 7 days | Premium Trial MUST last exactly 7 days **from subscription start** |
| INV-M4 | After trial expiration, user MUST revert to Free Tier automatically | After trial expiration **without payment**, user MUST revert to Free Tier |

### New Invariants

| Code | Rule |
|------|------|
| INV-P1 | Paywall dismissal without purchase returns to previous screen |
| INV-P2 | Successful purchase updates local User immediately (optimistic) |
| INV-P3 | Webhook is source of truth; client sync is optimistic |
| INV-P4 | Trial reminder shown max once per 24h period |
| INV-P5 | `app_user_id` must match Supabase `auth.uid` |
| INV-P6 | New users MUST start with `free` status (not `trial`) |

### Unchanged Invariants
- INV-M1: Free Tier MUST have no time limit
- INV-M5: Free Tier users CANNOT activate more than 2 protocols
- INV-M6: Premium Trial users MUST see full feature set
- INV-M7: Subscription pricing MUST offer annual discount
- INV-B5: Users MUST be able to use Free Tier indefinitely

---

## Domain Layer Changes

### 1. User Entity (`lib/features/user/domain/entities/user.dart`)

**Remove/Deprecate:**
- `createWithTrial()` factory → Replace with `create()` that starts with `free`
- `trialPeriod` field → No longer needed (RevenueCat tracks trial state)
- `getEffectiveStatus()` → Simplify (no Supabase trial logic)

**Update:**
```dart
// Before: User created with trial
static User createWithTrial({required String id, DateTime? createdAt}) {
  return User._(
    subscriptionStatus: SubscriptionStatus.trial,
    trialPeriod: TrialPeriod.startNow(),
    // ...
  );
}

// After: User created with free status
static User create({required String id, DateTime? createdAt}) {
  return User._(
    subscriptionStatus: SubscriptionStatus.free,
    trialPeriod: null, // RevenueCat manages trial
    // ...
  );
}
```

### 2. TrialPeriod Value Object (`lib/features/user/domain/value_objects/trial_period.dart`)

**Action:** Delete
- RevenueCat's `CustomerInfo.entitlements.active["Neurostack Pro"].expirationDate` replaces this
- No users to migrate (app under construction)

### 3. SubscriptionStatus Enum (`lib/features/user/domain/enums/subscription_status.dart`)

**No changes to enum values**, but update documentation:
```dart
enum SubscriptionStatus {
  /// On RevenueCat trial (7 days from subscription start).
  /// Requires active subscription with trial period.
  trial(protocolLimit: null, canAccessPremium: true),

  /// Free tier with 2 protocol limit. Default for new users.
  free(protocolLimit: 2, canAccessPremium: false),

  // ... rest unchanged
}
```

### 4. UserBootstrapService (`lib/features/auth/data/user_bootstrap_service.dart`)

**Update:** New user creation
```dart
// Before
final newUser = User.createWithTrial(id: userId, createdAt: authCreatedAt);

// After
final newUser = User.create(id: userId, createdAt: authCreatedAt);
```

### 5. UserDto (`lib/features/user/data/dtos/user_dto.dart`)

**Update:** Make `trial_period` nullable, handle missing field gracefully

### 6. Database Schema

**Migration:** Remove trial columns (no users to migrate)
```sql
ALTER TABLE users DROP COLUMN IF EXISTS trial_ends_at;
ALTER TABLE users DROP COLUMN IF EXISTS trial_expired_at;
```

---

## Customer Identification

**Pattern:** `app_user_id` = Supabase `auth.uid`

### Flow
```
App Launch
    |
Supabase Auth Check
    |
+-- Logged in --> Purchases.logIn(supabaseUserId)
+-- Not logged in --> Anonymous (RevenueCat auto-generates ID)
    |
On Logout --> Purchases.logOut()
```

**Integration Point:** `lib/features/auth/data/auth_service.dart`
- After `_rehydrateFromSession()` succeeds (line 217)
- Before `logout()` completes (line 89)

---

## Paywall Entry Points

| Entry Point | Trigger | Location |
|-------------|---------|----------|
| Trial Expired Modal | "Keep Everything" tap | `lib/home/home_view.dart:347` |
| Library Protocol Detail | "Upgrade to Add" tap | `lib/library/library_view_model.dart:154` |
| Library Card | Locked protocol tap | `lib/library/library_ui.dart:20` |
| Home Banner | Trial/expired banner tap | `lib/home/home_view_model.dart:113` |

All call `goToPaywall()` -> `/paywall` route -> RevenueCat paywall presentation.

---

## Trial Reminder (24h Warning)

**Trigger:** RevenueCat trial expires within 24 hours
**UI:** Dismissible soft alert (not blocking)
**Frequency:** Once per day maximum

### Detection
```dart
bool shouldShowReminder(CustomerInfo info) {
  final entitlement = info.entitlements.active['Neurostack Pro'];
  if (entitlement == null) return false;
  if (entitlement.periodType != PeriodType.trial) return false;

  final expirationDate = entitlement.expirationDate;
  if (expirationDate == null) return false;

  final hoursRemaining = expirationDate.difference(DateTime.now()).inHours;
  return hoursRemaining <= 24 && hoursRemaining > 0;
}
```

---

## Trial Expiration Modal

**Trigger:** User had active trial, now has no entitlement
**UI:** Blocking modal (existing `TrialExpiredModal`)
**Behavior:** Must choose "Keep Premium" or "Continue Free"

### Detection
```dart
bool shouldShowTrialExpiredModal(CustomerInfo info) {
  // No active entitlement
  final hasEntitlement = info.entitlements.active.containsKey('Neurostack Pro');
  if (hasEntitlement) return false;

  // But previously had trial (check non-active entitlements or transaction history)
  final allEntitlements = info.entitlements.all['Neurostack Pro'];
  if (allEntitlements == null) return false;

  // Had trial that is now expired
  return allEntitlements.periodType == PeriodType.trial &&
         !allEntitlements.isActive;
}
```

---

## Webhook Architecture

**Flow:** `RevenueCat -> Supabase Edge Function -> Update DB`

### Events to Handle
| Event | Action |
|-------|--------|
| `INITIAL_PURCHASE` | Set `trial` or `premiumMonthly`/`premiumAnnual` |
| `RENEWAL` | Maintain premium status |
| `CANCELLATION` | Schedule `expired` at period end |
| `BILLING_ISSUE` | Set `grace` |
| `EXPIRATION` | Set `free` |

### Edge Function Requirements
- **Idempotent:** May be called multiple times for same event
- **Fast:** Return 200 quickly, defer heavy processing
- **Secure:** Verify webhook signature

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| RevenueCat SDK init fails | Log warning, continue (paywall unavailable) |
| Paywall presentation fails | Show error toast, return to previous screen |
| Purchase fails | RevenueCat shows native error, no app-level handling |
| Webhook fails | Retry via RevenueCat, client falls back to SDK state |
| Network offline | Use cached CustomerInfo, defer sync |

---

## SDK Reference

### Installing dependencies

```sh
flutter pub add purchases_flutter purchases_ui_flutter
```

### API Key Access

```dart
const String.fromEnvironment(
  'REVENUECAT_API_KEY',
  defaultValue: '',
)
```

### Initialize SDK

```dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> initializeRevenueCat() async {
  String apiKey = const String.fromEnvironment('REVENUECAT_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError('REVENUECAT_API_KEY not configured');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}
```

### Check Entitlement

```dart
CustomerInfo customerInfo = await Purchases.getCustomerInfo();
final hasPro = customerInfo.entitlements.active.containsKey('Neurostack Pro');
```

### Present Paywall

```dart
final paywallResult = await RevenueCatUI.presentPaywall();
```

---

## Testing

### Unit Tests
- Entitlement -> SubscriptionStatus mapping
- Trial reminder timing logic (RevenueCat expirationDate)
- Customer identification flow

### Integration Tests
- Fresh user starts with `free` status
- Subscription with trial -> `trial` status
- Trial expiration -> modal appears
- Webhook -> DB update

### Manual Verification
- Sandbox purchase flow
- Trial expiration -> modal
- Webhook -> DB update
