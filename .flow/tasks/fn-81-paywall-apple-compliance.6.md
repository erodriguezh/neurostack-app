# fn-81-paywall-apple-compliance.6 Configure ASC API key + wire App Store products in RevenueCat

## Description
**Type:** PORTAL (manual — beginner step-by-step guide)
**Size:** M
**Phase:** 2 (can defer)
**Files:** None (portal-only)
**Depends on:** Task .5 (App Store Connect products must exist first)

This task walks you through: (A) generating an App Store Connect API key for RevenueCat, and (B) importing and wiring the real App Store products in RevenueCat.

### Part A — Configure App Store Connect API Key

**Step 1: Generate API key in App Store Connect**
- Go to https://appstoreconnect.apple.com
- Click **Users and Access** (top nav)
- Click **Integrations** tab → **App Store Connect API**
- Click **Generate API Key** (or **+** if keys exist)
  - Name: `RevenueCat`
  - Access: **App Manager** (minimum role required)
- Click **Generate**

**Step 2: Download the .p8 key file**
- Click **Download** next to the new key
- **IMPORTANT:** You can only download this file ONCE. Save it securely (e.g., 1Password)
- The file is named `AuthKey_XXXXXXXXXX.p8`

**Step 3: Note the Issuer ID**
- At the top of the API Keys page, you'll see **Issuer ID** (a UUID like `a1b2c3d4-...`)
- Copy this — you'll need it for RevenueCat

**Step 4: Find your Vendor Number**
- In App Store Connect, go to **Payments and Financial Reports** (bottom of left sidebar)
- Your **Vendor Number** is displayed at the top (a numeric ID)
- Copy this — RevenueCat needs it for price importing

**Step 5: Upload to RevenueCat**
- Go to RevenueCat dashboard → Project "Neurostack"
- Click on the **Neurostack** app (the App Store one, not Test Store)
- Go to **App Store Connect API** tab (or App Settings)
- Upload the `.p8` file
- Enter the **Issuer ID**
- Enter the **Key ID** (shown in App Store Connect next to your key)
- Enter the **Vendor Number**
- Click **Save**

**Step 6: Verify**
- After saving, RevenueCat should show `app_store_connect_api_key_configured: true`
- Verify via API:
```bash
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/apps" | jq '.items[] | select(.type == "app_store") | .app_store.app_store_connect_api_key_configured'
```

### Part B — Import and Wire Products

**Step 7: Import products from App Store Connect**
- In RevenueCat → Project "Neurostack" → **Products**
- Click **+ New** → **Import Products**
- Select the **Neurostack** App Store app
- RevenueCat should find `neurostack_monthly` and `neurostack_yearly`
- Import both

**Step 8: Attach products to packages**
- Go to **Offerings** → "default" offering → **Packages**
- Click on `$rc_monthly` package → **Attach Product**
  - Select the App Store `neurostack_monthly` product
  - (Keep the Test Store product also attached for development)
- Click on `$rc_annual` package → **Attach Product**
  - Select the App Store `neurostack_yearly` product

**Step 9: Attach products to entitlement**
- Go to **Entitlements** → "Neurostack Pro"
- Click **Attach** → select both App Store products
- (Keep Test Store products also attached)

**Step 10: Verify via API**
```bash
# Should show App Store products in addition to Test Store
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/products?app_id=appaea2f089fd&limit=20"

# Packages should have both Test Store and App Store products
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/packages/pkge9556a58aac/products?limit=20"
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/packages/pkge6aeaf41ae6/products?limit=20"

# Entitlement should have both
.claude/skills/revenuecat/scripts/rc-api.sh "/projects/proj2eeae544/entitlements/entl21aba2a7b0/products?limit=20"
```

**Step 11: Republish paywall**
- Go to Paywalls → "Neurostack Pro" → Publish
- This ensures the paywall picks up the new product associations

## Key context
- The .p8 file can only be downloaded once from Apple — save it securely
- App Manager is the minimum role; Admin also works
- Products must be in "Ready to Submit" or "Approved" status in App Store Connect before they appear in RevenueCat's import
- Allow up to 24 hours for propagation after approval
- Keep Test Store products attached alongside App Store products for development/testing
- The RevenueCat launch checklist warns: "You MUST replace your Test Store API key with the correct platform-specific API key before submitting your app for review"
## Acceptance
- [ ] App Store Connect API key generated with App Manager role
- [ ] .p8 file downloaded and stored securely
- [ ] Issuer ID, Key ID, and Vendor Number collected
- [ ] API key uploaded to RevenueCat App Store app
- [ ] `app_store_connect_api_key_configured: true` verified via API
- [ ] `neurostack_monthly` App Store product imported to RevenueCat
- [ ] `neurostack_yearly` App Store product imported to RevenueCat
- [ ] App Store products attached to `$rc_monthly` and `$rc_annual` packages
- [ ] App Store products attached to "Neurostack Pro" entitlement
- [ ] API verification confirms App Store products in packages and entitlement
- [ ] Paywall republished
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
