# Paywall Branch Cleanup Phase 2: Dedup, Deprecations, Patterns

## Overview

Second cleanup pass on the `feature/paywall-modal` branch after the Phase 13 cleanup (fn-60). The first pass addressed the largest issues (dead domain code, shared widget extraction, mock consolidation, ViewModel utility extraction). This pass targets remaining issues found via deep codebase scanning:

- Commented-out code and stale doc comments
- `mocktail` incorrectly in `dependencies` instead of `dev_dependencies`
- Deprecated `WillPopScope` usage (must be migrated to `PopScope`)
- Remaining test mock/fake duplication across 5+ files
- Incomplete adoption of `EntitlementSnapshotFactory` in tests
- Inconsistent snapshot scoping pattern between ViewModels
- 2 deprecated spec/investigation docs missing DEPRECATED headers

**Scope:** Internal refactoring only — no user-visible changes, no new features, no behavioral changes. The WillPopScope → PopScope migration MUST preserve identical blocking-modal semantics (system back blocked, programmatic pop via buttons still works).

## Quick commands

```bash
flutter analyze           # Must report 0 issues
flutter test              # Must all pass
dart fix --dry-run        # Preview automated fixes
rg WillPopScope lib/ test/ # Must return 0 matches after task 3
```

## Task parallelizability

Tasks 1, 2, and 3 target mostly disjoint file sets and CAN run in parallel with one caveat: Task 1's `dart fix --apply` and `build_runner` regeneration are repo-wide operations that touch files across `lib/` and `test/`. To avoid merge conflicts:

- **Run `dart fix --apply` and `build_runner` regeneration AFTER Tasks 2 and 3 have merged**, or coordinate if running earlier.
- If running tasks on separate branches, merge Task 2 and Task 3 first, then run Task 1's global fix steps on the combined result.

## Acceptance

- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` — all tests pass
- [ ] No commented-out code blocks in `lib/paywall/`
- [ ] `mocktail` is in `dev_dependencies`, not `dependencies`
- [ ] `rg WillPopScope lib/ test/` returns 0 matches (all migrated to `PopScope`)
- [ ] All paywall-related test mocks consolidated in `test/mocks/` (verified by repo-wide scan: `rg "extends Mock implements" test/` and `rg "extends Fake implements" test/`)
- [ ] Deprecated specs have DEPRECATED headers
- [ ] `rg INV-U3 lib/ docs/` — every match either has `(DEPRECATED)` annotation or is in `ubiquitous-language.md` where it is already marked
- [ ] All generated `.freezed.dart`/`.g.dart` files have a matching source `.dart` file (no orphans)
- [ ] PopScope migration includes explicit widget tests verifying system-back is blocked AND button pops succeed with correct results
- [ ] Snapshot scoping removal is backed by regression tests proving mismatched (user, snapshot.appUserId) combinations are handled safely by `SubscriptionStatusResolver`

## Out of Scope

- `progress_view_model_test.dart` inline fakes (10 stateful fakes, ~280 lines) — these have custom stateful behavior not expressible via mocktail; separate epic if addressed
- Enabling `unreachable_from_main` lint rule — separate concern with its own blast radius
- Cross-test-runner mock sharing (unit vs integration) — Dart test runner limitation

## Key Context

- **WillPopScope → PopScope: requires a guarded-pop pattern.** The trial-expired modal blocks system-back while allowing programmatic `Navigator.pop(result)` from buttons. Key facts about `PopScope`:
  - `PopScope(canPop: false)` blocks ALL pops — both system back AND programmatic `Navigator.pop()`. The buttons would break.
  - `onPopInvokedWithResult` is called for ALL pop attempts (system + programmatic). It does NOT distinguish the source of the pop.
  - To preserve the WillPopScope semantics (block system back, allow button pops), you MUST use a local state guard: the button sets a flag (e.g., `_allowNextPop = true`), calls `Navigator.of(context).maybePop(result)`, and `PopScope` reads `canPop` dynamically from that flag. After the pop succeeds (`didPop == true`), reset the flag.
  - `barrierDismissible: false` on `showDialog` does NOT block system back — only barrier taps. A `PopScope` wrapper is REQUIRED.
  - See `onboarding_view.dart` for the repo's existing PopScope pattern. See `lib/paywall/widgets/trial_expired_modal.dart:104-106` for the current WillPopScope usage.
- **Conditional imports are fragile.** `RevenueCatClientStub` is loaded via conditional import for web. Do NOT touch the import chain in `revenuecat_client_factory.dart`.
- **`EntitlementSnapshotFactory` adoption:** Only migrate tests where the factory covers the scenario AND the test does not assert on fields the factory hardcodes (especially `expirationDate` relative to `now`, `latestPurchaseDate`, and `originalTransactionId`). When the factory covers the scenario but the test asserts on specific field values, use the factory with explicit parameters to preserve the exact values. Tests in `entitlement_snapshot_test.dart` deliberately construct edge-case snapshots and should keep inline constructors.
- **Snapshot scoping removal safety** relies on two independent invariants: (1) `RevenueCatService` only sets `entitlementSnapshot.value` when `snapshot.appUserId == _identifiedUserId`, and (2) `SubscriptionStatusResolver.resolveEffectiveStatus()` checks `snapshot.isForUser(user.id)` internally. Both invariants must be enforced with tests. If either regresses, cross-user subscription state leaks could occur. After removing `_scopedSnapshot`, add regression tests verifying mismatched user/snapshot combinations are handled safely.

## References

- fn-60 (Phase 13 first cleanup): `.flow/specs/fn-60-paywall-branch-cleanup-remove.md`
- Plan: `plan_paywall_modal.md` (Phase 13)
- Paywall spec: `docs/specs/20260123220000_spec_paywall_modal.md`
- `EntitlementSnapshotFactory`: `test/factories/entitlement_snapshot_factory.dart`
- Centralized mocks: `test/mocks/mock_services.dart`
- `onboarding_view.dart`: Reference for correct `PopScope` usage pattern
