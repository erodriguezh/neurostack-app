# Paywall Apple Compliance

## Overview

The RevenueCat hosted paywall and app Settings screen are not Apple App Store-ready. The compliance audit (2026-03-24) found 3 critical blockers, 1 warning, and several polish items. This epic resolves all issues in two phases: first polish everything against the Test Store, then wire real App Store products.

### Current state
- Published paywall (`pw3847f37f3e364dad`) has only 2 buttons: "Subscribe" and "Continue with Free"
- No Restore Purchases, Privacy Policy, Terms of Use, or auto-renewal disclosure on paywall
- No Restore Purchases tile in Settings
- "Cancel Subscription" label is misleading (action opens subscription management)
- Both products show `trial_duration: null` despite specs promising 7-day trial
- All products wired to Test Store only; App Store app has zero products attached
- `app_store_connect_api_key_configured: false`
- fn-46-1b8 ("Add Restore Purchases") was marked done but never implemented

### Decisions made
- Restore Purchases tile: always visible to ALL users (Apple requirement)
- "Manage Subscription" tile: visible when `canAccessPremium` (includes trial users)
- 7-day free trial on both monthly and yearly plans
- Privacy Policy + Terms of Use URL (temporary): `https://getneurostack.app`
- Rename `onCancelSubscriptionTap` → `onManageSubscriptionTap` throughout
- Auto-renewal disclosure + cancellation guide text added to paywall
- Restore toast messages: success ("Purchases restored successfully"), no purchases ("No previous purchases found"), failure ("Unable to restore purchases. Please try again.")

## Scope

### Phase 1 — Test Store polish (tasks .1–.4)
- Fix hosted paywall content in RevenueCat dashboard
- Configure 7-day trial on Test Store products
- Add Restore Purchases to Settings + rename Cancel → Manage Subscription (code)
- Update specs and docs to match new reality
- End-to-end verification with Test Store

### Phase 2 — App Store wiring (tasks .5–.6, can defer)
- Create subscription products in App Store Connect
- Configure ASC API key + wire products in RevenueCat

## Risks
- Portal tasks (1, 2, 5, 6) are manual — no automated tests, verified only by Task 4 (E2E)
- Privacy/Terms URL (`https://getneurostack.app`) must contain actual legal text before Apple review
- App Store products take up to 24h to propagate after creation
- fn-46-1b8 is a zombie epic — must be closed to avoid duplicate tracking

## Quick commands
```bash
# Run settings tests after code changes
flutter test test/settings/

# Verify paywall config via API
RC_API_KEY=sk_... .claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/paywalls/pw3847f37f3e364dad?expand=components"

# Check products have trial_duration set
RC_API_KEY=sk_... .claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=app37554ace9b&limit=20"
```

## Acceptance
- [ ] Hosted paywall includes: Restore Purchases button, Privacy Policy link, Terms of Use link, auto-renewal disclosure, accurate trial terms
- [ ] Paywall renamed from "Untitled Paywall"
- [ ] Both Test Store products have `trial_duration: P7D`
- [ ] Settings shows "Restore Purchases" tile (always visible)
- [ ] Settings shows "Manage Subscription" tile (visible when `canAccessPremium`)
- [ ] `onCancelSubscriptionTap` renamed to `onManageSubscriptionTap` throughout
- [ ] Restore shows appropriate toast for success/no-purchases/failure
- [ ] All 8 flagged docs updated (specs, screen prompts, ubiquitous language, plans)
- [ ] fn-46-1b8 zombie epic closed
- [ ] E2E verification passes with Test Store
- [ ] (Phase 2) App Store products created and wired in RevenueCat

## References
- Investigation: `docs/investigations/20260324_revenuecat_paywall_apple_compliance.md`
- Apple Guidelines: 3.1.1 (Restore), 3.1.2 (Subscriptions), 5.1.1 (Privacy)
- RevenueCat paywall components: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/components
- RevenueCat app review guide: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/app-review
- RevenueCat launch checklist: https://www.revenuecat.com/docs/test-and-launch/launch-checklist
