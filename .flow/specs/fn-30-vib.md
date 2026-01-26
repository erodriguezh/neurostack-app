# fn-30-vib Paywall Modal - Phase 0.3: Update Onboarding Copy

## Overview

RevenueCat trials require a payment method upfront (credit card required before trial starts). The current onboarding copy in `offer_screen.dart` contradicts this new payment model and must be updated.

## Scope

**File to modify:** `lib/features/onboarding/presentation/widgets/screens/offer_screen.dart`

**Changes required:**
1. Remove "No credit card required" - This is now false with RevenueCat
2. Change CTA button text from "Start my free trial" to "Start free" or "Continue"
3. Optionally add disclaimer if keeping trial language

## Approach

1. Read the current offer_screen.dart to understand the existing copy
2. Replace misleading copy with honest, appealing alternatives
3. Verify the app builds and the screen renders correctly

## Quick commands

- `flutter analyze`
- `flutter test`

## Acceptance

- [ ] "No credit card required" text is removed or replaced with something honest and appealing
- [ ] CTA button text updated (no longer implies immediate trial start)
- [ ] Copy is honest about the payment model
- [ ] `flutter analyze` passes
- [ ] App builds and runs

## References

- Plan: `plan_paywall_modal.md` Phase 0.3
- File: `lib/features/onboarding/presentation/widgets/screens/offer_screen.dart`
