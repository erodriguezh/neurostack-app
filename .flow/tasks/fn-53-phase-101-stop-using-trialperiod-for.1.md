# fn-53-phase-101-stop-using-trialperiod-for.1 Remove trialPeriod gating usage from User entity and all callers

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Simplified User.getEffectiveStatus() to return subscriptionStatus directly, removing trialPeriod.isExpired() gating. Updated tests across user_test, check_eligibility_use_case_test, and log_session_use_case_test to reflect the entity no longer gates on trial expiry. Updated class and method docstrings to accurately describe the new responsibility split with SubscriptionStatusResolver.
## Evidence
- Commits: c943d13, 83fb65a
- Tests: flutter analyze, flutter test
- PRs: