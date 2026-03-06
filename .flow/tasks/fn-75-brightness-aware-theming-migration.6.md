## Description
Migrate library tab widgets from `kitColors.whiteXX` to semantic tokens, including adaptive-route dialog surfaces and empty state. Library is an adaptive route. `protocol_detail_sheet.dart` is the heaviest migration target in the entire codebase (25+ whiteXX usages).

**Size:** M
**Files:**
- `lib/library/widgets/library_category_header.dart` — replace whiteXX usages
- `lib/library/widgets/library_protocol_card.dart` — replace 15+ whiteXX usages
- `lib/library/widgets/protocol_detail_sheet.dart` — replace 25+ whiteXX usages (heaviest file)
- `lib/library/library_view.dart` — migrate confirm-remove dialog from `kitColors.panel` to semantic surface; migrate `_EmptyState` text colors from `kitColors.white60`/`white40` to semantic ink tokens
- Update existing `test/library/widgets/library_protocol_card_test.dart` for light+dark
- `test/library/widgets/protocol_detail_sheet_brightness_test.dart` (new)

## Approach
- `protocol_detail_sheet.dart` is the highest-risk file — map each whiteXX systematically (borders, fills, text, dividers)
- `library_protocol_card.dart` follows similar patterns to `home_protocol_card.dart` — apply same mapping
- `library_view.dart` has confirm-remove dialog with `kitColors.panel` background and `_EmptyState` with `kitColors.white60`/`white40` text — both must be migrated to semantic tokens
- Bottom sheets opened via `showModalBottomSheet` inherit Navigator theme — since library is an adaptive route, the sheet inherits the correct system theme naturally
- Use the contrast helper from `test/helpers/contrast_ratio.dart` (Task 3) for WCAG assertions
- Update existing test at `library_protocol_card_test.dart:85` which currently only tests dark mode

## Key context
- `protocol_detail_sheet.dart` is opened from `library_view.dart` line ~299 via `showModalBottomSheet` — it inherits the app-level theme
- Existing test at `library_protocol_card_test.dart:85` uses `Brightness.dark` only — add `Brightness.light` variant
- Dialog surfaces and empty state text using `kitColors` are critical light-mode breaks

## Acceptance
- [x] No `whiteXX` usage in `library_protocol_card.dart` for legibility tokens
- [x] No `whiteXX` usage in `protocol_detail_sheet.dart` for legibility tokens
- [x] No `whiteXX` usage in `library_category_header.dart` for legibility tokens
- [x] No `whiteXX` in `library_view.dart` (dialogs + empty state)
- [x] `protocol_detail_sheet.dart` readable in light mode (all text >= 4.5:1 contrast)
- [x] All library widgets visually unchanged in dark mode
- [x] Existing `library_protocol_card_test.dart` updated to test both brightness modes
- [x] New sheet brightness test validates light+dark rendering

## Evidence
- Commits: 56d18a7, 126c85c, 85d8adb, dad76a1, 737918b, 5b19a73, 11fd6e2, fd4eeb64ca056b2e034a12ed62f705cb1cef5826
- Tests: flutter test test/library/
- PRs:
## Done summary
Migrated library widgets (category header, protocol card, protocol detail sheet, library view dialogs/empty state) from kitColors.whiteXX to semantic color tokens. Made evidence/status color helpers brightness-aware, fixed badge icon contrast, destructive button disabled state, and locked card alpha handling.