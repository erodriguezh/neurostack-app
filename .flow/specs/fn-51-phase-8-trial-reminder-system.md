# fn-51-phase-8-trial-reminder-system Phase 8: Trial Reminder System

## Overview
Phase 8 of the RevenueCat Paywall Integration plan. The trial reminder alert widget already exists (created in Phase 6.4/fn-48). What remains is creating TrialReminderService with once-per-day throttling, DI registration, and wiring RevenueCat entitlement refresh on app resume.

## Scope
- Create `lib/paywall/data/trial_reminder_service.dart` with once-per-day throttle (INV-P4)
- Register TrialReminderService in DI
- Wire HomeViewModel to use TrialReminderService
- Wire RevenueCat refresh on app resume via AppLifecycleService

## Approach
- TrialReminderService wraps SubscriptionStatusResolver.shouldShowTrialReminder() with user-scoped SharedPreferences persistence
- AppLifecycleService gets RevenueCatService injected to refresh on resume

## Quick commands
- `flutter analyze`
- `flutter test`

## Acceptance
- [ ] TrialReminderService created with once-per-day throttle
- [ ] Registered in DI
- [ ] HomeViewModel uses TrialReminderService for trial reminder logic
- [ ] AppLifecycleService refreshes RevenueCat on app resume
- [ ] Tests pass

## References
- Plan: `plan_paywall_modal.md` Phase 8
- Existing resolver: `lib/paywall/domain/subscription_status_resolver.dart`
- Existing widget: `lib/paywall/widgets/trial_reminder_alert.dart`
- Existing lifecycle: `lib/core/utils/app_lifecycle_service.dart`
