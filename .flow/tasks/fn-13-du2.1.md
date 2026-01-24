# fn-13-du2.1 Replace _showTrialExpiredDialog() with showTrialExpiredModal() (Phase 3.1)

## Description

Replace the basic `_showTrialExpiredDialog()` method in `home_view.dart` with the new `showTrialExpiredModal()` entry function.

### Current Implementation
- **File:** `lib/home/home_view.dart`
- **Lines:** 319-353 (basic `AlertDialog`)

### New Implementation
```dart
Future<void> _showTrialExpiredDialog(HomeViewState state) async {
  final choice = await showTrialExpiredModal(
    context,
    activeProtocolCount: state.user?.activeProtocolCount ?? 0,
  );

  if (!mounted) return;

  switch (choice) {
    case TrialExpiredChoice.keepEverything:
      _viewModel.goToPaywall();
    case TrialExpiredChoice.continueWithFree:
      _viewModel.handleUseFreeTier();
    case null:
      // Modal dismissed without choice (shouldn't happen with barrierDismissible: false)
      break;
  }
}
```

### Required Import
```dart
import 'package:neurostack/paywall/widgets/trial_expired_modal.dart';
```

## Acceptance
- [ ] `_showTrialExpiredDialog()` calls `showTrialExpiredModal()` instead of `showDialog()`
- [ ] Method handles `TrialExpiredChoice.keepEverything` → `goToPaywall()`
- [ ] Method handles `TrialExpiredChoice.continueWithFree` → `handleUseFreeTier()`
- [ ] Method handles `null` case gracefully
- [ ] Import for `trial_expired_modal.dart` is added
- [ ] `flutter analyze` passes
- [ ] Existing tests pass

## Done summary
- Task completed
## Evidence
- Commits:
- Tests:
- PRs: