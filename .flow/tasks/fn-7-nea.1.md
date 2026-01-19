# fn-7-nea.1 Phase 8.1: Domain tests - CheckEligibilityUseCase

## Description
Verify domain tests for `CheckEligibilityUseCase` are complete and passing.
Tests were created during Phase 1.2 implementation.

## Acceptance
- [x] User not found → failure test exists
- [x] Onboarding not completed → failure test exists
- [x] Protocol not in stack → failure test exists
- [x] Too many active protocols → `User.TooManyActiveProtocols` test exists
- [x] Eligible → `Right(unit)` test exists
- [x] All tests pass

## Done summary
- Task completed
## Evidence
- Commits:
- Tests:
- PRs: