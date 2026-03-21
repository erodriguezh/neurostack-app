# fn-78-send-feedback-mailto-via-url-launcher.3 Clean up stale Wiredash references in code and docs

## Description
Remove all stale Wiredash references from code doc comments and documentation files. Update the settings spec to correct the encoding function reference.

**Size:** S
**Files:**
- `lib/settings/widgets/settings_support_section.dart` (update stale doc comments)
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` (update Send Feedback from Wiredash placeholder to mailto)
- `docs/specs/20260315140000_spec_userorient_integration.md` (remove stale out-of-scope Wiredash reference)
- `docs/specs/202603162012_spec_rate_app_integration.md` (remove stale out-of-scope Wiredash reference)
- `docs/specs/20260227120000_spec_settings_screen.md` (fix `Uri.encodeFull` → `Uri.encodeComponent` at line ~107; preserve historical Wiredash replacement note)

## Approach

### Code cleanup (`settings_support_section.dart`)
- Update all 3 callback doc comments to describe the widget contract precisely:
  - `onFeedbackTap`: "Launches a pre-filled feedback email."
  - `onRateAppTap`: "Navigates to the Rate App screen."
  - `onFeatureRequestTap`: "Opens the UserOrient board."

### Screen prompt (`11-settings-screen.md`)
- L43: Replace `Placeholder (no-op, pending Wiredash)` with description of mailto behavior in the tile table
- Follow existing table format: `| Label | Icon | Trailing | Visibility | Action |`

### Out-of-scope sections
- `20260315140000_spec_userorient_integration.md:147`: Remove entire bullet about "Send Feedback pending Wiredash"
- `202603162012_spec_rate_app_integration.md:277`: Remove entire bullet about "Send Feedback pending Wiredash"

### Settings spec fixes
- `20260227120000_spec_settings_screen.md:~107`: Change `Uri.encodeFull` → `Uri.encodeComponent` to match actual implementation
- The struck-through `~~Wiredash integration~~` replacement note in the settings spec Out of Scope section is a historical design decision record — leave it as-is

## Key context
- The screen prompt file (`11-settings-screen.md`) is used as input for AI-assisted UI generation — stale data causes regressions in future screen regeneration
- Remove entire "pending Wiredash" bullets from out-of-scope sections rather than leaving tombstones
- Historical replacement notes (struck-through with rationale) are acceptable — only remove actionable stale references
## Acceptance
- [ ] All 3 callback doc comments in `settings_support_section.dart` describe the widget contract precisely (no placeholder/TODO wording)
- [ ] `11-settings-screen.md` tile table shows mailto action for Send Feedback (not Wiredash placeholder)
- [ ] UserOrient spec out-of-scope no longer mentions "Send Feedback pending Wiredash"
- [ ] Rate App spec out-of-scope no longer mentions "Send Feedback pending Wiredash"
- [ ] Settings spec references `Uri.encodeComponent` (not `Uri.encodeFull`)
- [ ] Historical replacement note in settings spec Out of Scope preserved (struck-through with rationale)
- [ ] `flutter analyze` clean
## Done summary
Cleaned up all stale Wiredash references: updated 3 callback doc comments in settings_support_section.dart to describe actual widget contracts, updated 11-settings-screen.md tile table for Send Feedback mailto action, removed "Send Feedback pending Wiredash" bullets from UserOrient and Rate App specs, and fixed Uri.encodeFull to Uri.encodeComponent in the settings spec. Historical struck-through Wiredash note preserved.
## Evidence
- Commits: 98da0d7e8b716ea7cc8ade93c849afe632671431
- Tests: flutter analyze, flutter test test/settings/
- PRs: