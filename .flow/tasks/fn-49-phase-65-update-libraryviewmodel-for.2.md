# fn-49-phase-65-update-libraryviewmodel-for.2 Refactor: Extract shared patterns, purify _buildCards, add LibraryViewModel tests

## Description
Four refactoring items approved by user after Phase 6.5 implementation:

1. **Extract entitlement listener mixin** — Both HomeViewModel and LibraryViewModel have identical entitlement listener setup/teardown. Extract into a shared mixin.
2. **Extract connectivity listener mixin** — Same duplication for connectivity listener pattern. Extract into a shared mixin.
3. **Purify _buildCards** — Pass entitlement snapshot as parameter instead of reading service state directly, making the method pure and testable.
4. **Add LibraryViewModel unit tests** — Test that locked/unlocked card status respects resolver output and that entitlement changes trigger refresh.

## Acceptance
- [ ] Entitlement listener pattern extracted into shared mixin used by both HomeViewModel and LibraryViewModel
- [ ] Connectivity listener pattern extracted into shared mixin used by both view models
- [ ] _buildCards receives snapshot as parameter instead of reading service state
- [ ] LibraryViewModel unit tests cover: resolver-based locking, entitlement change triggers refresh, connectivity changes
- [ ] flutter analyze passes
- [ ] flutter test passes (all existing + new tests)

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
