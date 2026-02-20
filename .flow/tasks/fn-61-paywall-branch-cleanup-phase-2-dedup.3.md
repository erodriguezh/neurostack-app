# fn-61-paywall-branch-cleanup-phase-2-dedup.3 Production code patterns: WillPopScope migration and snapshot scoping

## Description
Fix two production code pattern issues: migrate ALL deprecated `WillPopScope` usages to `PopScope` with behavior-preserving semantics using a guarded-pop pattern, and align the entitlement snapshot scoping pattern between HomeViewModel and LibraryViewModel with regression tests.

**Size:** M
**Files:**
- `lib/paywall/widgets/trial_expired_modal.dart` (WillPopScope → PopScope with guarded-pop pattern)
- `test/paywall/widgets/trial_expired_modal_test.dart` (add/update back-button test)
- `lib/home/home_view_model.dart` (remove redundant `_scopedSnapshot`)
- `lib/library/library_view_model.dart` (verify pattern consistency)
- `test/home/home_view_model_test.dart` (add mismatched user/snapshot regression test)
- `test/paywall/domain/subscription_status_resolver_test.dart` (add mismatched user/snapshot regression test)
- Any other file found by `rg WillPopScope lib/ test/`

## Approach

### Phase A: WillPopScope → PopScope migration

1. **Search the ENTIRE repo** with `rg WillPopScope lib/ test/` and migrate ALL occurrences. The known instance is at `lib/paywall/widgets/trial_expired_modal.dart:104-106`.

2. **The migrated implementation uses the simple `PopScope(canPop: false)` pattern:**

   Key facts about `PopScope` (corrected during implementation):
   - `PopScope(canPop: false)` blocks only **system-initiated** pops (Android back button, escape key, `maybePop()`).
   - `Navigator.pop()` **bypasses `PopScope` entirely** — it always succeeds regardless of `canPop`.
   - Therefore, no guarded-pop pattern or state flag is needed. The simple approach works:

   **Implemented pattern:**

   a. Wrap the dialog content with `PopScope(canPop: false)`:
      ```dart
      PopScope(
        canPop: false,
        child: Dialog(...)
      )
      ```

   b. Buttons continue to use `Navigator.of(context).pop(result)` directly.

   This ensures:
   - System back (Android back / escape) → `canPop` is `false` → pop blocked
   - Button tap → `Navigator.pop(result)` → bypasses `PopScope` → pop succeeds with result

   > **Note:** The original spec prescribed a guarded-pop pattern with `_allowNextPop` state flag and `maybePop()`, based on the incorrect premise that `PopScope(canPop: false)` blocks `Navigator.pop()`. This was corrected during implementation.

3. **Remove the `// ignore: deprecated_member_use` comment.**

4. **Add widget tests** in `test/paywall/widgets/trial_expired_modal_test.dart`:
   - System back button does not dismiss the modal (use `tester.binding.handlePopRoute()` or `tester.sendKeyEvent(LogicalKeyboardKey.escape)`)
   - "Keep Everything" button pops with `TrialExpiredChoice.keepEverything`
   - "Continue with Free" button pops with `TrialExpiredChoice.continueWithFree`

5. **Confirm `rg WillPopScope lib/ test/` returns 0 matches.**

### Phase B: Snapshot scoping alignment

6. **Add invariant documentation to `RevenueCatService`** on the `entitlementSnapshot` field:
   ```dart
   /// Invariant: When non-null, always corresponds to the currently
   /// identified userId ([_identifiedUserId]). Cleared on logout().
   ```

7. **Remove `_scopedSnapshot` from HomeViewModel** (Option A from epic).

   **Why this is safe:** `RevenueCatService` already filters snapshots by `_identifiedUserId` before setting `entitlementSnapshot.value`:
   - In the entitlement listener: `if (_identifiedUserId != null && snapshot.appUserId == _identifiedUserId)`
   - In `refreshEntitlement`: only updates if non-null
   - On `logout()`: clears both `_identifiedUserId` and `entitlementSnapshot.value`

   Additionally, `SubscriptionStatusResolver.resolveEffectiveStatus()` checks `snapshot.isForUser(user.id)` internally. The `_scopedSnapshot` helper in HomeViewModel adds no additional safety.

8. **Update HomeViewModel** to pass the raw snapshot directly (matching LibraryViewModel's pattern). This applies to all callsites that currently use `_scopedSnapshot(user)`:
   - `resolveEffectiveStatus(user: user, snapshot: rawSnapshot)`
   - `_trialReminderService.shouldShowTrialReminder(snapshot: rawSnapshot, ...)`

9. **Add a doc comment** where `_scopedSnapshot` was removed, noting that scoping safety relies on `RevenueCatService` invariants. If those invariants ever change, snapshot scoping should be reintroduced.

10. **Add regression tests for snapshot scoping invariants:**

    a. In `test/paywall/domain/subscription_status_resolver_test.dart` (or appropriate resolver test file), add a test:
       - Pass `user.id == 'user-a'` and `snapshot.appUserId == 'user-b'`
       - Assert that `resolveEffectiveStatus` treats the mismatched snapshot as null-equivalent or resolves to a safe fallback consistent with DB state

    b. In `test/home/home_view_model_test.dart`, add a test:
       - Set up a scenario where `entitlementSnapshot.value` has a different `appUserId` than the current user
       - Assert that the effective status for the current user is NOT influenced by the mismatched snapshot

    These tests guard against future changes that might break the "scoped to user" assumption.

11. **Run `flutter test`** to verify no behavioral change.

## Key context

- **PopScope API (Flutter 3.12+):** `PopScope(canPop: bool, onPopInvokedWithResult: callback)` replaced `WillPopScope`. Key insight: `Navigator.pop()` bypasses `PopScope` entirely — only system-initiated pops (back button, escape, `maybePop()`) respect `canPop`. For blocking modals where buttons use `Navigator.pop(result)`, simply `PopScope(canPop: false)` suffices.
- The `showDialog` call for trial-expired modal uses `barrierDismissible: false` — this only prevents barrier-tap dismissal, NOT system back.
- Check `onboarding_view.dart` for the repo's existing `PopScope` pattern — follow it for consistency.
- If `RevenueCatService` invariants ever change (e.g., snapshot set without user filtering), snapshot scoping should be reintroduced in a shared helper (e.g., in `EntitlementListenerMixin`).
- **Two independent invariants protect against cross-user leaks:** (1) RevenueCatService filters by `_identifiedUserId`, (2) `SubscriptionStatusResolver` checks `snapshot.isForUser(user.id)`. Both must hold; regression tests in step 10 enforce this.

## Acceptance
- [ ] `rg WillPopScope lib/ test/` returns 0 matches
- [ ] No `// ignore: deprecated_member_use` suppress for WillPopScope
- [ ] Trial-expired modal uses `PopScope(canPop: false)` with direct `Navigator.pop(result)` from buttons
- [ ] Trial-expired modal blocks system-back dismissal (verified by widget test)
- [ ] "Keep Everything" button pops modal with `TrialExpiredChoice.keepEverything` (verified by widget test)
- [ ] "Continue with Free" button pops modal with `TrialExpiredChoice.continueWithFree` (verified by widget test)
- [ ] `RevenueCatService.entitlementSnapshot` has invariant doc comment
- [ ] `_scopedSnapshot` removed from HomeViewModel — raw snapshot passed directly
- [ ] Snapshot scoping pattern is consistent between HomeViewModel and LibraryViewModel
- [ ] Doc comment added noting RevenueCatService invariants that make scoping safe
- [ ] Regression test: `SubscriptionStatusResolver` handles mismatched user/snapshot safely
- [ ] Regression test: HomeViewModel effective status not influenced by mismatched snapshot
- [ ] `flutter analyze` reports 0 issues
- [ ] `flutter test` all pass
## Done summary
Migrated WillPopScope→PopScope(canPop: false) in trial_expired_modal.dart with the simpler pattern (Navigator.pop bypasses PopScope). Removed redundant _scopedSnapshot from HomeViewModel, aligning with LibraryViewModel's pattern. Added invariant docs to RevenueCatService.entitlementSnapshot and SubscriptionStatusResolver.shouldShowTrialExpiredModal. Added 7 new tests: system-back blocked, escape blocked, button pops with correct choices, and mismatched user/snapshot regression tests for both resolver and HomeViewModel. Standardized INV-U3 (DEPRECATED) annotation format across docs. Corrected PopScope misconception in epic and task specs.
## Evidence
- Commits: a50f642
- Tests: flutter test — 530 passing, flutter analyze — 0 issues
- PRs: