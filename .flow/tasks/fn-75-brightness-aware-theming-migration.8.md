## Description
Migrate settings and contact view widgets from `kitColors.whiteXX` to semantic tokens. Settings and contact are adaptive routes.

**Size:** M
**Files:**
- `lib/settings/widgets/settings_support_section.dart` — replace `white40`, `white10`, `white05` (lines 107-130)
- `lib/settings/widgets/settings_tile.dart` — replace `white40`, `white80`, `white20` (lines 67-88)
- `lib/settings/widgets/settings_upgrade_banner.dart` — replace `white90`, `white50`, `white30` (lines 97-118)
- `lib/settings/contact_view.dart` — replace whiteXX usages + chevron icon color
- `test/settings/widgets/settings_brightness_test.dart` (new)

## Approach
- These widgets were recently created/modified by fn-73 and fn-74 — use their settled patterns as migration baseline
- `settings_tile.dart` uses whiteXX for title (`white80`), subtitle (`white40`), and divider (`white20`) — map to `semanticColors.ink`, `semanticColors.inkSubtle`, `semanticColors.borderSubtle`
- `contact_view.dart` chevron uses hardcoded color — switch to `semanticColors.inkSubtle`
- Use shared contrast helper from `test/helpers/contrast_ratio.dart` (Task 3)

## Key context
- All settings files were modified by fn-73/fn-74 (both complete) — migration builds on their settled state
- `settings_support_section.dart` uses `SpotlightCard` with `kitColors.white05` — update call site to use semantic surface

## Acceptance
- [ ] No `whiteXX` usage in `settings_tile.dart` for legibility tokens
- [ ] No `whiteXX` usage in `settings_support_section.dart` for legibility tokens
- [ ] No `whiteXX` usage in `settings_upgrade_banner.dart` for legibility tokens
- [ ] No `whiteXX` usage in `contact_view.dart` for legibility tokens
- [ ] All settings widgets readable in light mode
- [ ] All settings widgets visually unchanged in dark mode
- [ ] Test: settings widgets rendered in both Brightness.light and Brightness.dark
