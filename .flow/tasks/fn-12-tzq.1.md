# fn-12-tzq.1 Create _UpgradeCard widget (Phase 2.1)

## Description

Create `_UpgradeCard` private widget inside `lib/paywall/widgets/trial_expired_modal.dart`

**Plan reference:** `plan_trial_expiration_modal.md` Phase 2.1

### Styling
- Wrap with `SpotlightCard` (ref: `lib/core/ui/widgets/spotlight_card.dart`)
- `spotlightColor: context.kitColors.brandSky.withOpacity(0.1)`
- `borderRadius: BorderRadius.circular(24)`
- Border: `1px solid brandSky/30`
- Background: `white/[0.02]`

### Layout (Column)
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

### Behavior
- On tap: Return `TrialExpiredChoice.keepEverything` via `Navigator.pop()`

## Files to modify
- `lib/paywall/widgets/trial_expired_modal.dart` - Add `_UpgradeCard` widget

## Acceptance
- [ ] `_UpgradeCard` is a private StatelessWidget
- [ ] Uses SpotlightCard wrapper with correct styling
- [ ] Has crown icon with semanticLabel
- [ ] Shows "Keep Everything" headline
- [ ] Shows "Subscribe to Premium" subtitle
- [ ] Shows arrow indicator
- [ ] Tapping returns `TrialExpiredChoice.keepEverything`
- [ ] `flutter analyze` passes

## Done summary
The _UpgradeCard widget was already implemented in commit b94daaf. It uses SpotlightCard with brandSky spotlight, displays crown icon with "Keep Everything" headline and "Subscribe to Premium" subtitle, includes an arrow indicator, and returns TrialExpiredChoice.keepEverything on tap. Flutter analyze passes.
## Evidence
- Commits: b94daaf
- Tests: flutter analyze lib/paywall/widgets/trial_expired_modal.dart
- PRs: