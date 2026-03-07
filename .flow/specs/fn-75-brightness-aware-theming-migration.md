The app currently mixes brightness-adaptive typography (`ColorScheme`, `textTheme`) with fixed dark-only surfaces (`AppGridBackground`, `KitColorsExtension.whiteXX`). This causes light-mode contrast failures — headers become unreadable on dark backgrounds when the system theme is light.

This epic migrates the app to coherent brightness-aware theming:
- **Adaptive routes** (home/library/progress/settings/contact) follow system brightness
- **Dark-first routes** (auth/onboarding/paywall/offline/splash) stay dark via local scope
- Shared primitives and feature widgets migrate from `whiteXX` tokens to semantic `AppSemanticColors`

### Scope
- 214+ `whiteXX` usages across ~40 files under `lib/`
- Hotspots: `protocol_detail_sheet.dart` (25+), `log_session_view.dart` (26+), `library_protocol_card.dart` (15+), `home_protocol_card.dart` (12+)
- All 4 tab routes, contact view, and modal/sheet/dialog presentations
- Core shared widgets: `app_primary_cta`, `dismiss_button`, `error_state_view`, `home_indicator_pill`, `toast_view`, `home_bottom_nav`
- Adaptive-route dialog surfaces (`kitColors.panel` in `home_view.dart`, `library_view.dart`)
- Global highlight/overlay whites in `app_theme.dart`

## Architecture

### Two Route Policies
```
┌─────────────────────────────────────────────────┐
│ MaterialApp (ThemeMode.system)                  │
│ ┌─────────────────┐  ┌────────────────────────┐ │
│ │ Adaptive Routes │  │ Dark-First Routes      │ │
│ │ (system theme)  │  │ (DarkThemeScope)       │ │
│ │                 │  │                        │ │
│ │ Home            │  │ Auth                   │ │
│ │ Library         │  │ Onboarding             │ │
│ │ Progress        │  │ Offline                │ │
│ │ Settings        │  │ Paywall                │ │
│ │ Contact         │  │ Splash                 │ │
│ │ Log Session*    │  │                        │ │
│ └─────────────────┘  └────────────────────────┘ │
└─────────────────────────────────────────────────┘
* Log session modal inherits caller's theme
```

### Palette Layering
```
┌──────────────────────────────────────────┐
│ AppSemanticColors (ThemeExtension) [NEW] │
│ - Brightness-aware surface/ink/border    │
│ - Grid tokens for AppGridBackground     │
│ - Derived from ColorScheme              │
│ - Path: lib/core/ui/extensions/         │
├──────────────────────────────────────────┤
│ KitColorsExtension (ThemeExtension)     │
│ - Brand colors (brandSky, etc.)         │
│ - whiteXX (dark-first only, legacy)     │
│ - NOT brightness-parameterized          │
├──────────────────────────────────────────┤
│ ColorScheme (Material 3)                │
│ - Brightness-branched (already exists)  │
│ - surface/onSurface/primary/etc.        │
└──────────────────────────────────────────┘
```

### Canonical Names (locked)
- Widget: `DarkThemeScope` in `lib/core/ui/widgets/dark_theme_scope.dart`
- Extension: `AppSemanticColors` in `lib/core/ui/extensions/app_semantic_colors.dart`
- Enum: `AppGridBackgroundMode { legacyDark, adaptive }` (two modes only; no `forceDark`)

### AppGridBackground Modes
- `legacyDark` (default): current behavior, fixed dark palette — no visual change
- `adaptive`: resolves fill/grid/glow from `ColorScheme` (Task 1); updated to use `AppSemanticColors` grid tokens once available (Task 3)

### Key Architectural Decisions

1. **`KitColorsExtension` stays dark-only**: Not brightness-parameterized. `whiteXX` tokens remain for dark-first routes. New adaptive code uses `AppSemanticColors` or `ColorScheme`.

2. **`DarkThemeScope` uses `AppTheme.buildTheme(Brightness.dark)` directly**: No manual extension re-registration needed. Since `buildTheme` returns a complete `ThemeData` with all registered extensions, `DarkThemeScope` automatically includes any new extensions (like `AppSemanticColors` from Task 3) as soon as they are registered in `buildTheme`.

3. **Modal/sheet/dialog theme inheritance**: `showModalBottomSheet`/`showDialog` capture inherited themes at the call site; they won't automatically follow later theme changes. Strategy:
   - Adaptive-route modals/dialogs: read ambient theme naturally (correct by default)
   - Dark-first modals (e.g., `trial_expired_modal`): wrap content in `DarkThemeScope`
   - Adaptive-route dialogs using `kitColors.panel`: migrate to `colorScheme.surfaceContainer` or `semanticColors.surfaceElevated` (covered in Tasks 5 and 6)

4. **Grid lines in light mode**: The real issue is **fill color and line color**, not the radial mask (which uses alpha channel for the fade effect). Adaptive mode uses `ColorScheme.surface` for fill and `ColorScheme.outlineVariant` (or `onSurface` with low alpha) for grid lines.

5. **`log_session_view.dart` is in scope**: 26 `whiteXX` usages, shown as modal from home/library. Gets its own migration task.

6. **Splash stays dark-first**: Uses `GridPattern` + shader (`beam.frag`) directly. Wrap in `DarkThemeScope`.

7. **Global highlight/overlay whites**: `app_theme.dart` has `highlightColor: Colors.white.withValues(alpha: .1)` — must be derived from `colorScheme.onSurface` in Task 3 (when wiring `AppSemanticColors` into `AppTheme`).

## Quick commands
```bash
# Run all tests
flutter test

# Check whiteXX usage count (migration progress metric)
rg "kitColors\.white(90|80|70|60|50|40|30|20|10|05|02)" lib | wc -l

# Analyze for lint errors
flutter analyze

# Update golden files after visual changes
flutter test --update-goldens
```

## Migration Phases

### Phase 1: Infrastructure (Tasks 1-3)
Build the foundation without changing any existing visuals.
- Task 1: Policy docs + AppGridBackground adaptive mode (uses `ColorScheme` initially)
- Task 2: DarkThemeScope + dark-first route containment (uses `AppTheme.buildTheme(Brightness.dark)` — automatic extension inclusion)
- Task 3: AppSemanticColors ThemeExtension (also updates `AppGridBackground` to use semantic grid tokens, fixes global highlight/overlay whites in `app_theme.dart`)

Tasks 1 and 2 can run in parallel. Task 3 depends on Task 1.

**Checkpoint**: Dark-first routes insulated. Semantic tokens available. Zero visual changes on adaptive routes.

### Phase 2: Core Migration (Tasks 4-5)
Migrate shared primitives and home widgets.
- Task 4: Core shared widget migration
- Task 5: Home widgets + home-route dialog migration

**Checkpoint**: Shared primitives brightness-safe. Home tab adaptive.

### Phase 3: Feature Migration (Tasks 6-9)
Migrate remaining feature domains. Tasks 5-9 are parallelizable **after Task 3 lands**. All share the contrast helper from Task 3 — no duplicate implementations.
- Task 6: Library widgets + library-route dialog migration
- Task 7: Progress widgets migration
- Task 8: Settings + contact migration
- Task 9: Session/modal migration

Testing approach for tasks 5-9: use the `contrastRatio` helper from `test/helpers/contrast_ratio.dart` (created in Task 3) for WCAG assertions; use `AppTheme.buildTheme(brightness)` parameterized widget tests (not golden tests) for each widget.

**Checkpoint**: All adaptive-route widgets brightness-safe in isolation.

### Phase 4: Activation + Enforcement (Tasks 10-11)
Flip the switch and lock it down.
- Task 10: Flip adaptive routes to adaptive background
- Task 11: Enforcement, cleanup, docs

**Checkpoint**: Light mode fully functional. CI guard active.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Grid lines invisible in light mode | High | Medium | Task 1 uses `ColorScheme.outlineVariant`/`onSurface` for adaptive line color; test validates visibility |
| Adaptive-route dialogs unreadable in light mode | High | High | Tasks 5+6 explicitly migrate `kitColors.panel` dialog backgrounds |
| Modal sheets inherit wrong theme | High | Medium | Task 2 documents strategy; task 9 applies it to session modals |
| `DarkThemeScope` missing extensions | Low | High (crash) | Uses `AppTheme.buildTheme(Brightness.dark)` — all extensions automatically included |
| Global highlight whites look wrong on light surfaces | Medium | Medium | Task 3 derives from `colorScheme.onSurface` instead of `Colors.white` |
| Golden test platform divergence | Medium | Low | Pin `devicePixelRatio = 1.0`, use Ahem font in test theme |
| Partial migration leaves inconsistent UI | Medium | Medium | Each task is self-contained; rollback = revert single PR |
| `protocol_detail_sheet.dart` regression (25+ changes) | Medium | High | Dedicated coverage in task 6; light+dark contrast assertions |

## Rollout & Rollback

- Each task maps to one PR, independently revertable
- Default `legacyDark` mode means no visual change until task 10 flips routes
- Task 10 rollback: revert route opt-ins back to `legacyDark`, keep all infrastructure
- Emergency: revert task 10 only; all other tasks remain safe

## Alternatives Considered

1. **Brightness-parameterize `KitColorsExtension`**: Rejected — would require touching all 214 call sites at once. Incremental migration via new `AppSemanticColors` is safer.
2. **`ColorScheme.fromSeed` for everything**: Rejected — brand colors need exact hex values. Use `fromSeed` base with `copyWith` for critical brand slots.
3. **Single big-bang PR**: Rejected — too risky, untestable, unreviewable.
4. **Three background modes (legacyDark/adaptive/forceDark)**: Rejected — `DarkThemeScope` handles the force-dark case at the theme level, so background only needs two modes.

## Acceptance

- [ ] Light mode: titles/text/icons on adaptive routes clearly readable
- [ ] Dark mode: no regressions from current visuals
- [ ] Adaptive routes use `AppSemanticColors`, not `kitColors.whiteXX` for legibility
- [ ] Adaptive-route dialogs use semantic surfaces (no `kitColors.panel`)
- [ ] Dark-first routes visually identical under both system themes
- [ ] `whiteXX` usage on adaptive surfaces reduced to near-zero
- [ ] CI lint guard blocks new `whiteXX` in adaptive areas (with allowlist for dark-first widgets)
- [ ] Light+dark contrast tests for all tab routes
- [ ] Investigation docs closed out with resolution notes

## References

- Investigation: `docs/investigations/20260304133000_investigation_brightness_aware_theming_plan.md`
- Symptom diagnosis: `docs/investigations/20260304120000_investigation_invisible_screen_titles.md`
- Design tokens doc: `docs/best_practices/design/visual-design.md`
- Theme builder: `lib/core/ui/app_theme.dart`
- Color constants: `lib/core/ui/constants/kit_colors.dart`
- Background widget: `lib/core/ui/widgets/app_grid_background.dart`
- Flutter ThemeExtension API: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- WCAG contrast ratio: https://www.w3.org/WAI/GL/wiki/Contrast_ratio


