# fn-28-rwa.1 Implement TrialExpirationDecisionStore and integrate into HomeViewModel/HomeView

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Implemented TrialExpirationDecisionStore to persist trial expiration decision state across app restarts, preventing repeated modal display for users whose trial expires between cron runs. Also fixed goToPaywall() async race condition and added tappable banner recovery path for trial-expired users.
## Evidence
- Commits: cc91dbf, 342c5f1, d016d9a
- Tests: flutter test test/paywall/data/trial_expiration_decision_store_test.dart, flutter test test/home/
- PRs: