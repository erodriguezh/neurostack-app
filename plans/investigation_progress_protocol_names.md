# Investigation: Progress Protocol Names Missing

## Summary
Protocol names are present in state but rendered in a `SizedBox(width: nameWidth)` that collapses to `0` when the grid is constrained under ~300px. With the Progress screen’s outer padding and the grid’s inner padding, common small-device widths can drop below this threshold, making names invisible even though data is loaded.

## Symptoms
- Progress screen grid renders day headers and cells, but the protocol name column is blank.

## Investigation Log

### Phase 1 - Initial Assessment
**Hypothesis:** Protocol names are not loaded or mapped into the Progress grid rows.
**Findings:** `ProgressViewModel` loads protocol names via `ProtocolRepository.getById` and assigns `protocol.name.value`, falling back to `'Protocol unavailable'` on error. This should never yield a blank string under normal domain validation.
**Evidence:** `lib/progress/progress_view_model.dart:280-285`.
**Conclusion:** Data-loading failure is unlikely; names should be non-empty or show the fallback string.

### Phase 2 - Context Builder & Model Trace
**Hypothesis:** The blank name column is a layout issue rather than data.
**Findings:** `ProgressGrid` computes `nameWidth` based on `maxWidth - (minCellSize * 7 + preferredGap * 6)`. If `maxWidth` is below ~300px, `nameWidth` collapses to `0`, and the name `Text` is wrapped in `SizedBox(width: nameWidth)` so it becomes invisible.
**Evidence:** `lib/progress/widgets/progress_grid.dart:43-75` and `lib/progress/widgets/progress_grid.dart:182-189`.
**Conclusion:** Layout collapse is a viable root cause.

### Phase 3 - Layout Constraint Analysis
**Hypothesis:** Progress screen padding reduces available width enough to collapse `nameWidth` on small screens.
**Findings:** `ProgressView` wraps `ProgressGrid` in `SliverPadding` with `spacing.lg` (24) on both sides, and `ProgressGrid` adds inner padding of `spacing.lg` (24). Total horizontal reduction is ~96px. On a 320px device, internal `maxWidth` becomes ~224px, which is below the 300px minimum for `minCellSize=36` + 6 gaps (8). This forces `nameWidth` to 0.
**Evidence:** `lib/progress/progress_view.dart:227-231`, `lib/progress/widgets/progress_grid.dart:40-64`, `lib/core/ui/constants/spacing.dart:12-20`.
**Conclusion:** Highly likely root cause for the screenshot.

### Phase 4 - Data Integrity Elimination
**Hypothesis:** Protocol names are empty due to DTO/domain reconstitution.
**Findings:** `ProtocolDto.toDomain()` uses `ProtocolName.create(name)` which rejects empty strings. If validation fails, the repository would return a failure and the view model sets `'Protocol unavailable'` rather than blank. The cache layer will accept empty names if they ever enter `protocolNamesById`, but there is no evidence of that in the current online path.
**Evidence:** `lib/features/protocol/data/dtos/protocol_dto.dart:45-90`, `lib/features/protocol/domain/value_objects/protocol_name.dart:33-61`, `lib/progress/progress_view_model.dart:280-285`.
**Conclusion:** Empty protocol names in state are unlikely.

### Phase 5 - Git History Check
**Hypothesis:** Recent changes to Progress grid layout introduced the regression.
**Findings:** Recent commits include `progress screen 1` and `progress-screen 3`, which likely introduced layout math in `ProgressGrid`.
**Evidence:** `git log -n 5 -- lib/progress/widgets/progress_grid.dart`.
**Conclusion:** Regression likely introduced during recent progress screen implementation.

## Root Cause
The protocol names are rendered inside a fixed-width column whose computed width collapses to zero on narrow constraints. `ProgressGrid` enforces a minimum layout of 7 day cells at `minCellSize=36` plus 6 gaps at `preferredGap=8` (total 300px). After outer and inner padding (96px), common small-device widths (e.g., 320px) fall below this threshold, so `nameWidth` becomes `0` and the name text is invisible despite being present in state.

## Recommendations
1. Adjust `ProgressGrid` layout to preserve a non-zero name column on narrow widths (e.g., allow `cellSize` to shrink below 36 or reduce gap and name width first).
2. Consider horizontal scrolling for the grid area if minimum cell size must be preserved.
3. Add a layout regression test that asserts the name column remains visible at narrow widths (in addition to the existing no-overflow test).

## Remediation Applied
- Implemented horizontal scrolling within the grid card to preserve minimum cell sizes and keep the name column visible when constrained widths are below the 300px minimum. See `lib/progress/widgets/progress_grid.dart`.

## Preventive Measures
- Add a widget test that asserts `ProgressGrid` renders protocol name text under a constrained width.
- Log computed layout widths in debug builds when `nameWidth` drops below a threshold.
- Keep `ProgressGrid` layout math in a pure helper function so it can be unit tested for edge cases.
