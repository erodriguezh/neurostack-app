# fn-81-paywall-apple-compliance.1 Fix hosted paywall + configure trials in RevenueCat dashboard

## Description
**Type:** PORTAL (manual — step-by-step guide for RevenueCat dashboard)
**Size:** M
**Files:** None (portal-only)

This task walks you through fixing the hosted paywall in the RevenueCat dashboard and configuring 7-day free trials on both Test Store products.

### Part A — Fix paywall content

Open the RevenueCat dashboard → Project "Neurostack" → Paywalls → "Untitled Paywall" → Edit.

**Step 1: Rename the paywall**
- Click the paywall name ("Untitled Paywall") at the top
- Rename to "Neurostack Pro" or similar

**Step 2: Add a Restore Purchases button**
- In the component tree, add a new **Button** component in the footer area (below the Subscribe button)
- Set the button text to "Restore Purchases"
- In the button properties panel (top-right), set **Action** to **"Restore Purchases"**
- Style: small/subtle text, not a primary button

**Step 3: Add Privacy Policy link**
- Add another **Button** component near the footer
- Set text to "Privacy Policy"
- Set **Action** to **"Navigate to"** → enter URL: `https://getneurostack.app`
- Set open mode to "In-App Browser" or "External Browser"

**Step 4: Add Terms of Use link**
- Add another **Button** component next to Privacy Policy
- Set text to "Terms of Use"
- Set **Action** to **"Navigate to"** → enter URL: `https://getneurostack.app`

**Step 5: Add auto-renewal disclosure text**
- Add a **Text** component below the legal links, small font (~10-11pt), muted color
- Text content:

> Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage in app Settings → Manage Subscription.

**Step 6: Add cancellation guide text** (optional, can be in same text block)

> To cancel: Open the app → Settings → Manage Subscription → Select Neurostack → Cancel Subscription and confirm.

**Step 7: Verify no delayed close button**
- Check that the "Continue with Free" (back/dismiss) button has NO delay configured
- If there's a delay, remove it — Apple rejects delayed close buttons

**Step 8: Verify pricing variables**
- Confirm price displays use `{{ product.price_per_period_abbreviated }}` or similar dynamic variables (not hardcoded prices)
- If trials are configured (Part B), add trial text using variables: `{{ product.offer_period_with_unit }}` free, then `{{ product.price_per_period }}`

**Step 9: Publish**
- Click **Publish** to make changes live
- The SDK will pick up the new paywall immediately

### Part B — Configure 7-day trial on Test Store products

**Step 10: Navigate to Products**
- In RevenueCat dashboard → Project "Neurostack" → Products
- Find `neurostack_monthly` (Test Store) → Edit
- Set **Trial Duration** to **7 days** (P7D)
- Save

**Step 11: Repeat for yearly**
- Find `neurostack_yearly` (Test Store) → Edit
- Set **Trial Duration** to **7 days** (P7D)
- Save

**Step 12: Verify via API**
```bash
# Both products should now show trial_duration: "P7D"
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=app37554ace9b&limit=20"
```

## Key context
- Current paywall has only 2 buttons: "Subscribe" and "Continue with Free" — confirmed by API expand on 2026-03-24
- RevenueCat Button component supports actions: "Restore Purchases", "Navigate to" (with URL), "Navigate back"
- "Navigate to" supports Privacy Policy and Terms of Service as destinations
- RevenueCat warns: delayed close buttons may cause Apple rejection
- Use RevenueCat template variables for pricing — never hardcode
- Test Store trial duration is set directly in RevenueCat (unlike App Store which requires App Store Connect)
## Acceptance
- [ ] Paywall renamed from "Untitled Paywall" to a proper name
- [ ] Restore Purchases button added with "Restore Purchases" action
- [ ] Privacy Policy button added linking to https://getneurostack.app
- [ ] Terms of Use button added linking to https://getneurostack.app
- [ ] Auto-renewal disclosure text added (payment charge, auto-renewal, cancellation)
- [ ] No delayed close button configured
- [ ] Pricing uses dynamic RevenueCat variables (not hardcoded)
- [ ] Paywall published (live to SDK)
- [ ] `neurostack_monthly` has `trial_duration: P7D`
- [ ] `neurostack_yearly` has `trial_duration: P7D`
- [ ] API verification confirms trial_duration on both products
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
