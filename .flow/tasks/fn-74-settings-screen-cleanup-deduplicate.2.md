# fn-74-settings-screen-cleanup-deduplicate.2 Extract shared tab-screen widgets: home indicator pill and header text style

## Description
Extract two patterns that are copy-pasted across all 4 tab screens into shared widgets/constants. These were propagated during settings screen implementation.

**Size:** M
**Files:**
- `lib/core/ui/widgets/home_indicator_pill.dart` (new)
- `lib/core/ui/constants/text_styles.dart` (edit — update `h1.letterSpacing` to `-0.8`)
- `lib/settings/settings_view.dart`
- `lib/settings/contact_view.dart`
- `lib/home/home_view.dart`
- `lib/home/widgets/home_header.dart`
- `lib/library/library_view.dart`
- `lib/progress/progress_view.dart`

## Approach

### 1. Extract home indicator pill widget

The identical ~15-line `Positioned` + `Container` widget appears in all 4 tab screens:
- `lib/settings/settings_view.dart:139-153`
<!-- Updated by plan-sync: fn-74.1 merged duplicate ValueListenableBuilder blocks, shifting pill lines from 144-158 to 139-153 -->
- `lib/home/home_view.dart:116-132`
- `lib/library/library_view.dart:114-130`
- `lib/progress/progress_view.dart:125-141`

Create `lib/core/ui/widgets/home_indicator_pill.dart`:
- Follow extraction pattern from fn-60.3 (`StaggeredFadeIn`, `ErrorStateView`)
- `StatelessWidget` taking `bottomInset` as parameter (computed from `MediaQuery.of(context).padding.bottom` by caller)
- Return the `Positioned` + `Center` + `Container` structure with `kitColors.white90.withValues(alpha: 0.3)`, width 134, height 5, borderRadius 999
- Replace inline code in all 4 tab screens with the new widget
- Stage changes: update Home/Library/Progress first, then rebase and update Settings last to minimize conflict risk

### 2. Consolidate screen header text style

The identical `headlineLarge?.copyWith(fontSize: 32, fontStyle: FontStyle.italic, letterSpacing: -0.8, color: kitColors.white90)` appears in 4+ places. The decision (per epic) is: **`-0.8` is canonical**.

Rather than creating a new `screenTitle` token (which would bake colors into `CustomTextStyles`, bypassing the `TextTheme` pipeline in `app_theme.dart`):

1. Update `CustomTextStyles.h1.letterSpacing` from `-0.5` to `-0.8` at `lib/core/ui/constants/text_styles.dart:55`
2. Replace all inline `headlineLarge?.copyWith(fontSize: 32, fontStyle: FontStyle.italic, letterSpacing: -0.8, color: kitColors.white90)` with direct `Theme.of(context).textTheme.headlineLarge` usage (color/font already applied via `TextTheme` in `app_theme.dart`)
3. Affected files: `settings_view.dart`, `contact_view.dart`, `library_view.dart`, `progress_view.dart`
4. Update `home_header.dart` to use `letterSpacing: textStyles.h1.letterSpacing` (or drop the override entirely) so it picks up the new `-0.8` value instead of hardcoding `-0.5` — otherwise it becomes an inconsistent one-off after the token change

## Key context

- Shared widget precedent: `lib/core/ui/widgets/staggered_fade_in.dart` and `lib/core/ui/widgets/error_state_view.dart` were extracted in fn-60.3 using the same pattern
- Theme pipeline: `lib/core/ui/app_theme.dart` applies `GoogleFonts.newsreader(color: ...)` onto the `TextTheme`; `CustomTextStyles` provides structure-only tokens (fontSize, fontStyle, letterSpacing, fontWeight)
- All 4 pill implementations are byte-identical except for import context

## Acceptance
- [ ] `HomeIndicatorPill` widget exists at `lib/core/ui/widgets/home_indicator_pill.dart`
- [ ] All 4 tab screens (`settings_view.dart`, `home_view.dart`, `library_view.dart`, `progress_view.dart`) use `HomeIndicatorPill` instead of inline code
- [ ] No inline `Positioned` + `Container` pill code remains in any tab screen
- [ ] `CustomTextStyles.h1.letterSpacing == -0.8`
- [ ] No inline `headlineLarge?.copyWith(fontSize: 32, fontStyle: FontStyle.italic, letterSpacing: -0.8, ...)` remains in tab title headers
- [ ] All 4 header usages (settings, contact, library, progress) use `headlineLarge` from theme directly
- [ ] `home_header.dart` uses the `h1` token's letterSpacing (no hardcoded `-0.5`)
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (all existing tests green)
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
