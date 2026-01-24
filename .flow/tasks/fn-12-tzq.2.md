# fn-12-tzq.2 Create _DowngradeCard widget (Phase 2.2)

## Description

Create/update `_DowngradeCard` private widget inside `lib/paywall/widgets/trial_expired_modal.dart`

**Plan reference:** `plan_trial_expiration_modal.md` Phase 2.2

### Styling
- Container with `rounded-[24px]`, `p-6` (use `spacing.lg`)
- Border: `1px solid white/10`
- Background: `white/[0.02]`
- No spotlight effect (less prominent than _UpgradeCard)

### Layout (Column)
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

### Known issue to fix
- Line 361 has `const SizedBox(height: 4)` - should be `SizedBox(height: spacing.xs)` for consistency

### Behavior
- On tap: Return `TrialExpiredChoice.continueWithFree` via callback

## Files to modify
- `lib/paywall/widgets/trial_expired_modal.dart` - Update `_DowngradeCard` widget

## Acceptance
- [ ] `_DowngradeCard` is a private StatelessWidget
- [ ] Uses correct container styling (no SpotlightCard)
- [ ] Has layers icon with semanticLabel
- [ ] Shows "Continue with Free" headline
- [ ] Shows "Limited to 2 protocols" subtitle
- [ ] Tapping returns `TrialExpiredChoice.continueWithFree`
- [ ] Uses `spacing.xs` instead of hardcoded `4`
- [ ] `flutter analyze` passes

## Done summary
Fixed spacing consistency in _DowngradeCard by replacing hardcoded `SizedBox(height: 4)` with `SizedBox(height: spacing.xs)` to match the pattern used in _UpgradeCard.
## Evidence
- Commits: c4a211ff8c1a64a641a5ad3e538edcfbbb8e6e68
- Tests: flutter analyze lib/paywall/widgets/trial_expired_modal.dart
- PRs: