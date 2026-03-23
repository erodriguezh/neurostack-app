## Description
Bump the splash screen minimum visible time from 500ms to 1000ms and update all references.

**Size:** M
**Files:**
- `lib/startup/startup_view_model.dart` — constant + doc comments
- `test/startup/startup_view_model_test.dart` — tearDown reset, 4 fakeAsync test timings, slow-failure delay
- `test/startup/startup_view_test.dart` — tearDown reset
- `docs/specs/20260322120000_spec_app_launch_handoff.md` — splash-minimum refs
- `plan_app_launch_handoff.md` — splash-minimum refs
- `docs/README.md` — all App Launch Handoff entries describing splash minimum
- `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md` — resolution summary

## Approach

1. **Production code** (`startup_view_model.dart`):
   - Change `minSplashDuration` from `Duration(milliseconds: 500)` to `Duration(milliseconds: 1000)`
   - Update doc comments: remove "aligned with entrance animation duration (500ms)", replace with rationale about entrance + breathing glow
   - Update parenthetical on line 111

2. **Test files**:
   - Both test files: update tearDown reset value from 500 to 1000
   - Four fakeAsync tests: update `minSplashDuration` override from 500 to 1000, adjust `elapse()` calls to reach 1000ms total
   - Slow-failure bootstrap delay: change from 600ms to 1100ms and adjust corresponding elapsed times

3. **Docs** — semantic rule: update references tied to `minSplashDuration`, minimum post-first-paint visibility, and `Future.delayed(...)` gating. Preserve references tied to entrance animation duration.
   - `docs/specs/20260322120000_spec_app_launch_handoff.md`: splash-minimum refs → 1000ms
   - `plan_app_launch_handoff.md`: splash-minimum refs → 1000ms (leave entrance animation "fade + slide, 500ms" untouched)
   - `docs/README.md`: update all App Launch Handoff entries that describe the minimum splash duration (architecture link, spec link, plan link)
   - `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`: append note to resolution that fn-80 increased minimum to 1000ms (historical record, not rewrite)

## Key context

- `testSplashDuration` (10ms) stays unchanged — only used for fast non-timing tests
- Entrance animation is 500ms (`splash_screen.dart:45`) — does NOT change
- Pattern at `startup_view_model.dart:116`: `Future.wait([_bootstrap(), Future.delayed(minSplashDuration)])` — mechanism unchanged
- Two distinct "500ms" concepts in docs: splash minimum (changing) vs entrance animation duration (not changing) — use semantic judgment

## Acceptance
- [ ] `StartupViewModel.minSplashDuration` equals `Duration(milliseconds: 1000)`
- [ ] Doc comment at lines 102-103 no longer claims "aligned with entrance animation"; states new rationale
- [ ] Doc comment at line 111 reflects 1000ms
- [ ] tearDown in `startup_view_model_test.dart` resets to 1000ms
- [ ] tearDown in `startup_view_test.dart` resets to 1000ms
- [ ] All 4 fakeAsync timing tests use 1000ms override and adjusted elapse calls
- [ ] Slow-failure bootstrap delay exceeds 1000ms (e.g. 1100ms)
- [ ] `flutter test test/startup/` passes
- [ ] Spec doc splash-minimum refs updated to 1000ms (entrance animation refs untouched)
- [ ] Plan doc splash-minimum refs updated to 1000ms (entrance animation refs untouched)
- [ ] All `docs/README.md` App Launch Handoff entries describing splash minimum updated to 1000ms
- [ ] Investigation doc resolution updated with fn-80 historical note
- [ ] `flutter analyze` clean

## Done summary
Bumped minSplashDuration from 500ms to 1000ms to allow both the entrance animation and breathing glow to complete before state transitions. Updated doc comments, all 4 fakeAsync timing tests, tearDown resets, slow-failure delay (1100ms), and all spec/plan/README/investigation doc references.
## Evidence
- Commits: 07f8566694f4bcbacc78219833b1585c77350b50
- Tests: flutter test test/startup/, flutter analyze
- PRs: