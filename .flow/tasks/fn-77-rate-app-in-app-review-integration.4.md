# fn-77-rate-app-in-app-review-integration.4 Documentation: screen prompt, spec updates, README

## Description
Create the Rate App screen prompt doc, update Settings screen spec and screen prompt to remove placeholder notes, update README with new links, rewrite the existing rate app spec to proper format, and fix screen functional specs metadata.

**Size:** M
**Files:**
- `docs/best_practices/design/screen-prompts/12-rate-app-screen.md` (new — screen prompt)
- `docs/best_practices/design/screen-prompts/11-settings-screen.md` (update placeholder note)
- `docs/specs/20260227120000_spec_settings_screen.md` (update placeholder, out-of-scope, deps)
- `docs/specs/202603162012_spec_rate_app_integration.md` (rewrite from research notes to proper spec)
- `docs/best_practices/design/screen-functional-specifications.md` (add Rate App screen entry + fix metadata counts)
- `docs/README.md` (add screen prompt link + spec link)

## Approach

### New screen prompt: `12-rate-app-screen.md`
- Follow format of `11-settings-screen.md`
<!-- Updated by plan-sync: fn-77.2 used AppGridBackground + Scaffold (no AppBar), star_rounded only on primary CTA, no icon on secondary CTA -->
- Layout: `AppGridBackground(mode: AppGridBackgroundMode.adaptive)` wrapping a `Scaffold` (transparent background, no `AppBar`). Close button is a standalone `IconButton(Icons.close)` in an `Align(topRight)` row, using `locator<RouterService>().back()`. Body is a centered column inside `Expanded` + horizontal padding.
- Neurostack logo (`assets/logo.svg` via `SvgPicture.asset`, 48x48, tinted `colorScheme.primary`) centered in upper area with glow shadow
- Title: "Enjoying Neurostack?" — `textTheme.headlineMedium`
- Body text: "Your feedback helps improve the app and reach more people who can benefit from evidence-based wellness protocols." — `textTheme.bodyMedium` with `semanticColors.inkSubtle`, max width 320
- Primary CTA: "Rate on App Store" (`FilledButton.icon` with `Icons.star_rounded` only, no external-link icon) — `openStoreListing()`
- Secondary CTA: "Quick Rating" (`OutlinedButton`, text only, no icon) — `requestReviewForScreen()` (service handles internal fallback)
- Semantic color tokens only (`AppSemanticColors`), `AppSpacing` grid, `context.borderRadius.full` for pill-shaped buttons
- Route: `/settings/rate-app`, pushed via `RouterService.goTo()`, `requiresAuth: true`, no bottom nav
- Note unsupported platform behavior: Quick Rating hidden, store link via url_launcher fallback, missing config disables CTA
- Note navigation uses `RouterService` (NOT GoRouter or `Navigator.pop()`)

### Update `11-settings-screen.md`
- Change Rate the App tile row: trailing icon `external-link` → `chevron-right`, action text from placeholder to "Navigate to /settings/rate-app via RouterService"

### Update Settings spec (`20260227120000`)
- Tile Definitions table: update Rate the App action to "Navigate to /settings/rate-app"
- Remove "App Store rating integration" from Out of Scope section
- Add `in_app_review` to Dependencies
- Update note block under Tile Definitions (remove placeholder language)

### Rewrite rate app spec (`202603162012`)
- Transform from best-practices research essay into standard spec format
- Follow structure of `docs/specs/20260315140000_spec_userorient_integration.md`
- Include: Goal & Context, Architecture (InAppReviewService, InAppReviewAdapter, ReviewTriggerHelper, constructor deps), API Contracts (method signatures), Edge Cases (iOS 18 freeze, Android NPE, missing config, unsupported platforms, fallback config validation, fallback launch failure), Acceptance Criteria, Boundaries
- Keep the original research content as an appendix or reference section

### Update screen functional specs
- Add "11. Rate App Screen" section with: Route, Wireframe, States, Navigation (RouterService), Invariants
- **Fix quick-reference metadata counts** — update summary header to reflect actual screen count including Rate App

### Update README
- Add screen prompt link after Settings Screen entry (line 38)
- Add/update spec link in Feature Specs section (line 65)

## Acceptance
- [ ] `docs/best_practices/design/screen-prompts/12-rate-app-screen.md` created with full screen prompt
- [ ] Screen prompt documents `RouterService.back()` for close (not `Navigator.pop()`)
- [ ] `11-settings-screen.md` updated: Rate the App tile action updated, trailing icon corrected
- [ ] Settings spec: placeholder removed from Tile Definitions, removed from Out of Scope, `in_app_review` added to Dependencies
- [ ] `202603162012_spec_rate_app_integration.md` rewritten in standard spec format (Goal, Architecture, API Contracts, Edge Cases, Acceptance Criteria)
- [ ] Rate app spec includes: ReviewTriggerHelper, fallback config validation, fallback launch failure handling
- [ ] Screen functional specs updated with Rate App screen entry
- [ ] Screen functional specs quick-reference metadata counts corrected
- [ ] `docs/README.md` updated with screen prompt link and spec link
- [ ] All doc formatting consistent with existing docs

## Done summary
Created Rate App screen prompt, rewrote rate app spec to standard format with API Contracts and Acceptance Criteria sections, updated Settings screen prompt/spec to remove placeholder language, added Rate App entry to screen functional specs with corrected metadata counts, and verified README links.
## Evidence
- Commits: 0d9149b, 2d408ef, 2126a08
- Tests: flutter analyze
- PRs: