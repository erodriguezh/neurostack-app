# fn-78-send-feedback-mailto-via-url-launcher.6 Clean up stale Wiredash references in code and docs

## Description
Remove all stale Wiredash references from code doc comments and documentation files. Update the settings spec to correct the encoding function reference.

**Size:** S
**Files:**
- `lib/settings/widgets/settings_support_section.dart` (remove stale doc comments)
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` (update Send Feedback from Wiredash placeholder to mailto)
- `docs/specs/20260315140000_spec_userorient_integration.md` (remove stale out-of-scope Wiredash reference)
- `docs/specs/202603162012_spec_rate_app_integration.md` (remove stale out-of-scope Wiredash reference)
- `docs/specs/20260227120000_spec_settings_screen.md` (fix `Uri.encodeFull` → `Uri.encodeComponent` at line ~107)

## Approach

### Code cleanup (`settings_support_section.dart`)
- Remove/update all 3 stale doc comments:
  - L31: `/// Placeholder action for Send Feedback (TODO: Wiredash).` → update to reflect mailto behavior
  - L34: `/// Placeholder action for Rate the App (TODO: App Store).` → update to reflect in-app review behavior (already implemented)
  - L37: `/// Placeholder action for Feature Request (TODO: Wiredash).` → update to reflect UserOrient behavior (already implemented)

### Screen prompt (`11-settings-screen.md`)
- L43: Replace `Placeholder (no-op, pending Wiredash)` with description of mailto behavior in the tile table
- Follow existing table format: `| Label | Icon | Trailing | Visibility | Action |`

### Out-of-scope sections
- `20260315140000_spec_userorient_integration.md:147`: Remove bullet about "Send Feedback pending Wiredash"
- `202603162012_spec_rate_app_integration.md:277`: Remove bullet about "Send Feedback pending Wiredash"

### Settings spec encoding fix
- `20260227120000_spec_settings_screen.md:~107`: Change `Uri.encodeFull` → `Uri.encodeComponent` to match actual implementation

## Key context
- The screen prompt file (`11-settings-screen.md`) is used as input for AI-assisted UI generation — stale data causes regressions in future screen regeneration
- Remove entire "pending Wiredash" bullets from out-of-scope sections rather than leaving tombstones
## Acceptance
- [ ] No remaining "Wiredash" references in `settings_support_section.dart` doc comments
- [ ] All 3 callback doc comments in `settings_support_section.dart` reflect current behavior
- [ ] `11-settings-screen.md` tile table shows mailto action for Send Feedback
- [ ] UserOrient spec out-of-scope no longer mentions "Send Feedback pending Wiredash"
- [ ] Rate App spec out-of-scope no longer mentions "Send Feedback pending Wiredash"
- [ ] Settings spec references `Uri.encodeComponent` (not `Uri.encodeFull`)
- [ ] `flutter analyze` clean
## Done summary
Duplicate — use task .1 instead
## Evidence
- Commits:
- Tests:
- PRs: