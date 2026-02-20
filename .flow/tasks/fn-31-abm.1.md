# fn-31-abm.1 Update docs/ubiquitous-language.md with RevenueCat paywall invariants

## Description
From `plan_paywall_modal.md` Phase 0.4: The app is transitioning from Supabase-managed trials to RevenueCat-managed subscriptions. The ubiquitous language document needs to be updated to reflect the new payment model.

## File to Modify
`docs/ubiquitous-language.md`

## Changes Required

### Deprecate old invariants:
- Mark **INV-U3** as DEPRECATED: "Trial MUST auto-activate on first app launch"
- Mark **INV-M3** as DEPRECATED: "Premium Trial MUST NOT require credit card"

### Update existing invariant:
- Update **INV-M2**: "Premium Trial MUST last exactly 7 days **from subscription start**" (not from first app launch)

### Add new paywall invariants (INV-P series):
- **INV-P1**: "Paywall dismissal without purchase returns to previous screen"
- **INV-P2**: "Successful purchase updates UI immediately via RevenueCat (optimistic)"
- **INV-P3**: "Webhook is source of truth for DB; client uses RevenueCat for UI gating"
- **INV-P4**: "Trial reminder shown max once per 24h period"
- **INV-P5**: "`app_user_id` must match Supabase `auth.uid`"
- **INV-P6**: "New users MUST start with `free` status (not `trial`)"

## Rationale
- RevenueCat manages trial periods, not Supabase
- Trials require a payment method (App Store/Play Store handles this)
- New users start as `free` and only become `trial` when they start a subscription with trial period
- The webhook is the single source of truth for DB subscription state
- Client uses RevenueCat SDK for real-time UI gating (faster, works offline with cache)

## Acceptance
- [ ] INV-U3 and INV-M3 marked as DEPRECATED with explanation
- [ ] INV-M2 updated to clarify "from subscription start"
- [ ] All 6 new INV-P invariants added
- [ ] Document maintains consistent formatting

## Done summary
Updated docs/ubiquitous-language.md with RevenueCat paywall invariants: deprecated INV-U3 and INV-M3, updated INV-M2 for subscription start, renamed Protocol Invariants to INV-PR*, added new Paywall Invariants (INV-P1 through INV-P6), and updated related terms to reflect the new payment model.
## Evidence
- Commits: 934ea05c10b9c6d6a2ee1cd6ad66e2e2eb9e19ae, c14dbd888da2b23236d8d40c7bf9ce957b46178e
- Tests:
- PRs: