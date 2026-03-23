# Increment splash screen min visible time to 1s

## Overview
Raise the minimum splash screen display time from 500ms to 1000ms so users see the full entrance animation (500ms) plus a brief breathing glow (~500ms) before transitioning.

## Scope
- Change `minSplashDuration` constant from 500ms to 1000ms
- Update doc comments: remove "aligned with entrance animation" claim, add new rationale (entrance + breathing glow)
- Fix all test timing: tearDown resets, fakeAsync elapsed times, slow-failure bootstrap delay (must exceed 1000ms)
- Update spec, plan, README, and investigation docs that reference the splash minimum as 500ms

## Out of scope
- Entrance animation duration stays at 500ms (`splash_screen.dart:45` comment, `screen-prompts/00-splash-screen.md:17` — leave untouched)
- `plan_app_launch_handoff.md:375` "fade + slide, 500ms" refers to entrance animation — leave untouched
- `testSplashDuration` (10ms override in tests) — stays at 10ms for fast non-timing tests

## Doc update rule
Update references tied to `minSplashDuration`, minimum post-first-paint visibility, and `Future.delayed(...)` gating. Preserve references tied to the splash entrance animation duration in `splash_screen.dart` and design prompt docs. Use semantic judgment, not line numbers — the intent distinguishes the two "500ms" concepts.

## Key decisions
- **Slow-failure test delay**: Change from 600ms to 1100ms (maintains ~100ms margin above splash)
- **fakeAsync intermediate checks**: Keep 200ms first checkpoint (still proves no early transition), adjust second elapse to reach 1000ms total
- **Doc comment rationale**: "Ensures the entrance animation (500ms) completes and the breathing glow is briefly visible before any state transition"
- **Investigation doc**: Update `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md` resolution summary to note fn-80 increased the minimum to 1000ms (append historical note, not rewrite)

## Quick commands
```bash
flutter test test/startup/
flutter analyze
```

## Acceptance
- [ ] `StartupViewModel.minSplashDuration` equals `Duration(milliseconds: 1000)`
- [ ] Doc comments on lines 102-103 and 111 reflect 1000ms with updated rationale
- [ ] All tests in `test/startup/` pass with updated timing
- [ ] "Slow failure" test uses bootstrap delay > 1000ms (e.g. 1100ms)
- [ ] Spec doc (`docs/specs/20260322120000_spec_app_launch_handoff.md`) updated: splash-minimum refs changed to 1000ms (entrance animation refs untouched)
- [ ] Plan doc (`plan_app_launch_handoff.md`) updated: splash-minimum refs changed to 1000ms (entrance animation refs untouched)
- [ ] `docs/README.md` summary phrases describing splash minimum updated to 1000ms
- [ ] `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md` resolution updated with fn-80 note
- [ ] `flutter analyze` clean
- [ ] `flutter test test/startup/` passes

## References
- Constant: `lib/startup/startup_view_model.dart:105`
- Tests: `test/startup/startup_view_model_test.dart`, `test/startup/startup_view_test.dart`
- Spec: `docs/specs/20260322120000_spec_app_launch_handoff.md`
- Plan: `plan_app_launch_handoff.md`
- README: `docs/README.md`
- Investigation: `docs/investigations/20260321174500_investigation_empty_white_startup_screen.md`
- Related epic: fn-79 (established the 500ms value)
