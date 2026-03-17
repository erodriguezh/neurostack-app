# fn-76-integrate-userorient-flutter-for.3 Update settings screen spec and screen prompt docs

## Description
Update settings screen documentation to list all currently rendered tiles and reflect the UserOrient integration for Feature Request.

**Size:** S
**Files:**
- `docs/specs/20260227120000_spec_settings_screen.md` — update tile table to list all 5 rendered tiles, add userorient_flutter dependency, clarify placeholder status
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` — update tile table to list all 5 rendered tiles

## Approach
- In the settings screen spec (`docs/specs/20260227120000_spec_settings_screen.md`):
  - **Tile Definitions table** (line 79 area): update to list ALL currently rendered tiles:
    1. Contact Us — `LucideIcons.mail`, chevron-right, always visible, navigates to `/settings/contact`
    2. Send Feedback — `LucideIcons.messageSquare`, chevron-right, always visible, **placeholder (no-op, pending Wiredash)**
    3. Rate the App — `LucideIcons.star`, external-link, always visible, **placeholder (no-op, pending App Store rating)**
    4. Feature Request — `LucideIcons.lightbulb`, chevron-right, always visible, opens UserOrient board
    5. Cancel Subscription — `LucideIcons.creditCard`, external-link, premium only, opens platform subscription management
  - **Dependencies section** (line 125 area): add `userorient_flutter: ^2.1.0`
  - **Note** (line 84 area): update to state that all 5 tiles are rendered. Feature Request is functional via UserOrient. Send Feedback and Rate the App are placeholder tiles with no-op callbacks pending future integrations.
  - **Out of Scope section** (line 140 area): remove Feature Request. Keep: Wiredash integration (for Send Feedback), App Store rating (for Rate the App). Note both tiles exist in code as placeholders.
- In the screen prompt (`docs/best_practices/design/screen-prompts/11-settings-screen.md`):
  - **Tile definitions table** (line 39-43): update to list all 5 currently rendered tiles with their icons, trailing icons, visibility, and action (or "placeholder" for no-op tiles)

## Acceptance
- [ ] Settings screen spec tile table lists all 5 rendered tiles: Contact Us, Send Feedback (placeholder), Rate the App (placeholder), Feature Request (UserOrient), Cancel Subscription
- [ ] Settings screen spec lists `userorient_flutter: ^2.1.0` in Dependencies
- [ ] Out of Scope / Note sections accurately describe: Feature Request is functional; Send Feedback and Rate the App are placeholder tiles in code
- [ ] Screen prompt tile table lists all 5 rendered tiles

## Done summary
Updated settings screen spec and screen prompt to list all 5 rendered tiles (Contact Us, Send Feedback placeholder, Rate the App placeholder, Feature Request via UserOrient, Cancel Subscription), added userorient_flutter dependency, and clarified conditional visibility and placeholder status in note/out-of-scope sections.
## Evidence
- Commits: 9998fe88c97e92253e2331c83b87f6227ee2dfe3
- Tests:
- PRs: