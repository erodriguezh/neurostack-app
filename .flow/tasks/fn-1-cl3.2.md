# fn-1-cl3.2 Create CheckEligibilityUseCase (Phase 1.2)

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
- Added `CheckEligibilityUseCase` to gate Log Session modal opening
- Use case loads user via `UserRepository` and delegates to `User.canLogSession()`
- Verifies: onboarding completed (INV-U4), protocol in stack, trial limits (INV-U5)

- Why: Pre-validates eligibility before user fills out form, avoiding poor UX
- Follows same pattern as `LogSessionUseCase` but without persistence

- Verification: 5 unit tests pass covering all failure cases + success
- `flutter analyze` passes with no issues
## Evidence
- Commits: cd2b0bf3a254d0bf272f8347fe0b72049fbe4a61
- Tests: flutter test test/domain/session/use_cases/check_eligibility_use_case_test.dart
- PRs: