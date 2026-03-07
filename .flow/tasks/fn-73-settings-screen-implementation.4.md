# fn-73-settings-screen-implementation.4 Phase 1.4: Add routing case to HomeBottomTabCoordinator

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Verified that the settings routing case in HomeBottomTabCoordinator (added in Phase 1.2 commit 2ec4fb7) correctly matches the Phase 1.4 plan specification. The case routes HomeBottomTab.settings to /settings via replaceAll, consistent with the other three tab cases. flutter analyze passed with no issues, all 571 tests passed, and RP review returned SHIP.
## Evidence
- Commits: 2ec4fb7, bee62ab
- Tests: flutter analyze, flutter test
- PRs: