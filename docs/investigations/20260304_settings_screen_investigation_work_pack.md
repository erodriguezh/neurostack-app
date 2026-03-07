# Investigation: Settings Screen Visual + Branch Commit Audit

## Summary
The Settings screen implementation on `feature/settings-screen` is largely aligned with the design and screenshot state (non-premium: upgrade banner + Contact Us tile). The main remaining gaps are animation-contract mismatch, missing UI-level regression tests, and missing in-repo screenshot artifact reference.

## Symptoms
- Attached screenshot shows dark grid background, Settings header, upgrade banner, Contact Us tile, and Settings tab active.
- Request was to investigate branch commits and produce a concrete work pack.

## Investigation Log

### Phase 1 - Initial assessment
**Hypothesis:** Core wiring exists; remaining issues are subtle parity or regression-related.
**Findings:** Branch history shows recent concentrated fixes in settings UI/interaction and docs.
**Evidence:**
- Branch: `feature/settings-screen`
- Recent settings commits include `ef05356`, `1084d6b`, `09a2a6c`, `c48e436`.
**Conclusion:** Likely stabilization phase, not greenfield implementation.

### Phase 2 - Broad context gathering (context_builder + oracle)
**Hypothesis:** Implementation probably matches behavior, with potential design drift and test gaps.
**Findings:** Oracle highlighted likely motion mismatch and missing widget coverage; flagged screenshot reference risk.
**Evidence:** Context builder selected 49 files across settings UI, premium pipeline, routes, tests, spec/plan/docs.
**Conclusion:** Proceed to line-level verification + commit timeline audit.

### Phase 3 - Agent verification (code + docs + tests)
**Hypothesis:** Premium gating and navigation are correctly wired.
**Findings:** Confirmed.
**Evidence:**
- Conditional rendering:
  - `lib/settings/settings_view.dart:85` `ValueListenableBuilder<bool>`
  - `lib/settings/settings_view.dart:91` `if (!isPremium)` banner
  - `lib/settings/settings_view.dart:101` stagger index shifts with premium state
- Banner details:
  - min height: `lib/settings/widgets/settings_upgrade_banner.dart:55`
  - border sky/30: `.../settings_upgrade_banner.dart:62`
  - press scale 150ms: `.../settings_upgrade_banner.dart:51-53`
  - crown/chevron: `.../settings_upgrade_banner.dart:79,116`
- Support section details:
  - Cancel Subscription premium-only: `lib/settings/widgets/settings_support_section.dart:47,50`
  - header style RobotoMono: `.../settings_support_section.dart:70`
  - divider white05: `.../settings_support_section.dart:94-97`
- Tile behavior:
  - press overlay + 150ms: `lib/settings/widgets/settings_tile.dart:53,57`
  - min height/padding: `.../settings_tile.dart:59-60`
- Navigation:
  - paywall: `lib/settings/settings_view_model.dart:89-90`
  - contact: `lib/settings/settings_view_model.dart:94-95`
  - cancel subscription URLs: `lib/settings/settings_view_model.dart:106-108`
- Premium state source:
  - notifier/mixin pipeline: `lib/core/abstractions/premium_aware_view_model_mixin.dart:74,86,110,156,166,170`
  - premium semantics: `lib/features/user/domain/enums/subscription_status.dart:44`
- Routes present:
  - `lib/config/route_config.dart:32,37,42`
**Conclusion:** Functional requirements are wired correctly.

### Phase 4 - Divergence + commit history validation
**Hypothesis:** Remaining gaps are mostly parity/test/docs integrity.
**Findings:** Confirmed.
**Evidence:**
- Animation mismatch vs prompt:
  - Prompt wants 400ms + translateY(8→0): `docs/best_practices/design/screen-prompts/11-settings-screen.md:42-43`
  - Current uses 500ms + fractional `Offset(0, 0.05)`: `lib/core/ui/widgets/staggered_fade_in.dart:37,41-42`
- Screenshot artifact reference mismatch:
  - Referenced in spec/plan:
    - `docs/specs/20260227120000_spec_settings_screen.md:133`
    - `plan_settings_screen.md:5`
  - Actual folder content: only `docs/design_screenshots/trial-expiration-modal.png`
- Tests gap (UI layer):
  - only file under `test/settings`: `test/settings/settings_view_model_test.dart`
  - no settings widget tests

**Commit evidence (branch progression):**
- `3574d08` initial settings screen
- `0afebba` subscription-aware settings VM + tab coordination
- `6daca1a` VM correctness fixes + contact route + tests
- `e0bcc9e` extracted `PremiumAwareViewModelMixin`
- `a2bb688` added upgrade banner
- `0ab009c` Material/InkWell interaction + support/tile wiring
- `ef05356` removed stub tiles + merged duplicate premium builders
- `1084d6b` fixed banner Ink layering/clipping
- `09a2a6c` added `ValueKey`s to prevent conditional widget reuse issues
- `c48e436` shared HomeIndicatorPill + canonical h1 letter spacing
- `adedaad`, `1123d23` docs cleanup/alignment

**Conclusion:** Branch resolved major structural/interaction issues; residual risk is motion parity + regression-proofing + missing design artifact.

## Root Cause
No single functional bug remains evident in settings wiring. Current gaps are due to:
1. **Spec-to-implementation motion drift** (`400ms + 8px` spec vs `500ms + fractional offset` shared widget).
2. **Verification gap** (no widget/golden tests for settings UI conditions/interactions).
3. **Documentation/source-of-truth gap** (referenced screenshot file missing in repo).

## Eliminated Hypotheses
- **“Banner visibility logic is broken”** → Eliminated (conditional + premium pipeline verified in code).
- **“Navigation to paywall/contact missing”** → Eliminated (`SettingsViewModel` routes verified).
- **“Support section still has old stub tiles”** → Eliminated (removed in `ef05356`; current section has real 2-tile model).

## Work Pack (Prioritized)

### P0 - Immediate verification (docs/process first)
1. **Restore canonical screenshot reference** (Docs/process)
   - Add `docs/design_screenshots/11-settings.png` or update spec/plan references to actual canonical asset.
2. **Capture current baseline screenshots** (Process)
   - Produce free + premium state captures on defined device/theme for side-by-side validation.
3. **Token/value spot-check** (Code review process)
   - Confirm spacing/token values used in settings match prompt targets.

### P1 - Hardening (code + tests)
1. **Add widget tests for settings conditional UI** (Code/tests)
   - Free: banner visible, cancel hidden.
   - Premium: banner hidden, cancel visible.
   - Contact always visible.
2. **Add widget-level interaction tests** (Code/tests)
   - Banner tap → paywall navigation path.
   - Contact tap → `/settings/contact`.
3. **Add regression test for premium-state flips** (Code/tests)
   - Protect against conditional insertion/reuse issue addressed by `09a2a6c`.
4. **Align docs wording for section header font** (Docs)
   - Resolve spec wording (`Inter mono`) vs prompt/code (`Roboto Mono`).

### P2 - Optional polish (code)
1. **Motion parity decision**
   - Either align `StaggeredFadeIn` to 400ms + 8px, or create a settings-specific animation to avoid global side effects.
2. **Evaluate icon stroke-width strictness**
   - If strict 1.5 stroke is required, consider SVG/vector approach (IconData defaults are not stroke-configurable).

## Preventive Measures
- Add a lightweight UI parity checklist (prompt values + screenshot path validity) to completion criteria before marking settings tasks SHIP.
- Require at least one widget test for any premium-gated screen.
- Keep a canonical design screenshot in-repo for each screen prompt referenced by spec/plan.
