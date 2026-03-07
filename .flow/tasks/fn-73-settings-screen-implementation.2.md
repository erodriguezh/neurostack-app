# fn-73-settings-screen-implementation.2 Phase 1.2: Fix enum exhaustiveness across codebase

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Added HomeBottomTab.settings case to the HomeBottomTabCoordinator switch statement, fixing the only enum exhaustiveness error introduced by Phase 1.1. Verified home_state.dart and library_state.dart defaults need no changes. flutter analyze passes with 0 issues, all 571 tests pass.
## Evidence
- Commits: 2ec4fb7713654972482006b7233f0a383a4fa147
- Tests: flutter analyze, flutter test (571 passed)
- PRs: