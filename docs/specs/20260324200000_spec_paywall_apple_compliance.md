# Spec: Paywall Apple Compliance

**Created:** 2026-03-24
**Status:** Draft
**Epic:** `fn-81-paywall-apple-compliance`
**Parent spec:** `docs/specs/20260123220000_spec_paywall_modal.md`
**Investigation:** `docs/investigations/20260324_revenuecat_paywall_apple_compliance.md`

---

## Overview

The published RevenueCat hosted paywall and the app Settings screen do not meet Apple App Store requirements for subscription apps. This spec defines the compliance gaps, required changes, and acceptance criteria.

### Apple requirements (citations)

- **Guideline 3.1.1** — App must include a restore mechanism for any restorable in-app purchases
- **Guideline 3.1.2** — Before asking a customer to subscribe, clearly describe what the user gets for the price; disclose subscription name, duration, price, and how to cancel
- **Guideline 3.1.2(a)** — Free trial: clearly indicate duration AND the price billed when trial ends
- **Guideline 5.1.1(i)** — All apps must include a Privacy Policy link in App Store Connect metadata AND within the app
- **Schedule 2, Section 3.8(b)** — Auto-renewal disclosure: payment charge, renewal terms, cancellation window, trial forfeiture
- **Apple Subscriptions page** — Full renewal price must be the most prominent pricing element; restore mechanism required for current/past subscribers

### Current state (deficiencies)

| # | Issue | Evidence |
|---|-------|----------|
| 1 | Paywall has no Restore Purchases button | API expand of `pw3847f37f3e364dad` components: only 2 buttons ("Subscribe", "Continue with Free") |
| 2 | Paywall has no Privacy Policy link | No `navigate_to` button with privacy URL in component tree |
| 3 | Paywall has no Terms of Use link | No `navigate_to` button with terms URL in component tree |
| 4 | Paywall has no auto-renewal disclosure text | No disclosure text component in paywall footer |
| 5 | No Restore Purchases in Settings | `lib/settings/widgets/settings_support_section.dart:48-165` — 5 tiles, no Restore |
| 6 | "Cancel Subscription" label is misleading | `settings_support_section.dart:80` — action opens subscription management, not just cancellation |
| 7 | Trial duration mismatch | `lib/paywall/paywall_constants.dart:11-12` says 7-day trial; live products return `trial_duration: null` |
| 8 | All products wired to Test Store only | `GET /projects/proj2eeae544/products?app_id=appaea2f089fd` returns empty list |
| 9 | ASC API key not configured | `app_store.app_store_connect_api_key_configured: false` |
| 10 | Paywall named "Untitled Paywall" | `GET /projects/proj2eeae544/paywalls` → `name: "Untitled Paywall"` |

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Restore Purchases tile visibility | Always visible to ALL users | Apple requires restore for anyone with restorable purchases; hiding behind premium gate would fail review |
| Manage Subscription tile visibility | Visible when `canAccessPremium` (premium + trial) | Trial users need a path to cancel before being charged |
| Privacy Policy URL | `https://getneurostack.app` (temporary) | Actual legal text pages coming in a future task |
| Terms of Use URL | `https://getneurostack.app` (temporary) | Same as above |
| 7-day free trial | Both monthly and yearly plans | User decision; both in same subscription group, one trial per group |
| Callback rename | `onCancelSubscriptionTap` → `onManageSubscriptionTap` | Code clarity — action is broader than cancellation |
| Restore on web | Hidden (tile not shown) | `RevenueCatClientStub.restorePurchases()` is a no-op; restore is meaningless on web |
| App Store product wiring | Phase 2 (can defer) | Independent of Test Store polish; zero code overlap |

---

## Changes Required

### A. Hosted Paywall (RevenueCat Dashboard)

Add the following Paywall Components to `pw3847f37f3e364dad`:

| Component | Type | Action | Content |
|-----------|------|--------|---------|
| Restore Purchases | Button | `restore_purchases` | "Restore Purchases" |
| Privacy Policy | Button | `navigate_to` → `https://getneurostack.app` | "Privacy Policy" |
| Terms of Use | Button | `navigate_to` → `https://getneurostack.app` | "Terms of Use" |
| Auto-renewal disclosure | Text | — | See §Disclosure Copy below |
| Cancellation guide | Text | — | See §Disclosure Copy below |

- Rename paywall from "Untitled Paywall" to "Neurostack Pro"
- Verify no delayed close button (Apple rejects these; see RevenueCat components docs)
- Verify pricing uses dynamic variables (`{{ product.price_per_period_abbreviated }}`)
- If trials configured: add trial text via `{{ product.offer_period_with_unit }}` free, then `{{ product.price_per_period }}`
- Republish paywall after changes

#### Disclosure Copy

**Auto-renewal disclosure** (small text, paywall footer):
> Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage in app Settings → Manage Subscription.

**Cancellation guide** (same text block or separate):
> To cancel: Open the app → Settings → Manage Subscription → Select Neurostack → Cancel Subscription and confirm.

### B. Test Store Products (RevenueCat Dashboard)

- Set `trial_duration: P7D` on `neurostack_monthly` (product `prod173ebea3fe`, app `app37554ace9b`)
- Set `trial_duration: P7D` on `neurostack_yearly` (product `prodb81e70d11e`, app `app37554ace9b`)
- Verify via API: `GET /projects/proj2eeae544/products?app_id=app37554ace9b&limit=20`

### C. Settings Screen (Code)

#### C.1 Add Restore Purchases tile

- **File:** `lib/settings/widgets/settings_support_section.dart`
  - Add new `_TileEntry` for "Restore Purchases" (cite: `settings_support_section.dart:48-165` for tile pattern)
  - Icon: `LucideIcons.rotateCcw` (or similar)
  - Trailing: none (in-app action, not external)
  - Visibility: always visible (not gated on premium/trial/web)
  - Position: above "Manage Subscription" tile
  - Hide on web (`kIsWeb`)
- **File:** `lib/settings/widgets/settings_support_section.dart`
  - Add `VoidCallback onRestorePurchasesTap` parameter
- **File:** `lib/settings/settings_view.dart`
  - Wire `onRestorePurchasesTap: _viewModel.restorePurchases` (cite: `settings_view.dart:107-116` for wiring pattern)

#### C.2 Add restorePurchases() to SettingsViewModel

- **File:** `lib/settings/settings_view_model.dart`
  - Inject `NotifyService` via constructor (cite: `lib/settings/rate_app/rate_app_view_model.dart` for injection pattern)
  - Add `bool _isRestoring = false` guard (cite: `_isPresenting` in `lib/paywall/paywall_view_model.dart`)
  - Add `Future<void> restorePurchases()` method:
    - Guard: if `_isRestoring`, return (prevents concurrent calls)
    - Call `_revenueCatService.restorePurchases()` → returns `Future<bool>` (cite: `lib/paywall/data/revenuecat_service.dart:340-363`)
    - After restore, check entitlement state to determine toast:
      - `true` + entitlement active → `ToastEventSuccess(message: 'Purchases restored successfully')`
      - `true` + no entitlement → `ToastEventInfo(message: 'No previous purchases found')`
      - `false` or exception → `ToastEventError(message: 'Unable to restore purchases. Please try again.')`
    - Guard disposal: check `_isDisposed` before showing toast (cite: existing disposal pattern in SettingsViewModel)
  - Toast events: cite `lib/core/utils/internal_notification/toast/toast_event.dart`
  - NotifyService: cite `lib/core/utils/internal_notification/notify_service.dart`

#### C.3 Rename Cancel Subscription → Manage Subscription

- **File:** `lib/settings/widgets/settings_support_section.dart`
  - Line 80: change label `'Cancel Subscription'` → `'Manage Subscription'`
  - Rename parameter `onCancelSubscriptionTap` → `onManageSubscriptionTap`
  - Change visibility from `isPremium` to `canAccessPremium` (includes trial users)
    - Requires exposing `canAccessPremium` from SettingsViewModel (cite: `SubscriptionStatus.canAccessPremium` at `lib/features/user/domain/enums/subscription_status.dart`)
- **File:** `lib/settings/settings_view.dart`
  - Line 116: rename `onCancelSubscriptionTap:` → `onManageSubscriptionTap:` in wiring
- **File:** `lib/settings/settings_view_model.dart`
  - Expose `ValueNotifier<bool> canAccessPremium` (or derive from existing subscription state)

#### C.4 Update SettingsView constructor wiring

- **File:** `lib/settings/settings_view.dart`
  - Pass `locator<NotifyService>()` to SettingsViewModel constructor (cite: `settings_view.dart:33-41` for existing locator pattern)

### D. Test Store Trial Configuration

- Configure `trial_duration: P7D` on both RevenueCat Test Store products (see §B above)

### E. Docs and Specs Updates

| File | Change | Citation |
|------|--------|----------|
| `docs/specs/20260227120000_spec_settings_screen.md:171-176` | Remove "Restore Purchases tile (not included)" from out-of-scope; add Restore tile row to §4 tile table | Settings spec out-of-scope section |
| `docs/specs/20260227120000_spec_settings_screen.md:13,14,85,87,117,142` | Replace all "Cancel Subscription" → "Manage Subscription" | Settings spec throughout |
| `docs/specs/20260227120000_spec_settings_screen.md:156` | Update dependency note: "Manage Subscription + Send Feedback mailto" | Settings spec dependencies |
| `docs/best_practices/design/screen-prompts/11-settings-screen.md:46` | Add Restore Purchases row, rename Cancel→Manage in tile table | Settings screen prompt |
| `docs/best_practices/design/screen-prompts/06-paywall-modal.md` | Note compliance elements (Restore, Privacy, Terms, disclosure) on hosted paywall | Paywall screen prompt |
| `docs/best_practices/design/screen-prompts/01-on-boarding-3.md:38` | Flag "No credit card required" as inaccurate for App Store trials | Onboarding screen prompt |
| `docs/ubiquitous-language.md:270` | Update Settings examples: add "Restore Purchases", rename "Cancel Subscription" → "Manage Subscription" | Ubiquitous language |
| `docs/ubiquitous-language.md:121-124` | Annotate INV-M2: trial_duration was null until fn-81 | Ubiquitous language invariant |
| `plan_settings_screen.md:113-116` | Annotate: "Restore removed per spec" decision reversed by fn-81 | Settings plan §2.2 |
| `plan_settings_screen.md:186,310` | Rename Cancel → Manage | Settings plan §3.6, testing notes |
| `plan_paywall_modal.md` Section 5.3 | Correct false [DONE] status — Restore was never implemented, re-opened by fn-81 | Paywall plan |
| `lib/paywall/paywall_constants.dart:11-12` | Update 7-day trial comments to match actual configured state | Code comments |

### F. Close Zombie Epic

- Close `fn-46-1b8` ("Phase 5.3: Add Restore Purchases Entry Point") — marked done but never implemented; scope absorbed by this spec
- Command: `.flow/bin/flowctl epic close fn-46-1b8 --reason "Absorbed by fn-81-paywall-apple-compliance"`

---

## Invariant Changes

### New Invariants

| Code | Rule |
|------|------|
| INV-P7 | Paywall MUST include a Restore Purchases button (Apple Guideline 3.1.1) |
| INV-P8 | Paywall MUST include Privacy Policy and Terms of Use links (Apple Guidelines 5.1.1, Schedule 2 §3.8(b)) |
| INV-P9 | Paywall MUST include auto-renewal disclosure text (Apple Schedule 2 §3.8(b)) |
| INV-SET3 | Settings MUST include a Restore Purchases tile visible to ALL users (Apple Guideline 3.1.1) |
| INV-SET4 | Manage Subscription tile MUST be visible when `canAccessPremium` is true (premium + trial users) |

### Modified Invariants

| Code | Old Rule | New Rule |
|------|----------|----------|
| INV-M2 | Premium Trial MUST last exactly 7 days from subscription start | (unchanged, but annotate: `trial_duration` was `null` on live products until fn-81 configured it) |

### Deprecated Terms

| Old | New | Reason |
|-----|-----|--------|
| Cancel Subscription (UI label) | Manage Subscription | Action opens subscription management, not just cancellation |
| `onCancelSubscriptionTap` (code) | `onManageSubscriptionTap` | Consistency with new label |

---

## Phase 2: App Store Wiring (can defer)

These steps are required before App Store submission but independent of Phase 1.

### G. Create App Store Connect Products

- Create subscription group "Neurostack Pro" in App Store Connect
- Create `neurostack_monthly` (1 Month, pricing TBD, 7-day Introductory Offer)
- Create `neurostack_yearly` (1 Year, pricing TBD, 7-day Introductory Offer)
- Product IDs must match RevenueCat identifiers exactly (case-sensitive)
- Submit products for review
- Allow 24 hours for propagation after approval

### H. Configure ASC API Key + Wire Products in RevenueCat

- Generate App Store Connect API key (App Manager role minimum)
- Upload .p8 key to RevenueCat App Store app (`appaea2f089fd`)
- Import `neurostack_monthly` and `neurostack_yearly` from App Store Connect
- Attach to packages `$rc_monthly` (`pkge9556a58aac`) and `$rc_annual` (`pkge6aeaf41ae6`)
- Attach to entitlement "Neurostack Pro" (`entl21aba2a7b0`)
- Republish paywall

---

## Testing

### Unit Tests (Code — Phase 1)

- `test/settings/settings_view_model_test.dart`:
  - `restorePurchases()` calls `revenueCatService.restorePurchases()`
  - Success + entitlement → success toast
  - Success + no entitlement → info toast
  - Failure → error toast
  - Double-tap guard: second call while `_isRestoring` is ignored
  - Disposal guard: toast not fired after dispose
  - "Manage Subscription" label renders (was "Cancel Subscription")
  - Restore tile always visible; Manage tile visible when `canAccessPremium`
- Use `MockRevenueCatService` from `test/mocks/mock_services.dart:43`
- Use `MockNotifyService` (create if not exists)
- `FakeRevenueCatClient` at `test/mocks/fake_revenuecat_client.dart:25` tracks `restorePurchasesWasCalled`

### Manual Verification (E2E — after all tasks)

- Paywall: verify Restore, Privacy, Terms, disclosure, pricing, trial terms, dismiss button
- Settings: verify Restore tile (all users), Manage tile (premium + trial), toast messages
- API: verify paywall components, product trial_duration

---

## Out of Scope

- Custom/local paywall UI (using RevenueCat hosted paywall)
- Privacy Policy / Terms of Use page content (separate future task — URLs are placeholder)
- Trial eligibility checking (`checkTrialOrIntroductoryEligibility()` — RevenueCat handles automatically)
- Server-side entitlement validation
- Paywall A/B testing or multiple offerings
- Android-specific compliance (Google Play has different requirements)

---

## Dependencies

- `purchases_flutter: ^9.10.7` — already in `pubspec.yaml`
- `purchases_ui_flutter: ^9.10.7` — already in `pubspec.yaml`
- `RevenueCatService.restorePurchases()` — exists at `lib/paywall/data/revenuecat_service.dart:340-363`
- `NotifyService` — exists at `lib/core/utils/internal_notification/notify_service.dart`
- `PremiumAwareViewModelMixin` — exists at `lib/core/abstractions/premium_aware_view_model_mixin.dart`

---

## References

- Investigation: `docs/investigations/20260324_revenuecat_paywall_apple_compliance.md`
- Parent spec: `docs/specs/20260123220000_spec_paywall_modal.md`
- Settings spec: `docs/specs/20260227120000_spec_settings_screen.md`
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Subscriptions: https://developer.apple.com/app-store/subscriptions/
- RevenueCat paywall components: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/components
- RevenueCat app review guide: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/app-review
- RevenueCat launch checklist: https://www.revenuecat.com/docs/test-and-launch/launch-checklist
