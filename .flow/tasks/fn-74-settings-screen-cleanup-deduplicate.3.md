# fn-74-settings-screen-cleanup-deduplicate.3 Documentation cleanup: fix dead references, update plan, add mixin to README

## Description
Fix documentation issues introduced or revealed during settings screen implementation, including spec drift from stub tile removal and broken links to the missing settings screen prompt file.

**Size:** S
**Files:**
- `docs/README.md`
- `docs/specs/20260227120000_spec_settings_screen.md`
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` (new — create minimal prompt)
- `plan_settings_screen.md`

## Approach

### 1. Create missing settings screen prompt file

`11-settings-screen.md` is referenced by THREE documents but does not exist:
- `docs/README.md` line 38
- `docs/specs/20260227120000_spec_settings_screen.md` (UI Specification link)
- `plan_settings_screen.md` (UI Design link at top)

Create `docs/best_practices/design/screen-prompts/11-settings-screen.md` with minimal content consistent with the Settings spec + `docs/design_screenshots/11-settings.png` (if screenshot exists). Follow the pattern of existing prompts (`00-splash-screen.md` through `10-auth-check-email.md`). Keep it concise — a minimal prompt, not a full design doc.

### 2. Update settings spec for tile removal

`docs/specs/20260227120000_spec_settings_screen.md` defines 5 tiles in the "Tile Definitions" section. After fn-74.1 removes 3 stub tiles, update the spec:
- Remove Send Feedback, Rate the App, and Feature Request from tile definitions
- Update any narrative text that references "five tiles" or lists the removed tiles
- Update the `docs/README.md` Settings Screen prompt descriptor (line 38) to remove "rate app, feedback" from the keywords

### 3. Update plan to reflect PremiumAwareViewModelMixin

`plan_settings_screen.md` Phase 2.1 (lines 56-92) instructs wiring `EntitlementListenerMixin` directly and writing `isPremium` boilerplate inline. The actual implementation uses `PremiumAwareViewModelMixin` (extracted in commit `e0bcc9e`). Add a note at the top of Phase 2 indicating the implementation diverged to use the mixin. Also add a note in Phase 3.6 that fn-74 removed the Feedback/Rate/Feature Request tiles (e.g., "Post-implementation cleanup (fn-74) removed Feedback/Rate/Feature Request tiles; see spec for current tile set.").

### 4. Add core abstractions to README

`docs/README.md` "Core Infrastructure" section (lines 83-94) lists shared utilities but does not mention the 3 core abstractions:
- `EntitlementListenerMixin` at `lib/core/abstractions/entitlement_listener_mixin.dart`
- `PremiumAwareViewModelMixin` at `lib/core/abstractions/premium_aware_view_model_mixin.dart`
- `ConnectivityListenerMixin` at `lib/core/abstractions/connectivity_listener_mixin.dart`

Add a bullet for the abstractions directory.

## Acceptance
- [ ] `docs/best_practices/design/screen-prompts/11-settings-screen.md` exists with minimal prompt content
- [ ] All 3 references to `11-settings-screen.md` (README, spec, plan) resolve to the new file
- [ ] `docs/specs/20260227120000_spec_settings_screen.md` tile definitions match implementation (2 tiles: Contact Us + Cancel Subscription)
- [ ] `docs/README.md` Settings Screen prompt descriptor updated (no mention of removed tiles)
- [ ] `plan_settings_screen.md` Phase 2 has a note about PremiumAwareViewModelMixin
- [ ] `docs/README.md` Core Infrastructure section mentions core abstractions (mixins)
- [ ] No broken links in `docs/README.md`
## Done summary
TBD

## Evidence
- Commits:
- Tests:
- PRs:
