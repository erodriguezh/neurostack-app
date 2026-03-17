# Rate App Screen

Create a Rate App screen for in-app review prompts and App Store listing navigation.

> Semantic token mapping note: This is an adaptive route. Map any `white/XX`
> prompt values to `ColorScheme`/`AppSemanticColors` equivalents instead of
> using `kitColors.whiteXX` directly.

Background: `AppGridBackground(mode: AppGridBackgroundMode.adaptive)` wrapping a `Scaffold` (transparent background, no `AppBar`).

Layout:

1. Close button (Align topRight, pt-sm, pr-sm):
   - `IconButton(Icons.close)`, color `semanticColors.inkSubtle`
   - Action: `locator<RouterService>().back()` (NOT `Navigator.pop()`)

2. Body (Expanded, centered column, px-lg):
   - Spacer(flex: 2) at top

   - Logo:
     - `SvgPicture.asset('assets/logo.svg')`, 48x48
     - `ColorFilter.mode(colorScheme.primary, BlendMode.srcIn)`
     - Container with `BoxShadow`: `colorScheme.primary.withValues(alpha: 0.2)`, blurRadius 15
     - Spacing below: `spacing.xl`

   - Title: "Enjoying Neurostack?" — `textTheme.headlineMedium`, centered

   - Body text (spacing.md below title):
     - "Your feedback helps improve the app and reach more people who can benefit from evidence-based wellness protocols."
     - `textTheme.bodyMedium`, color `semanticColors.inkSubtle`, centered
     - `ConstrainedBox(maxWidth: 320)`

   - Spacer(flex: 3)

   - Primary CTA: "Rate on App Store"
     - `FilledButton.icon` with `Icons.star_rounded` (size 18) — no external-link icon
     - Full width, `Size.fromHeight(56)`, pill shape (`context.borderRadius.full`)
     - `backgroundColor: colorScheme.primary`, `foregroundColor: colorScheme.onPrimary`
     - `textStyle: textTheme.labelLarge` with `FontWeight.w600`, letterSpacing 0.2
     - Always rendered. Enabled when `viewModel.canOpenStoreListing` is true (native service OR fallback URL available); disabled otherwise
     - When disabled (no native service AND no fallback config): show disabled button + "Store rating not available on this platform" in `textTheme.bodySmall` / `semanticColors.inkSubtle`
     - Action: `viewModel.openStoreListing()` — delegates to native service or fallback `url_launcher`

   - Secondary CTA: "Quick Rating" (spacing.md below primary)
     - `OutlinedButton` — text only, no icon
     - Full width, `Size.fromHeight(56)`, pill shape (`context.borderRadius.full`)
     - `side: BorderSide(color: semanticColors.border)`, `foregroundColor: semanticColors.ink`
     - `textStyle: textTheme.labelLarge` with `FontWeight.w600`, letterSpacing 0.2
     - Visible only when `viewModel.isServiceInitialized` is true (iOS/Android only)
     - Action: `viewModel.requestReviewForScreen()` — tries native `requestReview()`, auto-fallback to `openStoreListing()`

   - SizedBox(height: spacing.xl) at bottom

3. Route: `/settings/rate-app`, pushed via `RouterService.goTo()`, `requiresAuth: true`, no bottom nav

4. Navigation:
   - Entry: Settings "Rate the App" tile (star icon, chevron-right trailing)
   - Close: `locator<RouterService>().back()` — same pattern as ContactView
   - Uses `RouterService` throughout (NOT GoRouter or `Navigator.pop()`)

5. Platform behavior:
   - iOS/Android (service initialized): Both CTAs visible, native paths used
   - Web/Desktop (service not initialized, fallback config present): Primary CTA enabled via `url_launcher` fallback, Secondary CTA hidden
   - Web/Desktop (no config): Primary CTA disabled with explanatory text, Secondary CTA hidden
   - Missing `APP_STORE_ID` on Apple platforms (iOS/macOS): Service uninitialized AND no fallback URL available (both require `APP_STORE_ID`), so primary CTA disabled and Quick Rating hidden
