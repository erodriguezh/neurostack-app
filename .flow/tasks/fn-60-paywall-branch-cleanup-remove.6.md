# fn-60-paywall-branch-cleanup-remove.6 Run static analysis and final validation

## Description
Final validation pass after all cleanup tasks. Run static analysis, full test suite, and verify no regressions.

**Size:** S
**Files:** None (validation only)

## Steps

1. Run `flutter analyze` — must pass with zero warnings/errors
2. Run `flutter test` — all tests must pass
3. Run `dart format lib test` — verify formatting
4. Grep for any remaining known dead code patterns:
   - `grep -r "ExpirationDecision\|isResolved\|markResolved\|upgradeToPremium\|updateSubscriptionStatus\|TrialStartedEvent\|SubscriptionUpgradedEvent" lib/`
   - Should return zero results
5. Verify no cross-module imports of `home_state.dart` from Library/Progress for `HomeBottomTab`
6. Spot-check that shared widgets are properly imported in views

## Key context

- This is a validation-only task — no code changes unless issues found
- If issues are found, fix them in this task (they should be minor)
## Acceptance
- [ ] `flutter analyze` passes with zero warnings
- [ ] `flutter test` passes (all tests green)
- [ ] `dart format lib test` produces no changes
- [ ] Grep for dead code patterns returns zero results in `lib/`
- [ ] No cross-module `HomeBottomTab` imports from `home_state.dart`
## Done summary
Final validation pass: applied dart format across 80 files, removed HomeBottomTab re-export from home_state.dart, added direct imports in home_view_model.dart and progress_view.dart. All acceptance criteria verified: flutter analyze (zero issues), flutter test (all green), no dead code patterns, no cross-module HomeBottomTab imports.
## Evidence
- Commits: 6552cf75e5b91d417bc1d23737aada0a21fefa95
- Tests: flutter analyze, flutter test, dart format lib test --set-exit-if-changed
- PRs: