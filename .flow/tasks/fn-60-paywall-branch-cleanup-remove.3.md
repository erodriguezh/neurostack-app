# fn-60-paywall-branch-cleanup-remove.3 Extract shared ErrorState and StaggeredFadeIn widgets

## Description
Extract duplicate private widgets into shared public widgets in `lib/core/ui/widgets/`.

**Size:** M
**Files:**
- `lib/home/home_view.dart` (remove `_ErrorState` at L447-476, `_StaggeredFadeIn` at L484-515)
- `lib/library/library_view.dart` (remove `_ErrorState` at L411-440, `_StaggeredFadeIn` at L448-479)
- `lib/progress/progress_view.dart` (remove `_ErrorState` at L341-370)
- `lib/core/ui/widgets/error_state_view.dart` (NEW)
- `lib/core/ui/widgets/staggered_fade_in.dart` (NEW)

## What to extract

### `_ErrorState` → `ErrorStateView` (from 3 views)
All three views have an identical `StatelessWidget` with:
- message text
- "Pull to refresh to retry." subtitle
- Centered column layout

Extract to `lib/core/ui/widgets/error_state_view.dart` with a `message` parameter.

### `_StaggeredFadeIn` → `StaggeredFadeIn` (from 2 views)
Home and Library have an identical `StatefulWidget` with:
- `delay` parameter (Duration)
- `child` parameter
- `initState` starts a delayed opacity animation
- `AnimatedOpacity` in build

Extract to `lib/core/ui/widgets/staggered_fade_in.dart` with `delay` and `child` parameters.

## Approach

- Follow existing pattern at `lib/core/ui/widgets/dismiss_button.dart` for widget extraction conventions
- Use `const` constructors where possible
- Keep the same visual behavior — no design changes
- Update imports in all 3 view files
- No test changes needed unless widget tests reference the private types by name

## Key context

- ProgressView does NOT use `_StaggeredFadeIn` — only Home + Library
- The name `ErrorStateView` avoids conflict with `ErrorState` which could collide with state management concepts
## Acceptance
- [ ] `ErrorStateView` widget created at `lib/core/ui/widgets/error_state_view.dart`
- [ ] `StaggeredFadeIn` widget created at `lib/core/ui/widgets/staggered_fade_in.dart`
- [ ] Private `_ErrorState` removed from `home_view.dart`, `library_view.dart`, `progress_view.dart`
- [ ] Private `_StaggeredFadeIn` removed from `home_view.dart`, `library_view.dart`
- [ ] All 3 views import and use the shared widgets
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (no regressions)
## Done summary
Extracted duplicate _ErrorState and _StaggeredFadeIn private widgets from home_view.dart, library_view.dart, and progress_view.dart into shared ErrorStateView and StaggeredFadeIn widgets in lib/core/ui/widgets/, removing 101 lines of duplicated code.
## Evidence
- Commits: 9b0a99a8a92296f1362fb82e31e97efb90091fee
- Tests: flutter analyze, flutter test test/home/ test/library/ test/progress/
- PRs: