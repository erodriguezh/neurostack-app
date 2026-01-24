# fn-24-vwc.1 Update TrialPeriodDto: add endDate field and update toDomain/fromDomain methods

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Added endDate field to TrialPeriodDto with nullable support. Updated toDomain() to use DB endDate when present or fall back to computed value (start + 7 days), handling null/empty/whitespace edge cases. Updated fromDomain() to serialize both dates.
## Evidence
- Commits: 4f078ac, d948f71
- Tests: flutter test
- PRs: