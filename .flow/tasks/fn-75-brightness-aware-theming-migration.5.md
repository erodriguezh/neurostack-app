## Description
Migrate home tab widgets from `kitColors.whiteXX` to `AppSemanticColors` tokens, including adaptive-route dialog surfaces. The home tab is an adaptive route — these widgets must be readable in both light and dark modes.

**Size:** M
**Files:**
- `lib/home/widgets/home_bottom_nav.dart` — replace `background.withValues(alpha: 0.85)`, `white10` border, `white40` inactive (lines 30-86)
- `lib/home/widgets/home_header.dart` — replace whiteXX usages
- `lib/home/widgets/home_empty_state.dart` — replace whiteXX usages
- `lib/home/widgets/home_protocol_card.dart` — replace 12+ whiteXX usages for borders/fills/text
- `lib/home/widgets/home_status_banner.dart` — replace `white10` border, `white05`/`white60`/`white70` (lines 49-136)
- `lib/home/widgets/home_status_dot.dart` — replace whiteXX usages
- `lib/home/home_view.dart` — migrate dialog surfaces from `kitColors.panel` to `colorScheme.surfaceContainer` or `semanticColors.surfaceElevated`
- `test/home/widgets/home_widgets_brightness_test.dart` (new)

## Approach
- `home_bottom_nav.dart` is the most impactful: its `kitColors.background.withValues(alpha: 0.85)` hardcodes a near-black pill. Replace with `semanticColors.surface` at appropriate opacity
- `home_protocol_card.dart` is the heaviest (12+ usages) — map each whiteXX to its semantic equivalent
- `home_view.dart` has dialogs with `AlertDialog.backgroundColor = kitColors.panel` — in light mode this produces dark text on dark panel (unreadable). Replace with semantic surface
- Use the contrast helper from `test/helpers/contrast_ratio.dart` (Task 3) for WCAG assertions
- Follow the pattern established in Task 4 for shared primitives
- Test all widgets in both brightness modes

## Key context
- `home_bottom_nav.dart` is shown on ALL tab routes (home/library/progress/settings) — high visual impact
- `home_status_banner.dart` uses `SpotlightCard` which takes `spotlightColor` as param — callers typically pass `kitColors.white05`, update call sites
- Dialog surfaces using `kitColors.panel` are a critical light-mode break — dark text on dark panel makes dialogs unreadable

## Acceptance
- [ ] No `whiteXX` usage in any `lib/home/widgets/` file for legibility-critical tokens
- [ ] `home_bottom_nav.dart` background adapts to brightness (light surface in light mode)
- [ ] `home_protocol_card.dart` text and borders readable in both modes
- [ ] `home_view.dart` dialog backgrounds use semantic surfaces (no `kitColors.panel`)
- [ ] All home widgets visually unchanged in dark mode
- [ ] Test: home widgets rendered in both Brightness.light and Brightness.dark
- [ ] Test: header text contrast >= 4.5:1 in both modes (using shared contrast helper)
