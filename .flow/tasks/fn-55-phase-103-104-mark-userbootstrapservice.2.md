# fn-55-phase-103-104-mark-userbootstrapservice.2 Update UserDto to stop serializing trial columns (Phase 10.4)

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Removed the trialEndsAt field entirely from UserDto, stopping serialization of trial_ends_at before the DB column is dropped. Updated tests to verify toJson omits the field and fromJson tolerates the legacy column.
## Evidence
- Commits: 5644a22, a1ea30d
- Tests: flutter test, flutter analyze
- PRs: