# fn-37-tmv.1 Create RevenueCatClient abstract interface

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created RevenueCatClient abstract interface with all required methods (configure, logIn, logOut, getEntitlementSnapshot, presentPaywall, restorePurchases) and entitlementChanges stream. Documented nullable return type contract to distinguish "RC unavailable" from "no entitlement".
## Evidence
- Commits: cfa24021720144082f5cb475f85998f0af3050e6
- Tests: flutter analyze, flutter test
- PRs: