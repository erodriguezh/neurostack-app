## Description
Add CI enforcement against new `whiteXX` usage in adaptive areas, update design docs (including fixing stale file structure references), and close out investigation documents.

**Size:** M
**Files:**
- `lib/core/ui/constants/kit_colors.dart` — add deprecation annotations/comments on whiteXX tokens for adaptive usage
- `docs/best_practices/design/brightness_theming.md` — finalize with migration results
- `docs/best_practices/design/visual-design.md` — add AppSemanticColors to Token Hierarchy, update PR checklist, add Surface Mode Policy subsection, fix File Structure section to match actual repo layout (`kit_colors.dart`, `app_theme.dart`, `extensions/`)
- `docs/README.md` — add DarkThemeScope + AppSemanticColors to widget/token registry
- `docs/best_practices/design/screen-prompts/02-home-and-stack-screen.md` — add note about semantic token mapping
- `docs/best_practices/design/screen-prompts/03-library-screen.md` — add note
- `docs/best_practices/design/screen-prompts/04-progress-screen.md` — add note
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` — add note
- `docs/investigations/20260304133000_investigation_brightness_aware_theming_plan.md` — add Resolution section
- `docs/investigations/20260304120000_investigation_invisible_screen_titles.md` — add resolution note
- CI config or script for whiteXX grep guard

## Approach
- CI guard: shell script that greps for `kitColors.white` in adaptive areas only:
  - Blocked paths: `lib/home/`, `lib/library/`, `lib/progress/`, `lib/settings/`, and adaptive core widgets in `lib/core/ui/widgets/` (exclude `dark_theme_scope.dart`)
  - Allowed paths (dark-first): `lib/features/auth/`, `lib/features/onboarding/`, `lib/features/offline/`, `lib/paywall/`, `lib/startup/`
  - Document the allowlist/denylist in the script and in `brightness_theming.md`
- `visual-design.md`: fix the File Structure section which references paths that don't exist (`app_colors.dart`, `theme/`) — update to match actual layout (`kit_colors.dart`, `app_theme.dart`, `lib/core/ui/extensions/app_semantic_colors.dart`, `lib/core/ui/widgets/dark_theme_scope.dart`)
- Screen prompt docs: add header note clarifying `white/XX` values map to `AppSemanticColors` tokens post-migration
- Investigation close-outs: append `## Resolution` section with link to this epic and `brightness_theming.md`
- Widget registry format: `**WidgetName** - \`path\` - descriptor, keywords`

## Key context
- `visual-design.md` uses fenced dart blocks with "correct vs wrong" comment pairs — follow that format
- Investigation docs use 4-phase structure — add `## Resolution` as final section
- A naive grep blocking all `whiteXX` would break legitimate dark-first usage — the guard must be path-scoped
- `visual-design.md` File Structure section is materially out of sync with the real repo — this must be fixed alongside adding new entries

## Acceptance
- [ ] CI guard blocks new `whiteXX` usage in adaptive paths (`lib/home/`, `lib/library/`, `lib/progress/`, `lib/settings/`, adaptive core widgets)
- [ ] CI guard allows `whiteXX` in dark-first paths (`lib/features/auth/`, `lib/features/onboarding/`, `lib/features/offline/`, `lib/paywall/`, `lib/startup/`)
- [ ] Allowlist/denylist documented in guard script and `brightness_theming.md`
- [ ] `visual-design.md` documents AppSemanticColors in Token Hierarchy and PR checklist
- [ ] `visual-design.md` has Surface Mode Policy subsection (adaptive vs dark-first)
- [ ] `visual-design.md` File Structure section matches actual repo layout
- [ ] `docs/README.md` has DarkThemeScope and AppSemanticColors registry entries
- [ ] Screen prompt docs (02, 03, 04, 11) have semantic token mapping note
- [ ] Investigation `20260304133000` has Resolution section
- [ ] Investigation `20260304120000` has resolution note linking to policy doc
- [ ] `brightness_theming.md` finalized with migration results and token reference
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
