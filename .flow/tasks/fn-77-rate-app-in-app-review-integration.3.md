# fn-77-rate-app-in-app-review-integration.3 Wire Settings tile and programmatic session trigger

## Description
Wire the Settings "Rate the App" tile to navigate to the Rate App screen via `SettingsViewModel` using `RouterService`, and add the programmatic `requestReview()` trigger after session logging in HomeView and ProgressView using the shared `ReviewTriggerHelper`.

**Size:** M
**Files:**
- `lib/settings/settings_view.dart` (wire tile tap to ViewModel method)
- `lib/settings/settings_view_model.dart` (add `goToRateApp()` method)
- `lib/settings/widgets/settings_support_section.dart` (update trailing icon)
- `lib/home/home_view.dart` (add programmatic trigger using ReviewTriggerHelper)
- `lib/progress/progress_view.dart` (add programmatic trigger using ReviewTriggerHelper)
- `test/home/post_modal_review_trigger_test.dart` (new — integration test for callback-future orchestration)

## Approach

### Settings tile wiring
- Add `goToRateApp()` method to `SettingsViewModel` — uses `_routerService.goTo(Path(name: '/settings/rate-app'))` following existing pattern of `goToPaywall()`, `goToContact()`, etc.
- In `settings_view.dart:109`, replace `onRateAppTap: () {}` with `onRateAppTap: _viewModel.goToRateApp`
- In `settings_support_section.dart`, change trailing icon from `LucideIcons.externalLink` to `LucideIcons.chevronRight`

### Programmatic trigger (using shared ReviewTriggerHelper)

Both HomeView and ProgressView use the same `ReviewTriggerHelper` (created in task 1) — no logic duplication.

**Callback contract constraint**: `showLogSessionModal` takes `void Function(Session session)` as `onSessionLogged`. The callback is synchronous (`void` return), so async work inside it is fire-and-forget from the modal's perspective. We handle this by storing the `Future<int>` and awaiting it after modal dismiss.

- In `home_view.dart`, inside `_showLogSessionModal`:
  1. Declare `Future<int>? sessionCountFuture;` before `showLogSessionModal` call
  2. **In `onSessionLogged` callback** (fires pre-dismiss, after save, before sync moves data):
     ```dart
     sessionCountFuture = locator<ReviewTriggerHelper>().captureSessionCount(userId);
     ```
     Fire-and-forget from the modal's perspective, but we hold the `Future<int>` reference.
  3. After `await showLogSessionModal()` returns (modal dismissed):
     ```dart
     if (sessionCountFuture != null) {
       try {
         final count = await sessionCountFuture!;
         await locator<ReviewTriggerHelper>().triggerReviewIfNeeded(count, userId);
       } catch (_) {
         // Non-critical — review prompt is best-effort
       }
     }
     ```
  4. Add `// TODO(analytics): track review prompt event`

- Same pattern in `progress_view.dart`

- **No changes** to `showLogSessionModal` callback contract — `void Function(Session)` is preserved

### Callback-future orchestration integration test

Add a dedicated test that verifies the full sequencing:
1. `captureSessionCount` Future is initiated when `onSessionLogged` fires
2. The Future runs concurrently (not blocked by modal)
3. After modal dismiss simulation, `await sessionCountFuture` resolves with correct count
4. `triggerReviewIfNeeded` is called after dismiss with the captured count
5. 2-second delay occurs before `requestReviewIfNeeded` fires

Test approach: mock `ReviewTriggerHelper`, simulate the callback-await-trigger sequence in a unit test. Use `FakeAsync` for delay verification.

## Key context

- The `onSessionLogged` callback fires BEFORE modal dismiss — this is where we start count capture (safe snapshot point).
- `showLogSessionModal` is async and the caller awaits it — the code after `await` runs when the modal is gone.
- The 2-second delay is intentional: lets the success toast and haptic feedback land before any review dialog appears.
- Navigation uses `RouterService.goTo(Path(name: ...))`, NOT GoRouter.

## Acceptance
- [ ] `goToRateApp()` method added to `SettingsViewModel` using `_routerService.goTo(Path(name: '/settings/rate-app'))`
- [ ] Settings "Rate the App" tile delegates to `SettingsViewModel.goToRateApp()`
- [ ] Tile trailing icon changed from `externalLink` to `chevronRight`
- [ ] Programmatic trigger added in `home_view.dart` using `ReviewTriggerHelper`
- [ ] Programmatic trigger added in `progress_view.dart` using `ReviewTriggerHelper`
- [ ] Session count Future started in `onSessionLogged` callback (fire-and-forget from modal, stored as `Future<int>?`)
- [ ] Captured count Future awaited after modal dismiss, passed to `triggerReviewIfNeeded`
- [ ] `showLogSessionModal` callback contract preserved (`void Function(Session)` — no changes)
- [ ] Integration test verifies: Future started in callback, awaited after dismiss, delayed trigger fires with correct count
- [ ] All trigger code wrapped in try/catch
- [ ] `// TODO(analytics)` comment at trigger call sites
- [ ] `goToRateApp()` tested: verify `RouterService.goTo` called with correct path
- [ ] `flutter analyze` passes

## Done summary
Wire Settings "Rate the App" tile to navigate via SettingsViewModel.goToRateApp(), change trailing icon to chevronRight, and add programmatic review trigger in HomeView and ProgressView using ReviewTriggerHelper with fire-and-forget callback-future orchestration pattern decoupled from modal lifecycle.
## Evidence
- Commits: cdf788990c17b6b122f27b05a6ea3aedd9d109e2, f8a526685eaff1650794b6d861a56eb653954bc8
- Tests: flutter test test/settings/settings_view_model_test.dart, flutter test test/core/utils/in_app_review/, flutter test test/home/post_modal_review_trigger_test.dart, flutter analyze
- PRs: