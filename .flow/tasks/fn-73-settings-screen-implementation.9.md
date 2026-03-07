# fn-73-settings-screen-implementation.9 Phase 3.3: Upgrade banner widget

## Description
TBD

## Acceptance
- [ ] TBD

## Done summary
Created SettingsUpgradeBanner widget with crown icon glow, headline/subtitle text, and trailing chevron. Wired into SettingsView with conditional rendering via ValueListenableBuilder on isPremium (hidden for premium users), wrapped in StaggeredFadeIn for entrance animation.
## Evidence
- Commits: a2bb688, 83caec8
- Tests: flutter analyze, flutter test
- PRs: