# fn-54-phase-102-update-user-entity.1 Update User Entity: rename createWithTrial→create, remove currentTime param, cascade to callers

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Renamed User.createWithTrial() to User.create() with subscriptionStatus: free (INV-P6), removed unused currentTime parameter from getEffectiveStatus(), activateProtocol(), and canLogSession(), and cascaded the changes to all callers (HomeViewModel, LibraryViewModel, CheckEligibilityUseCase, LogSessionUseCase, LogSessionViewModel, UserBootstrapService) and their tests.
## Evidence
- Commits: 7928bf25, 0d516e4, f32fca5
- Tests: flutter analyze, flutter test
- PRs: