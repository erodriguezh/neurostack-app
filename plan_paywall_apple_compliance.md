# Implementation Plan: Paywall Apple Compliance

**Spec:** `docs/specs/20260324200000_spec_paywall_apple_compliance.md`
**Investigation:** `docs/investigations/20260324_revenuecat_paywall_apple_compliance.md`
**Epic:** `fn-81-paywall-apple-compliance`

---

## Phase 1 — Fix Hosted Paywall in RevenueCat Dashboard [PORTAL]

> Manual task — step-by-step guide for the RevenueCat dashboard.
> **Flow task:** `fn-81-paywall-apple-compliance.1`

### 1.1 Rename the paywall

- Open RevenueCat dashboard → Project "Neurostack" → Paywalls → "Untitled Paywall" → Edit
- Click the paywall name at the top, rename to **"Neurostack Pro"**
- Cite: `GET /projects/proj2eeae544/paywalls` → `name: "Untitled Paywall"` (spec §Current state #10)

### 1.2 Add Restore Purchases button

- In the paywall editor, add a **Button** component in the footer area (below "Subscribe")
- Set button text: `Restore Purchases`
- In the button properties panel (top-right), set **Action** to **"Restore Purchases"**
- Style: small/subtle text, not a primary button — positioned near legal links
- Cite: Apple Guideline 3.1.1; spec §A; RevenueCat components docs confirm Button → "Restore Purchases" action

### 1.3 Add Privacy Policy link

- Add a **Button** component near the footer
- Set text: `Privacy Policy`
- Set **Action** to **"Navigate to"** → URL: `https://getneurostack.app`
- Set open mode: "In-App Browser" or "External Browser"
- Cite: Apple Guideline 5.1.1(i); spec §A; spec §Decisions (temporary URL)

### 1.4 Add Terms of Use link

- Add a **Button** component next to Privacy Policy
- Set text: `Terms of Use`
- Set **Action** to **"Navigate to"** → URL: `https://getneurostack.app`
- Cite: Apple Schedule 2, Section 3.8(b); spec §A

### 1.5 Add auto-renewal disclosure text

- Add a **Text** component below the legal links, small font (~10-11pt), muted color
- Content (spec §Disclosure Copy):
  > Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage in app Settings → Manage Subscription.
- Cite: Apple Schedule 2, Section 3.8(b); spec §A

### 1.6 Add cancellation guide text

- Same text block or separate Text component:
  > To cancel: Open the app → Settings → Manage Subscription → Select Neurostack → Cancel Subscription and confirm.
- Cite: spec §A; user decision #6

### 1.7 Verify no delayed close button

- Check the "Continue with Free" (back/dismiss) button — confirm NO delay is configured
- RevenueCat warns: "Delayed close buttons may be rejected during Apple's App Review"
- Cite: spec §A; RevenueCat components docs; investigation Phase 4

### 1.8 Verify pricing variables

- Confirm price displays use dynamic RevenueCat variables:
  - `{{ product.price_per_period_abbreviated }}` for price
  - `{{ product.periodly | capitalize }}` for period
- If trial is configured (Phase 2): add trial text using `{{ product.offer_period_with_unit }}` free, then `{{ product.price_per_period }}`
- Cite: spec §A; practice-scout findings (never hardcode pricing)

### 1.9 Configure 7-day trial on Test Store products

- Navigate to Products in RevenueCat dashboard
- Find `neurostack_monthly` (Test Store) → Edit → set **Trial Duration** to **7 days** (P7D) → Save
- Find `neurostack_yearly` (Test Store) → Edit → set **Trial Duration** to **7 days** (P7D) → Save
- Cite: spec §B; user decision #2; `lib/paywall/paywall_constants.dart:11-12` (comments assume 7-day trial)
- Verify via API:
  ```bash
  .claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=app37554ace9b&limit=20"
  # Both products should show subscription.trial_duration: "P7D"
  ```

### 1.10 Publish the paywall

- Click **Publish** to make all changes live
- The SDK picks up the new paywall immediately
- Cite: spec §A

---

## Phase 2 — Add Restore Purchases to Settings + Rename Manage Subscription [CODE]

> **Flow task:** `fn-81-paywall-apple-compliance.2`
> **Parallel with Phase 1** — no file overlap.

### 2.1 Inject NotifyService into SettingsViewModel

- **File:** `lib/settings/settings_view_model.dart`
- Add `NotifyService _notifyService` constructor parameter
  - Cite: `lib/settings/rate_app/rate_app_view_model.dart` for NotifyService injection pattern
  - Cite: `lib/core/utils/internal_notification/notify_service.dart` for NotifyService interface
- **File:** `lib/settings/settings_view.dart`
  - Pass `locator<NotifyService>()` to SettingsViewModel constructor
  - Cite: `settings_view.dart:33-41` for existing locator wiring pattern

### 2.2 Add restorePurchases() method to SettingsViewModel

- **File:** `lib/settings/settings_view_model.dart`
- Add `bool _isRestoring = false` guard
  - Cite: `_isPresenting` pattern in `lib/paywall/paywall_view_model.dart`
- Add `Future<void> restorePurchases()` method:
  - If `_isRestoring`, return immediately (prevents concurrent calls)
  - Set `_isRestoring = true`
  - Call `_revenueCatService.restorePurchases()` → returns `Future<bool>`
    - Cite: `lib/paywall/data/revenuecat_service.dart:340-363`
  - After restore, determine toast:
    - `true` + entitlement active → `ToastEventSuccess(message: 'Purchases restored successfully')`
    - `true` + no entitlement → `ToastEventInfo(message: 'No previous purchases found')`
    - `false` or exception → `ToastEventError(message: 'Unable to restore purchases. Please try again.')`
    - Cite: `lib/core/utils/internal_notification/toast/toast_event.dart` for toast types
  - Check `_isDisposed` before showing toast (guard against navigation-during-async)
    - Cite: existing disposal pattern in SettingsViewModel
  - Set `_isRestoring = false` in finally block
- Entitlement check after restore:
  - Read `_revenueCatService.entitlementSnapshot.value`
  - Check if it maps to an active subscription status via existing resolution
  - Cite: `lib/paywall/data/revenuecat_service.dart` entitlementSnapshot

### 2.3 Rename Cancel Subscription → Manage Subscription

- **File:** `lib/settings/widgets/settings_support_section.dart`
  - Line 80: change label `'Cancel Subscription'` → `'Manage Subscription'`
    - Cite: spec §C.3; `settings_support_section.dart:80`
  - Rename parameter `onCancelSubscriptionTap` → `onManageSubscriptionTap`
    - Cite: spec §Decisions (callback rename); `settings_support_section.dart` parameter declaration
  - Change visibility from `isPremium` to `canAccessPremium`
    - Cite: spec §Decisions (trial users); `lib/features/user/domain/enums/subscription_status.dart` (`canAccessPremium` property)
- **File:** `lib/settings/settings_view.dart`
  - Line 116: rename `onCancelSubscriptionTap:` → `onManageSubscriptionTap:`
    - Cite: `settings_view.dart:107-116` wiring section

### 2.4 Expose canAccessPremium from SettingsViewModel

- **File:** `lib/settings/settings_view_model.dart`
- Add `ValueNotifier<bool> canAccessPremium` (drives Manage Subscription visibility)
- Initialize synchronously from current subscription state (same pattern as `isPremium`)
  - Cite: `lib/core/abstractions/premium_aware_view_model_mixin.dart` for `isPremium` pattern
  - Cite: `lib/features/user/domain/enums/subscription_status.dart` for `canAccessPremium` getter
- Update in `onEntitlementChanged()` callback alongside `isPremium`
- Dispose in `dispose()` method

### 2.5 Add Restore Purchases tile to SettingsSupportSection

- **File:** `lib/settings/widgets/settings_support_section.dart`
  - Add new `_TileEntry` for "Restore Purchases":
    - Icon: `LucideIcons.rotateCcw` (or `LucideIcons.refreshCcw`)
    - Label: `'Restore Purchases'`
    - Trailing: `LucideIcons.chevronRight` (in-app action)
    - Visibility: always visible, EXCEPT on web (`!kIsWeb`)
    - Position: above "Manage Subscription" tile (tile #5, before tile #6)
    - Cite: spec §C.1; `settings_support_section.dart:48-165` for tile pattern
  - Add `VoidCallback onRestorePurchasesTap` parameter
- **File:** `lib/settings/settings_view.dart`
  - Wire `onRestorePurchasesTap: _viewModel.restorePurchases`
    - Cite: `settings_view.dart:107-116` for wiring pattern

### 2.6 Tests

- **File:** `test/settings/settings_view_model_test.dart`
  - Cite: existing test file (652 lines) for patterns
  - Cite: `test/mocks/mock_services.dart:43` for `MockRevenueCatService`
  - Cite: `test/mocks/fake_revenuecat_client.dart:25` for `FakeRevenueCatClient.restorePurchasesWasCalled`
  - Add or create `MockNotifyService` (check if it exists in `test/mocks/`)
  - Test cases:
    - `group('restorePurchases', () { ... })`:
      - Calls `revenueCatService.restorePurchases()`
      - Success + entitlement → success toast via `notifyService.setToastEvent()`
      - Success + no entitlement → info toast
      - Failure → error toast
      - Double-tap: second call while `_isRestoring` is ignored (verify `restorePurchases` called only once)
      - Disposal: toast not fired after `viewModel.dispose()`
    - Update existing tests:
      - Rename "Cancel Subscription" → "Manage Subscription" in widget assertions
      - Cite: `test/settings/widgets/settings_brightness_test.dart:268` — `find.text('Cancel Subscription')` must become `find.text('Manage Subscription')`
    - Verify Restore tile always visible, Manage tile visible when `canAccessPremium`
- Run `flutter analyze` — must be clean
- Run `flutter test test/settings/` — all pass

### Source references for patterns
- SettingsViewModel: `lib/settings/settings_view_model.dart:23-223`
- SettingsSupportSection: `lib/settings/widgets/settings_support_section.dart:13-165`
- SettingsView wiring: `lib/settings/settings_view.dart:107-116`
- SettingsTile widget: `lib/settings/widgets/settings_tile.dart:15-100`
- RevenueCatService.restorePurchases(): `lib/paywall/data/revenuecat_service.dart:340-363`
- NotifyService: `lib/core/utils/internal_notification/notify_service.dart`
- Toast events: `lib/core/utils/internal_notification/toast/toast_event.dart`
- PremiumAwareViewModelMixin: `lib/core/abstractions/premium_aware_view_model_mixin.dart:50-172`
- EntitlementListenerMixin: `lib/core/abstractions/entitlement_listener_mixin.dart:15-46`

---

## Phase 3 — Update Specs and Docs [CODE]

> **Flow task:** `fn-81-paywall-apple-compliance.3`
> **Depends on:** Phase 2 (needs final naming/decisions)

### 3.1 Update Settings spec

- **File:** `docs/specs/20260227120000_spec_settings_screen.md`
- Lines 171-176 (Out of Scope): Remove "Restore Purchases tile (not included)" — use struck-through pattern:
  `~~Restore Purchases tile (not included)~~ — Added in fn-81-paywall-apple-compliance`
  - Cite: spec §Out of Scope; same file uses `~~Wiredash~~` pattern at line 174
- Line 13: `Cancel Subscription hidden` → `Manage Subscription hidden`
- Line 14: `Cancel Subscription visible` → `Manage Subscription visible`
- Line 85: Tile table row: `Cancel Subscription` → `Manage Subscription`; add row #6 for "Restore Purchases" (Always visible)
- Line 87: Note: rename Cancel → Manage; add Restore description
- Line 117: `Cancel Subscription visibility` → `Manage Subscription visibility`; note: now gated on `canAccessPremium` not `isPremium`
- Line 142: `Cancel Subscription tile visibility` → `Manage Subscription tile visibility`
- Line 156: `Cancel Subscription + Send Feedback mailto` → `Manage Subscription + Send Feedback mailto`

### 3.2 Update Settings screen prompt

- **File:** `docs/best_practices/design/screen-prompts/11-settings-screen.md`
- Line 46: Tile table — rename Cancel→Manage, add "Restore Purchases | rotateCcw | chevron-right | Always (not web)"
  - Cite: spec §C.1

### 3.3 Update Paywall screen prompt

- **File:** `docs/best_practices/design/screen-prompts/06-paywall-modal.md`
- Add note that the hosted paywall now includes compliance elements:
  - Restore Purchases button, Privacy Policy link, Terms of Use link, auto-renewal disclosure
  - Cite: spec §A

### 3.4 Flag onboarding screen prompt

- **File:** `docs/best_practices/design/screen-prompts/01-on-boarding-3.md`
- Line 38: Flag "No credit card required" as inaccurate for App Store trials (Apple requires payment method)
  - Cite: spec §Invariant Changes (INV-M3 deprecated)

### 3.5 Update ubiquitous language

- **File:** `docs/ubiquitous-language.md`
- Line 270: Update Settings examples from "Contact Us, Send Feedback, Rate the App, Feature Request, Cancel Subscription" → add "Restore Purchases", rename "Cancel Subscription" → "Manage Subscription"
  - Cite: spec §C.1, §C.3
- Lines 121-124 (INV-M2): Annotate that `trial_duration` was `null` on live RevenueCat products until fn-81 configured it
  - Cite: investigation Phase 3 (trial mismatch evidence)

### 3.6 Update Settings plan

- **File:** `plan_settings_screen.md`
- Lines 113-116 (§2.2): Annotate that "Restore Purchases removed per spec" decision was reversed by fn-81-paywall-apple-compliance
  - Cite: spec §Decisions
- Line 186: Tile table — rename Cancel → Manage
- Line 310: Testing notes — rename "Cancel Subscription tile only renders for premium users" → "Manage Subscription tile renders for canAccessPremium users"

### 3.7 Correct Paywall plan

- **File:** `plan_paywall_modal.md`
- Section 5.3 ("Add Restore Purchases Entry Point"): Change `[DONE]` → annotate: "Marked [DONE] but never implemented. Scope absorbed by fn-81-paywall-apple-compliance. See `docs/specs/20260324200000_spec_paywall_apple_compliance.md`"
  - Cite: investigation root cause #2; epic-scout finding on fn-46-1b8

### 3.8 Update paywall constants comments

- **File:** `lib/paywall/paywall_constants.dart`
- Lines 11-12: Update "7-day trial" comments to say trial is now configured (P7D) on Test Store products as of fn-81; App Store products pending Phase 2
  - Cite: spec §B; investigation root cause #3

### 3.9 Close zombie epic fn-46-1b8

- Run: `.flow/bin/flowctl epic close fn-46-1b8 --reason "Absorbed by fn-81-paywall-apple-compliance.2"`
- Or via flowctl: `$FLOWCTL epic close fn-46-1b8 ...`
  - Cite: epic-scout finding — fn-46-1b8 marked done but never implemented

### 3.10 Update docs/README.md

- **File:** `docs/README.md`
- Add spec link under Feature Specs:
  `- [Spec: Paywall Apple Compliance](./specs/20260324200000_spec_paywall_apple_compliance.md) - Apple compliance, Restore Purchases, Privacy Policy, Terms of Use, auto-renewal disclosure, trial config`
- Add plan link under Implementation Plans:
  `- [Plan: Paywall Apple Compliance](../plan_paywall_apple_compliance.md) - Apple compliance fixes, Settings Restore tile, Manage Subscription rename, docs updates`

---

## Phase 4 — End-to-End Verification with Test Store [VERIFY]

> Manual testing task.
> **Flow task:** `fn-81-paywall-apple-compliance.4`
> **Depends on:** Phases 1, 2, 3

### 4.1 Paywall verification

- Open the app → trigger the paywall (tap Upgrade or hit the paywall gate)
- Verify the paywall shows:
  - Subscription prices (dynamic, not hardcoded)
  - Billing periods ("Monthly", "Yearly")
  - 7-day free trial terms (from configured P7D trial)
  - "Restore Purchases" button — tap it, verify it triggers restore flow
  - "Privacy Policy" link — tap it, verify it opens `https://getneurostack.app`
  - "Terms of Use" link — tap it, verify it opens `https://getneurostack.app`
  - Auto-renewal disclosure text visible
  - "Continue with Free" dismiss button — no delay, immediately visible
  - Paywall name is "Neurostack Pro" (not "Untitled Paywall")

### 4.2 Settings verification

- Open Settings screen:
  - "Restore Purchases" tile is visible (even as free user)
  - Tap "Restore Purchases" → shows toast ("No previous purchases found" for new user)
  - "Manage Subscription" tile visible when premium/trial (not "Cancel Subscription")
  - Tap "Manage Subscription" → opens App Store subscription management page

### 4.3 Edge case verification

- Double-tap Restore in Settings — second tap ignored (no double toast)
- Paywall Restore → dismiss paywall → entitlement refresh reflected in Settings
- Web (if applicable): Restore Purchases tile is NOT shown

### 4.4 API verification

```bash
# Verify paywall components include Restore, Privacy, Terms buttons
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/paywalls/pw3847f37f3e364dad?expand=components"

# Verify products have trial_duration
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=app37554ace9b&limit=20"
```

---

## Phase 5 — Create App Store Connect Subscription Products [PORTAL, can defer]

> Manual task — beginner step-by-step guide for App Store Connect.
> **Flow task:** `fn-81-paywall-apple-compliance.5`
> **Independent of Phases 1-4** — can start anytime.

### 5.1 Open App Store Connect

- Go to https://appstoreconnect.apple.com → sign in → **My Apps** → **Neurostack**

### 5.2 Create Subscription Group

- Left sidebar → **Subscriptions** (under "In-App Purchases")
- Click **+** next to "Subscription Groups"
- Group name: **Neurostack Pro**
- Cite: spec §G; one subscription group ties monthly/yearly together

### 5.3 Create Monthly Product

- Inside "Neurostack Pro" group → click **Create**
- Reference Name: `Neurostack Monthly`
- Product ID: `neurostack_monthly` (must match RevenueCat exactly — cite: spec §G)
- Subscription Duration: **1 Month**
- Add Subscription Price → set base price → confirm
- Add Localization: Display Name "Neurostack Pro Monthly", Description "Full access to all protocols, updated monthly"

### 5.4 Configure Monthly Introductory Offer (7-day trial)

- Scroll to **Introductory Offers** → click **+**
- Type: **Free Trial**
- Duration: **1 Week** (7 days)
- Cite: spec §G; user decision #2 (7-day trial on all plans)

### 5.5 Create Yearly Product

- Same group → **Create** again
- Reference Name: `Neurostack Yearly`
- Product ID: `neurostack_yearly` (must match RevenueCat — cite: spec §G)
- Subscription Duration: **1 Year**
- Add Subscription Price → set base price → confirm
- Add Localization: Display Name "Neurostack Pro Yearly", Description "Full access to all protocols, billed annually"

### 5.6 Configure Yearly Introductory Offer

- Same as §5.4: Free Trial, 1 Week duration
- Note: one trial per subscription group — user who trialed monthly cannot re-trial on yearly
  - Cite: practice-scout finding; Apple Introductory Offer rules

### 5.7 Set Subscription Group Ranking

- Drag to order: Yearly first (higher rank), Monthly second
- Apple may suggest upgrades to higher-ranked products

### 5.8 Submit Products for Review

- Verify both products show "Ready to Submit" or fill any missing fields
- Products are reviewed alongside app binary or independently
- Allow 24 hours for propagation after approval
  - Cite: docs-scout finding (RevenueCat launch checklist)

---

## Phase 6 — Configure ASC API Key + Wire App Store Products in RevenueCat [PORTAL, can defer]

> **Flow task:** `fn-81-paywall-apple-compliance.6`
> **Depends on:** Phase 5 (products must exist first)

### 6.1 Generate API key in App Store Connect

- App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
- Click **Generate API Key** → Name: `RevenueCat` → Access: **App Manager**
- Cite: spec §H; docs-scout finding (ASC API key configuration docs)

### 6.2 Download the .p8 key file

- Click **Download** next to the new key
- Save securely (1Password, etc.) — **one-time download only**
- Cite: spec §H; RevenueCat ASC API key docs

### 6.3 Note Issuer ID and Key ID

- **Issuer ID**: UUID at the top of the API Keys page
- **Key ID**: shown next to your key in the table
- Copy both

### 6.4 Find Vendor Number

- App Store Connect → **Payments and Financial Reports** (bottom left sidebar)
- **Vendor Number** displayed at top (numeric ID)

### 6.5 Upload to RevenueCat

- RevenueCat dashboard → Project "Neurostack" → click **Neurostack** (App Store app, not Test Store)
- Go to **App Store Connect API** tab
- Upload `.p8` file, enter Issuer ID, Key ID, Vendor Number → **Save**
- Verify via API:
  ```bash
  .claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/apps" | jq '.items[] | select(.type == "app_store") | .app_store.app_store_connect_api_key_configured'
  # Should return: true
  ```
- Cite: spec §H; investigation root cause #1 (`api_key_configured: false`)

### 6.6 Import products from App Store Connect

- RevenueCat → **Products** → **+ New** → **Import Products**
- Select the Neurostack App Store app
- Import `neurostack_monthly` and `neurostack_yearly`
- Cite: spec §H

### 6.7 Attach products to packages

- **Offerings** → "default" → **Packages**
- `$rc_monthly` (`pkge9556a58aac`) → **Attach Product** → select App Store `neurostack_monthly`
- `$rc_annual` (`pkge6aeaf41ae6`) → **Attach Product** → select App Store `neurostack_yearly`
- Keep Test Store products also attached (for development)
- Cite: spec §H; investigation Phase 3 (packages wired only to Test Store)

### 6.8 Attach products to entitlement

- **Entitlements** → "Neurostack Pro" (`entl21aba2a7b0`) → **Attach** → select both App Store products
- Keep Test Store products also attached
- Cite: spec §H; investigation Phase 3 (entitlement wired only to Test Store)

### 6.9 Republish paywall

- Paywalls → "Neurostack Pro" → Publish
- Ensures paywall picks up new product associations

### 6.10 Verify via API

```bash
# App Store products exist
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=appaea2f089fd&limit=20"

# Packages have both Test Store and App Store products
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/packages/pkge9556a58aac/products?limit=20"
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/packages/pkge6aeaf41ae6/products?limit=20"

# Entitlement has both
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/entitlements/entl21aba2a7b0/products?limit=20"
```

---

## Files Changed (Summary)

| File | Action | Phase |
|------|--------|-------|
| `lib/settings/settings_view_model.dart` | Edit — inject NotifyService, add restorePurchases(), expose canAccessPremium | 2 |
| `lib/settings/widgets/settings_support_section.dart` | Edit — add Restore tile, rename Cancel→Manage, update callback, change visibility | 2 |
| `lib/settings/settings_view.dart` | Edit — wire new callback, pass NotifyService | 2 |
| `test/settings/settings_view_model_test.dart` | Edit — add restore tests, update cancel→manage assertions | 2 |
| `test/settings/widgets/settings_brightness_test.dart` | Edit — update "Cancel Subscription" text assertions | 2 |
| `docs/specs/20260227120000_spec_settings_screen.md` | Edit — reverse Restore out-of-scope, rename Cancel→Manage throughout | 3 |
| `docs/specs/20260324200000_spec_paywall_apple_compliance.md` | New — this spec | — |
| `docs/best_practices/design/screen-prompts/11-settings-screen.md` | Edit — add Restore row, rename Cancel→Manage | 3 |
| `docs/best_practices/design/screen-prompts/06-paywall-modal.md` | Edit — note compliance elements | 3 |
| `docs/best_practices/design/screen-prompts/01-on-boarding-3.md` | Edit — flag "No credit card required" | 3 |
| `docs/ubiquitous-language.md` | Edit — update Settings examples, annotate INV-M2 | 3 |
| `plan_settings_screen.md` | Edit — annotate Restore reversal, rename Cancel→Manage | 3 |
| `plan_paywall_modal.md` | Edit — correct Section 5.3 false [DONE] | 3 |
| `lib/paywall/paywall_constants.dart` | Edit — update trial duration comments | 3 |
| `docs/README.md` | Edit — add spec + plan links | 3 |

---

## Dependency Graph

```
Phase 1 (portal)  ──────────────────────────┐
                                             │
Phase 2 (code) ──→ Phase 3 (docs) ──────────┼──→ Phase 4 (verify)
                                             │
Phase 5 (ASC products) ──→ Phase 6 (wire RC) ┘ (Phase 5-6 can defer)
```

- Phases 1 and 2 can run **in parallel** (portal vs code, no overlap)
- Phase 3 depends on Phase 2 (needs final naming/code decisions)
- Phase 4 depends on Phases 1, 2, 3 (verifies everything)
- Phases 5 and 6 are independent of 1-4 (can start anytime, can defer)
