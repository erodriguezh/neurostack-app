# fn-81-paywall-apple-compliance.5 Create subscription products in App Store Connect

## Description
**Type:** PORTAL (manual — beginner step-by-step guide for App Store Connect)
**Size:** M
**Phase:** 2 (can defer — not needed for Test Store testing)
**Files:** None (portal-only)

This task walks you through creating real subscription products in App Store Connect. These products must exist before the app can be submitted to the App Store.

**Prerequisites:** You need an Apple Developer account with Admin or App Manager role.

### Step 1: Open App Store Connect
- Go to https://appstoreconnect.apple.com
- Sign in with your Apple Developer account
- Click **My Apps** → Select **Neurostack**

### Step 2: Navigate to Subscriptions
- In the left sidebar, click **Subscriptions** (under "In-App Purchases")
- If you don't see it, click **Features** first, then **Subscriptions**

### Step 3: Create a Subscription Group
- Click the **+** button next to "Subscription Groups"
- Enter group name: **Neurostack Pro**
- This group ties monthly and yearly plans together (a user can only have one active subscription per group)

### Step 4: Create Monthly Product
- Inside the "Neurostack Pro" group, click **Create** (or **+**)
- **Reference Name:** Neurostack Monthly
- **Product ID:** `neurostack_monthly` (must match RevenueCat exactly)
- Click **Create**

### Step 5: Configure Monthly Product
- **Subscription Duration:** 1 Month
- **Subscription Prices:** Click **Add Subscription Price**
  - Select your base country/region
  - Set your monthly price (e.g., $9.99)
  - Apple will auto-calculate prices for other regions
  - Click **Next** → **Confirm**
- **App Store Localization:** Click **+** next to Localizations
  - Display Name: "Neurostack Pro Monthly"
  - Description: "Full access to all protocols, updated monthly"

### Step 6: Configure Monthly Introductory Offer (7-day free trial)
- Scroll down to **Introductory Offers** (or **Subscription Prices** section)
- Click **+** (Create Introductory Offer)
  - **Type:** Free Trial
  - **Duration:** 1 Week (7 days)
- Each user gets this trial once per subscription group

### Step 7: Create Yearly Product
- Go back to "Neurostack Pro" subscription group
- Click **Create** again
- **Reference Name:** Neurostack Yearly
- **Product ID:** `neurostack_yearly` (must match RevenueCat exactly)
- Click **Create**

### Step 8: Configure Yearly Product
- **Subscription Duration:** 1 Year
- **Subscription Prices:** Set your yearly price (e.g., $49.99)
- **App Store Localization:**
  - Display Name: "Neurostack Pro Yearly"
  - Description: "Full access to all protocols, billed annually"

### Step 9: Configure Yearly Introductory Offer
- Same as Step 6: Free Trial, 1 Week duration

### Step 10: Set Subscription Group Ranking
- In the subscription group, drag to order: Yearly first, Monthly second
- Higher rank = Apple may suggest the upgrade to users

### Step 11: Submit Products for Review
- Products start in "Missing Metadata" or "Ready to Submit" status
- Fill in all required fields (localization, pricing, screenshot if needed)
- Products are reviewed alongside your app binary, or can be submitted independently
- **Note:** Products take up to 24 hours to propagate after approval

### Step 12: Verify in App Store Connect
- Both products should show status "Ready to Submit" or "Waiting for Review"
- Verify Product IDs match exactly: `neurostack_monthly`, `neurostack_yearly`

## Key context
- Product IDs must match RevenueCat identifiers exactly (case-sensitive)
- Introductory Offers are per subscription group — a user who used a trial on monthly cannot get another on yearly
- Products need "Approved" status before they work in production (sandbox works earlier)
- Allow 24 hours for propagation after products are approved
## Acceptance
- [ ] Subscription group "Neurostack Pro" created in App Store Connect
- [ ] `neurostack_monthly` product created with correct duration and pricing
- [ ] `neurostack_yearly` product created with correct duration and pricing
- [ ] 7-day free trial (Introductory Offer) configured on monthly product
- [ ] 7-day free trial (Introductory Offer) configured on yearly product
- [ ] Localizations filled in for both products
- [ ] Products submitted for review (or ready to submit)
- [ ] Product IDs verified to match RevenueCat identifiers exactly
## Done summary
Portal-only task completed. In App Store Connect:
- Created subscription group "Neurostack Pro"
- Created neurostack_monthly (1 Month, 7-day free trial, localized)
- Created neurostack_yearly (1 Year, 7-day free trial, localized)
- Group ranking set (Yearly first)
- Review screenshots uploaded
- Products in "Missing Metadata" status — will resolve at release time
## Evidence
- Commits:
- Tests:
- PRs: