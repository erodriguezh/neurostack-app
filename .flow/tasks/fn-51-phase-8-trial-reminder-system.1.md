# fn-51-phase-8-trial-reminder-system.1 Create TrialReminderService and register in DI (Phase 8.2-8.3)

## Description

Create `lib/paywall/data/trial_reminder_service.dart` implementing once-per-day trial reminder throttling (INV-P4).

Currently, `HomeViewModel._maybeTriggerExpiredModal()` calls `_resolver.shouldShowTrialReminder()` to compute whether to show the reminder. However, there's no persistence of when the reminder was last shown, so it would re-show on every app launch/refresh.

The TrialReminderService adds:
- User-scoped persistence of last reminder shown time via SharedPreferences
- Key format: `trialReminder:lastShownAt:<userId>`
- Once-per-day throttle: if reminder was shown within last 24h, suppress it
- Delegates to SubscriptionStatusResolver for the "should show" check
- Pure `DateTime now` parameter for testability

Then register the service in `lib/config/locator_config.dart`.

Finally, wire it into HomeViewModel so `showTrialReminder` respects the once-per-day throttle.

### Key files
- New: `lib/paywall/data/trial_reminder_service.dart`
- New: `test/paywall/data/trial_reminder_service_test.dart`
- Modified: `lib/config/locator_config.dart` (add DI registration)
- Modified: `lib/home/home_view_model.dart` (use TrialReminderService)

## Acceptance
- [ ] `lib/paywall/data/trial_reminder_service.dart` exists with `shouldShowTrialReminder()` and `markReminderShown()` methods
- [ ] Uses SharedPreferences for user-scoped persistence
- [ ] Once-per-day throttle: returns false if shown within last 24 hours
- [ ] Delegates to SubscriptionStatusResolver for the expiration-window check
- [ ] Registered in locator_config.dart
- [ ] HomeViewModel updated to use TrialReminderService for reminder logic
- [ ] Unit tests for TrialReminderService
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes

## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
