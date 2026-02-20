# fn-59-phase-114-delete-trialperiod-value.1 Delete TrialPeriod value object file and all related tests

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Deleted the TrialPeriod value object, TrialPeriodDto, and all related tests/factories. Removed the trialPeriod field from User entity and UserDto, updated all test files that referenced it, and regenerated freezed/json_serializable code.
## Evidence
- Commits: 68d425f403e754afa153989454b7d22bfc46b698
- Tests: flutter analyze, flutter test
- PRs: