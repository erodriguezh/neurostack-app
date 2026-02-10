# fn-50-phase-71-update.1 Re-key TrialExpirationDecisionStore from trialStartDate to RevenueCat-stable identifiers

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Re-keyed TrialExpirationDecisionStore from trialStartDate to RevenueCat-stable identifiers with fallback hierarchy (originalTransactionId > latestPurchaseDate > expirationDate > null). Added isSubscriptionExpirationResolved/markSubscriptionExpirationResolved methods, ExpirationDecision enum, and 26 unit tests. Legacy methods preserved for backward compatibility.
## Evidence
- Commits: b67fad7, 19e22e2
- Tests: flutter test test/paywall/data/trial_expiration_decision_store_test.dart, flutter analyze
- PRs: