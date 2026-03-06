## Description
Migrate progress tab widgets from `kitColors.whiteXX` to semantic tokens, including the progress route shell. Progress is an adaptive route.

**Size:** M
**Files:**
- `lib/progress/progress_view.dart` — replace `kitColors.white40` subtitle color and any other whiteXX usages
- `lib/progress/widgets/progress_grid.dart` — replace 6 whiteXX usages
- `lib/progress/widgets/progress_day_cell.dart` — replace 4 whiteXX usages
- `lib/progress/widgets/backdate_session_sheet.dart` — replace whiteXX usages
- Update `test/progress/widgets/progress_grid_test.dart` for light+dark (currently dark-only at line 47)
- `test/progress/widgets/progress_brightness_test.dart` (new) — day cell + sheet + view tests

## Approach
- `progress_view.dart` has `context.kitColors.white40` for subtitle color — must be migrated or it will be low-contrast after Task 10 flips the background
- `progress_grid.dart` and `progress_day_cell.dart` are simpler migrations (fewer usages) — follow same mapping pattern from tasks 4-6
- `backdate_session_sheet.dart` is shown via `showModalBottomSheet` — inherits Navigator theme, which is correct for adaptive routes
- Update existing dark-only test at `progress_grid_test.dart:47` to parameterize both brightness modes
- Use shared contrast helper from `test/helpers/contrast_ratio.dart` (Task 3)

## Key context
- `progress_day_cell.dart` uses whiteXX for cell borders and fill states — map to `semanticColors.border`/`semanticColors.surface`
- `progress_view.dart` subtitle is a critical light-mode break if not migrated

## Acceptance
- [x] No `whiteXX` usage in `progress_view.dart` for legibility tokens
- [x] No `whiteXX` usage in `progress_grid.dart` for legibility tokens
- [x] No `whiteXX` usage in `progress_day_cell.dart` for legibility tokens
- [x] No `whiteXX` usage in `backdate_session_sheet.dart` for legibility tokens
- [x] All progress widgets visually unchanged in dark mode
- [x] Existing `progress_grid_test.dart` updated to test both brightness modes
- [x] New brightness test covers day cell, sheet, and view in light+dark

## Done summary
Migrated progress widgets from kitColors.whiteXX/panel to semantic tokens. Added brightness tests with WCAG contrast assertions.

## Evidence
- Commits: 2e0842f, dff8355, 37d2ee0, 645cbb5, db09d4f
- Tests: `flutter test test/progress/` (45 pass), `flutter analyze` (0 issues)
