# Implementation Plan: Trial Expiration Modal

**Spec:** `docs/specs/20260120120000_spec_trial_expiration_modal.md`
**UI Design:** `docs/best_practices/design/screen-prompts/07-trial-expiration-modal.md`
**Functional Spec:** `docs/best_practices/design/screen-functional-specifications.md` (Section 9)

---

## Phase 0: Fix Modal Trigger Logic (Critical Bug) ✅ DONE

### 0.1 Update `_maybeTriggerExpiredModal()` in HomeViewModel ✅
- **File:** `lib/home/home_view_model.dart`
- **Current:** Checks `subscriptionStatus == SubscriptionStatus.expired`
- **Problem:** `expired` is for RevenueCat premium lapses, not trial expiration. Trial expiration keeps `subscriptionStatus == trial` in DB but `getEffectiveStatus()` returns `free`.
- **Fix:**
  ```dart
  void _maybeTriggerExpiredModal(User user) {
    if (_hasShownExpiredModal) return;

    // Check for trial expiration: stored status is trial, but effective status is free
    final isTrialExpired = user.subscriptionStatus == SubscriptionStatus.trial &&
        user.getEffectiveStatus(DateTime.now()) == SubscriptionStatus.free;

    // Also handle RevenueCat premium expiration
    final isPremiumExpired = user.subscriptionStatus == SubscriptionStatus.expired;

    if (isTrialExpired || isPremiumExpired) {
      _hasShownExpiredModal = true;
      state.value = state.value.copyWith(showTrialExpiredModal: true);
    }
  }
  ```

---

## Phase 1: Create Modal Widget

### 1.1 Create `TrialExpiredModal` widget ✅ DONE
- **New file:** `lib/paywall/widgets/trial_expired_modal.dart`
- **Pattern:** Use `showDialog()` with blur + fade animation (similar to `LogSessionModal`)
- **Components:**
  - Full-screen overlay with `#030303` background
  - Amber radial glow at top (similar to `AppGridBackground.showTopGlow`)
  - Hourglass icon (72px, amber stroke, glow effect) — use `LucideIcons.hourglass`
  - Headline using `context.textStyles.h2` (Newsreader 28px italic)
  - Conditional subtext when `activeProtocolCount > 2`
  - Two decision cards using `SpotlightCard`
- **Props:**
  ```dart
  final int activeProtocolCount;
  ```
- **Return value:** `TrialExpiredChoice` enum instead of callbacks
  ```dart
  enum TrialExpiredChoice { keepEverything, continueWithFree }
  ```
- **Blocking behavior:**
  - No close button
  - Cards are the only way to dismiss

### 1.2 Create `showTrialExpiredModal()` entry function ✅ DONE
- **Location:** `lib/paywall/widgets/trial_expired_modal.dart`
- **Signature:**
  ```dart
  Future<TrialExpiredChoice?> showTrialExpiredModal(
    BuildContext context, {
    required int activeProtocolCount,
  });
  ```
- **Implementation:**
  ```dart
  Future<TrialExpiredChoice?> showTrialExpiredModal(
    BuildContext context, {
    required int activeProtocolCount,
  }) async {
    return showDialog<TrialExpiredChoice>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xE6030303), // #030303 at 90%
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: TrialExpiredModal(
            activeProtocolCount: activeProtocolCount,
          ),
        );
      },
    );
  }
  ```

---

## Phase 2: Create Decision Card Widgets

### 2.1 Create `_UpgradeCard` widget (internal) ✅ DONE
- **Location:** `lib/paywall/widgets/trial_expired_modal.dart`
- **Styling:**
  - Wrap with `SpotlightCard` (ref: `lib/core/ui/widgets/spotlight_card.dart`)
  - `spotlightColor: context.kitColors.brandSky.withOpacity(0.1)`
  - `borderRadius: BorderRadius.circular(24)`
  - Border: `1px solid brandSky/30`
  - Background: `white/[0.02]`
- **Layout (Column):**
  ```dart
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(LucideIcons.crown, size: 28, color: brandSky, semanticLabel: 'Premium'),
      const SizedBox(height: 12),
      Text('Keep Everything', style: ...),  // Inter 18px medium, white/90
      const SizedBox(height: 4),
      Text('Subscribe to Premium', style: ...),  // Inter 14px light, brandSky
      const SizedBox(height: 12),
      Text('→', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.3))),
    ],
  )
  ```
- **Tap:** Return `TrialExpiredChoice.keepEverything`

### 2.2 Create `_DowngradeCard` widget (internal) ✅ DONE
- **Location:** `lib/paywall/widgets/trial_expired_modal.dart`
- **Styling:**
  - Container with `rounded-[24px]`, `p-6`
  - Border: `1px solid white/10`
  - Background: `white/[0.02]`
  - No spotlight effect (less prominent)
- **Layout (Column):**
  ```dart
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(LucideIcons.layers, size: 28, color: Colors.white.withOpacity(0.4), semanticLabel: 'Free tier'),
      const SizedBox(height: 12),
      Text('Continue with Free', style: ...),  // Inter 18px medium, white/70
      const SizedBox(height: 4),
      Text('Limited to 2 protocols', style: ...),  // Inter 14px light, white/40
    ],
  )
  ```
- **Tap:** Return `TrialExpiredChoice.continueWithFree`

---

## Phase 3: Update HomeView Integration

### 3.1 Replace `_showTrialExpiredDialog()` method ✅ DONE
- **File:** `lib/home/home_view.dart`
- **Current:** Lines 319-353 (basic `AlertDialog`)
- **Change:** Replace with call to `showTrialExpiredModal()` and handle result
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

### 3.2 Handle paywall dismiss → return to modal ✅ DONE
- **Logic:** After returning from `/paywall` without subscribing, re-show modal
- **Implementation:** Check subscription status after paywall navigation returns
- **Refactoring applied:** Extracted shared `isTrialOrPremiumExpired(User)` method to `HomeViewModel` to eliminate duplicated expiration-check logic between view and view model. The view now calls `_viewModel.isTrialOrPremiumExpired(user)` instead of having its own helper.

### 3.3 Update imports ✅ DONE
- **File:** `lib/home/home_view.dart`
- **Add:**
  ```dart
  import 'package:neurostack/paywall/widgets/trial_expired_modal.dart';
  ```

---

## Phase 4: Update ViewModel for Free Tier Transition

### 4.1 Add `CachedUserStore` dependency to HomeViewModel ✅ DONE
- **File:** `lib/home/home_view_model.dart`
- **Constructor change:**
  ```dart
  HomeViewModel({
    // ... existing params ...
    CachedUserStore? cachedUserStore,
  }) : // ... existing assignments ...
       _cachedUserStore = cachedUserStore;

  final CachedUserStore? _cachedUserStore;
  ```
- **Import:** `import 'package:neurostack/features/auth/data/cached_user_store.dart';`

### 4.2 Update HomeView to inject CachedUserStore ✅ DONE
- **File:** `lib/home/home_view.dart`
- **Change:**
  ```dart
  late final HomeViewModel _viewModel = HomeViewModel(
    // ... existing params ...
    cachedUserStore: locator<CachedUserStore>(),
  );
  ```
- **Import:** `import 'package:neurostack/features/auth/data/cached_user_store.dart';`

### 4.3 Update `handleUseFreeTier()` method ✅ DONE
- **File:** `lib/home/home_view_model.dart`
- **Current:** Lines 194-203 (only shows deactivation modal if >2)
- **Change:** Add status transition to `free` when ≤2 protocols
  ```dart
  Future<void> handleUseFreeTier() async {
    final user = state.value.user;
    if (user == null) return;

    if (user.activeProtocolCount > 2) {
      state.value = state.value.copyWith(showDeactivationModal: true);
      return;
    }

    // ≤2 protocols: transition to free tier
    final updatedUser = user.updateSubscriptionStatus(SubscriptionStatus.free);
    await _userRepository.save(updatedUser);
    await _cachedUserStore?.saveUser(updatedUser);

    // Refresh state with updated user
    await refresh();
  }
  ```
- **Additional fixes applied:**
  - Added proper `Either` result handling for `_userRepository.save()` with error toast
  - Added try-catch around `_cachedUserStore?.saveUser()` for robustness
  - Fixed `isTrialOrPremiumExpired()` to check raw `subscriptionStatus` instead of `effectiveStatus`, preventing modal re-trigger after user chooses free tier

### 4.4 Verify `updateSubscriptionStatus()` exists on User ✅ DONE
- **File:** `lib/features/user/domain/entities/user.dart`
- **Status:** ✅ Method exists at line 287, returns updated `User` with new status

---

## Phase 5: Testing

### 5.1 Create test directory ✅ DONE
- **New directory:** `test/paywall/widgets/`

### 5.2 Widget tests ✅ DONE
- **New file:** `test/paywall/widgets/trial_expired_modal_test.dart`
- **Cases:**
  - Modal renders headline "Your Premium Trial Has Ended"
  - Subtext hidden when `activeProtocolCount <= 2`
  - Subtext shows count when `activeProtocolCount > 2`
  - "Keep Everything" tap returns `TrialExpiredChoice.keepEverything`
  - "Continue with Free" tap returns `TrialExpiredChoice.continueWithFree`
  - Modal cannot be dismissed by tapping outside
  - Icons have semanticLabel for accessibility

### 5.3 ViewModel tests ✅ DONE
- **New file:** `test/home/home_view_model_test.dart`
- **Add cases:**
  - `handleUseFreeTier()` with 2 protocols → status becomes `free`, cache updated
  - `handleUseFreeTier()` with 3 protocols → triggers deactivation modal
  - `_maybeTriggerExpiredModal()` triggers for trial expiration (trial + effective free)
  - `_maybeTriggerExpiredModal()` triggers for premium expiration (expired status)
  - `_maybeTriggerExpiredModal()` does not trigger for active trial
  - _(additional regression tests added for free user with expired trialPeriod)_


---

## File Summary

### New Files
| File | Purpose |
|------|---------|
| `lib/paywall/widgets/trial_expired_modal.dart` | Modal widget + entry function + `TrialExpiredChoice` enum |
| `test/paywall/widgets/trial_expired_modal_test.dart` | Widget tests |

### Modified Files
| File | Changes |
|------|---------|
| `lib/home/home_view_model.dart` | Fix trigger logic, add `CachedUserStore`, update `handleUseFreeTier()` |
| `lib/home/home_view.dart` | Inject `CachedUserStore`, replace dialog with new modal, handle paywall return |

---

## Verification Steps

1. **Build passes:** `flutter analyze`
2. **Tests pass:** `flutter test test/paywall/ test/home/`
3. **Manual test - expired trial with 2 protocols:**
   - Set user to `trial` status with expired trial period and 2 active protocols
   - Launch app → modal appears
   - Tap "Continue with Free" → modal dismisses, home loads
   - Verify status is now `free`
4. **Manual test - expired trial with 3 protocols:**
   - Set user to `trial` status with expired trial period and 3 active protocols
   - Launch app → modal appears
   - Tap "Continue with Free" → deactivation placeholder shows
5. **Manual test - paywall navigation (no subscribe):**
   - Tap "Keep Everything" → navigates to `/paywall`
   - Back-navigate without subscribing → returns to trial expired modal
6. **Manual test - paywall navigation (subscribe):**
   - Tap "Keep Everything" → navigates to `/paywall`
   - Complete subscription → returns to home, modal does not reappear

---

## Implementation Order

1. **Phase 0:** Fix trigger logic in `home_view_model.dart` (critical bug) ✅
2. **Phase 1-2:** Create `trial_expired_modal.dart` with widget + entry function
3. **Phase 5.1-5.2:** Add widget tests
4. **Phase 3:** Update `home_view.dart` to use new modal
5. **Phase 4:** Add `CachedUserStore` dependency and update `handleUseFreeTier()`
6. **Phase 5.3:** Add ViewModel tests
7. Manual verification
8. Update `docs/README.md` with spec link
9. **Phase 6:** Design and implement trial expiration cronjob (backend)

---

## Review Changes Applied

From Carmack-level plan review (2026-01-20):

1. ✅ **Critical:** Fixed trigger logic to detect trial expiration correctly
2. ✅ Added `CachedUserStore` dependency for cache consistency
3. ✅ Changed from callbacks to return value for cleaner navigation
4. ✅ Specified `lucide_icons_flutter` for hourglass and crown icons
5. ✅ Added blur + fade animation matching `LogSessionModal`
6. ✅ Added `semanticLabel` for icon accessibility
7. ✅ Added paywall dismiss → modal return edge case
8. ✅ Explicit arrow placement in card Column layout
9. ✅ Clarified `showDialog()` pattern (not bottom sheet)
