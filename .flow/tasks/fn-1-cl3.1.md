# fn-1-cl3.1 Add Session.DateTooOld failure

## Description
TBD

## Acceptance
## Acceptance Criteria
- [ ] Add `dateTooOld` failure constant to `session_failures.dart`
- [ ] Code: `Session.DateTooOld`
- [ ] Message: `Cannot log sessions more than 7 days in the past`
- [ ] Follow existing pattern in the failures file
- [ ] `flutter analyze` passes


## Done summary
- Added `dateTooOld` failure constant to SessionFailures
- Code: `Session.DateTooOld`, Message: `Cannot log sessions more than 7 days in the past`
- Follows existing pattern with INV-LSM2 reference comment
- Verification: `flutter analyze` passes, all 27 session domain tests pass
## Evidence
- Commits: 531da56
- Tests: flutter test test/domain/session/
- PRs: