# fn-81-paywall-apple-compliance.3 Update specs and docs for compliance changes

## Description
**Size:** M
**Files:** (8 docs + 2 code comments + 1 flow epic)
- `docs/specs/20260227120000_spec_settings_screen.md` — reverse Restore out-of-scope, rename Cancel→Manage
- `docs/specs/20260123220000_spec_paywall_modal.md` — update trial assumptions if needed
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` — add Restore tile row, rename Cancel→Manage
- `docs/best_practices/design/screen-prompts/06-paywall-modal.md` — note compliance elements (Restore, Privacy, Terms, disclosure)
- `docs/best_practices/design/screen-prompts/01-on-boarding-3.md` — flag "No credit card required" as inaccurate
- `docs/ubiquitous-language.md` — update Settings examples, annotate INV-M2 trial invariant
- `plan_settings_screen.md` — rename Cancel→Manage, update Restore decision record
- `plan_paywall_modal.md` — fix fn-46 Section 5.3 false [DONE] status
- `lib/paywall/paywall_constants.dart:11-12` — update trial duration comments to match actual config
- `.flow/epics/fn-46-1b8.json` — close zombie epic via flowctl

## Approach

### Settings spec (`docs/specs/20260227120000_spec_settings_screen.md`)
- Lines 171-176: Remove "Restore Purchases tile (not included)" from out-of-scope. Use struck-through pattern: `~~Restore Purchases tile (not included)~~ — Added in fn-81`
- Lines 13, 14, 85, 87, 117, 142: Replace all "Cancel Subscription" → "Manage Subscription"
- Line 156: Update dependency note
- Add new tile row for "Restore Purchases" in the tile table (line 85 area)

### Settings screen prompt (`docs/best_practices/design/screen-prompts/11-settings-screen.md`)
- Line 46: Rename Cancel→Manage in tile table, add Restore Purchases row

### Paywall screen prompt (`docs/best_practices/design/screen-prompts/06-paywall-modal.md`)
- Note that the hosted paywall now includes: Restore button, Privacy Policy link, Terms of Use link, auto-renewal disclosure

### Onboarding screen prompt (`docs/best_practices/design/screen-prompts/01-on-boarding-3.md`)
- Line 38: Flag "No credit card required" as inaccurate for App Store (Apple requires payment method for trials)

### Ubiquitous language (`docs/ubiquitous-language.md`)
- Line 270: Update Settings examples to include "Restore Purchases" and "Manage Subscription"
- Lines 121-124 (INV-M2): Annotate trial invariant with note that trial_duration was null until fn-81

### Plan files
- `plan_settings_screen.md:113-116`: Annotate that the "Restore removed per spec" decision was reversed by fn-81
- `plan_settings_screen.md:186,310`: Rename Cancel→Manage
- `plan_paywall_modal.md` Section 5.3: Change [DONE] → annotate as re-opened by fn-81

### Code comments
- `lib/paywall/paywall_constants.dart:11-12`: Update "7-day trial" comments to reflect actual configured state

### Close fn-46-1b8
```bash
.flow/bin/flowctl epic close fn-46-1b8 --reason "Absorbed by fn-81-paywall-apple-compliance.2"
```
## Acceptance
- [ ] Settings spec: "Restore Purchases" removed from out-of-scope, added to tile table
- [ ] Settings spec: all "Cancel Subscription" → "Manage Subscription"
- [ ] Settings screen prompt: tile table updated (Restore + Manage)
- [ ] Paywall screen prompt: compliance elements noted
- [ ] Onboarding screen prompt: "No credit card required" flagged
- [ ] Ubiquitous language: Settings examples updated, INV-M2 annotated
- [ ] plan_settings_screen.md: Restore decision record annotated, labels updated
- [ ] plan_paywall_modal.md: Section 5.3 status corrected
- [ ] paywall_constants.dart: trial comments match actual config
- [ ] fn-46-1b8 epic closed in .flow
## Done summary
Updated 8 docs + 1 code comment file + closed zombie epic fn-46-1b8.

Changes:
- Settings spec: Restore removed from out-of-scope, added to tile table, Cancel→Manage, merged screen states table with visibility rules
- Settings screen prompt: tile table updated, trailing icon defined as optional
- Paywall screen prompt: compliance elements noted
- Onboarding screen prompt: "No credit card required" flagged as inaccurate
- Ubiquitous language: Settings examples updated, INV-M2 annotated
- plan_settings_screen.md: Restore decision annotated, labels updated
- plan_paywall_modal.md: Section 5.3 status corrected
- paywall_constants.dart: trial comments updated to reference P7D config
- fn-46-1b8 zombie epic closed
- `224ea61`: merged Settings screen-state/visibility rules into one table and standardized trailing-icon wording as optional in both the spec and screen prompt

Commits: 6b08e1b, b59d6f4, a706f47, bd50490, 224ea61
## Evidence
- Commits: 6b08e1b, b59d6f4, a706f47, bd50490, 224ea61
- Tests: 958 passed, 1 pre-existing failure (unrelated)
- PRs: