# fn-81-paywall-apple-compliance.4 End-to-end verification with Test Store

## Description
**Type:** VERIFY (manual testing)
**Size:** S
**Files:** None (manual verification)

Run the app against the Test Store and verify all compliance elements work end-to-end. This task depends on tasks .1 (portal), .2 (code), and .3 (docs) being complete.

## Verification checklist

### Paywall verification
1. Open the app → trigger the paywall (tap Upgrade or hit the paywall gate)
2. Verify the paywall shows:
   - [ ] Subscription prices (dynamic, not hardcoded)
   - [ ] Billing periods ("Monthly", "Yearly")
   - [ ] 7-day free trial terms (if configured in Part B of task .1)
   - [ ] "Restore Purchases" button — tap it, verify it triggers restore flow
   - [ ] "Privacy Policy" link — tap it, verify it opens https://getneurostack.app
   - [ ] "Terms of Use" link — tap it, verify it opens https://getneurostack.app
   - [ ] Auto-renewal disclosure text visible
   - [ ] "Continue with Free" dismiss button — no delay, immediately visible
   - [ ] Paywall name is no longer "Untitled Paywall"

### Settings verification
3. Open Settings screen:
   - [ ] "Restore Purchases" tile is visible (even as free user)
   - [ ] Tap "Restore Purchases" → shows toast ("No previous purchases found" for new user)
   - [ ] "Manage Subscription" tile visible when premium/trial (not "Cancel Subscription")
   - [ ] "Manage Subscription" opens App Store subscription management

### API verification
4. Run API checks:
```bash
# Verify paywall components include Restore, Privacy, Terms buttons
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/paywalls/pw3847f37f3e364dad?expand=components" | jq '.components.published'

# Verify products have trial_duration
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=app37554ace9b&limit=20" | jq '.items[].subscription.trial_duration'
```

### Edge case verification
5. Test edge cases:
   - [ ] Double-tap Restore in Settings — second tap ignored (no double toast)
   - [ ] Paywall Restore → dismiss paywall → entitlement refresh reflected in Settings
   - [ ] Web: Restore Purchases tile is NOT shown (if web is supported)
## Acceptance
- [ ] Paywall shows: prices, periods, trial terms, Restore, Privacy, Terms, disclosure
- [ ] Paywall dismiss button has no delay
- [ ] Settings "Restore Purchases" visible to all users, shows correct toast
- [ ] Settings "Manage Subscription" visible for premium+trial, opens subscription management
- [ ] API confirms paywall components include compliance elements
- [ ] API confirms both products have trial_duration: P7D
- [ ] Edge cases verified (double-tap guard, web hide)
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
