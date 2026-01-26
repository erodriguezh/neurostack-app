# NeuroStack Specifications

## Quick Start
- [CLAUDE.md](../CLAUDE.md) - build commands, architecture overview, layer structure, key patterns, testing, environment setup
- [AGENTS.md](../AGENTS.md) - repository guidelines, coding style, commit conventions, PR guidelines

## Architecture
- [conventions.md](./best_practices/conventions.md) - naming conventions, file structure, feature folders, lower_snake_case, UpperCamelCase
- [general_structure_and_guidelines.md](./best_practices/general_structure_and_guidelines.md) - MVVM wiring, ValueNotifier state, DI/service locator, routing and navigation
- [MVVM and DDD Guide](./best_practices/architecture/mvvm_and_ddd_guide.md) - aggregates, invariants, Either flows, repositories, DTOs, domain events, fpdart
- [MVVM + DDD Supabase Magic Link Authentication](./best_practices/architecture/mvvm_and_ddd_supabase_magic_link_authentication.md) - magic link auth flow, deep linking, PKCE/OTP, auth callbacks
- [MVVM + DDD Supabase Integration Supplement](./best_practices/architecture/mvvm_and_ddd_supabase_integration_supplement.md) - Supabase data sources, DTO mapping, PostgrestException handling, mocking, PGRST codes

## Domain
- [Ubiquitous Language](./ubiquitous-language.md) - domain terms, subscription tiers, invariants, business rules, INV-U1, INV-M2
- [DomainFailure](../lib/core/failures/domain_failure.dart) - canonical failure shape and naming convention ({Aggregate}.{Invariant})

## UI
- [visual-design.md](./best_practices/design/visual-design.md) - design tokens, ColorScheme, Material 3, typography, TextTheme, spacing grid, AppColors, AppSpacing, theming, dark mode, accessibility
- [UI Widget Guidelines](./best_practices/design/ui_widget_guidelines.md) - StatelessWidget extraction, const constructors, widget composition, ValueNotifier state, sealed state classes, ViewModel pattern, ListView.builder, ValueKey/ObjectKey, pure build methods, RepaintBoundary, FadeTransition, widget granularity, lint config
- [Screen Functional Specs](./best_practices/design/screen-functional-specifications.md) - screen specs, wireframes, navigation routes, subscription states, paywall modal, protocol stack, log session, error mapping

### Screen Prompts
- [Splash Screen](./best_practices/design/screen-prompts/00-splash-screen.md) - splash, loading, logo, pulse animation, brand sky, neural icon
- [Onboarding 1 - Hook](./best_practices/design/screen-prompts/01-on-boarding-1.md) - onboarding, cold plunge, zone 2, cardio, stagger animation, progress dots
- [Onboarding 2 - Agitation](./best_practices/design/screen-prompts/01-on-boarding-2.md) - agitation, knowing-doing gap, protocol abandonment, motivation, week one
- [Onboarding 3 - Value Prop](./best_practices/design/screen-prompts/01-on-boarding-3.md) - value props, trial offer, 7 days free, streaks, CTA button, benefits list
- [Onboarding 4 - Disclaimer](./best_practices/design/screen-prompts/01-on-boarding-4.md) - disclaimer, health warning, medical advice, consent checkbox, terms
- [Home & Stack Screen](./best_practices/design/screen-prompts/02-home-and-stack-screen.md) - home, stack, protocol card, trial banner, bottom nav, log session, empty state, spotlight effect
- [Library Screen](./best_practices/design/screen-prompts/03-library-screen.md) - library, protocol list, locked state, evidence RCT, free tier, upgrade
- [Progress Screen](./best_practices/design/screen-prompts/04-progress-screen.md) - progress, weekly grid, session tracking, completed, missed, legend, date range
- [Log Session Modal](./best_practices/design/screen-prompts/05-log-session-modal.md) - log session, modal, date picker, duration input, notes, form fields, slide-up
- [Paywall Modal](./best_practices/design/screen-prompts/06-paywall-modal.md) - paywall, subscription, pricing cards, annual, monthly, premium, subscribe
- [Trial Expiration Modal](./best_practices/design/screen-prompts/07-trial-expiration-modal.md) - trial expired, blocking modal, upgrade, downgrade, free tier limit, hourglass
- [Protocol Selection Modal](./best_practices/design/screen-prompts/08-protocol-selection-modal.md) - protocol selection, deactivation, choose two, downgrade, checkbox, session count
- [Auth Screen](./best_practices/design/screen-prompts/09-auth-screen.md) - auth, login, sign in, email input, magic link, passwordless
- [Auth Check Email](./best_practices/design/screen-prompts/10-auth-check-email.md) - check email, inbox, magic link sent, resend link, cooldown timer, verification

## Testing
- [Testing Rules Index](./best_practices/test/domain/index.md) - quick reference, test naming, file structure, boundary testing, factory pattern, hard rules, adoption guide, test checklist
- [00-flutter-testing-core.md](./best_practices/test/domain/00-flutter-testing-core.md) - flutter test, unit testing, AAA pattern, arrange act assert, boundary testing, mocktail, fakeAsync, setUp tearDown, never Future.delayed
- [01-test-factories.md](./best_practices/test/domain/01-test-factories.md) - factory pattern for domain entities, domain service tests, TestConstants, abstract final class, nullable ID pattern, optional parameters, boundary states, createAtCapacity, barrel export, magic values, domain entity mocking
- [02-test-constants.md](./best_practices/test/domain/02-test-constants.md) - test constants, TestConstants, magic values, test data, cross-references, dynamic values, abstract final class, factory defaults
- [03-parameterized-test.md](./best_practices/test/domain/03-parameterized-test.md) - parameterized tests, Dart records, for loop tests, edge cases, boundary conditions, input validation, test cases array, overlap detection, TimeRange, Email validation
- [04-result-assertions.md](./best_practices/test/domain/04-result-assertions.md) - Result assertions, Either testing, fpdart, custom matchers, domain errors, isSuccessWith, isFailureWith, sealed class errors, fold pattern, isRightWith, isLeftWith
- [05-widget-tests.md](./best_practices/test/domain/05-widget-tests.md) - widget tests, testWidgets, pump, pumpAndSettle, finders, find.byKey, golden tests, form validation testing, dialog testing, navigation testing, WidgetTester
- [06-dto-factories.md](./best_practices/test/data-layer/06-dto-factories.md) - DTO factories, test factories, JSON parsing tests, toDomain failures, fromJson tests, createWithInvalid, createAtCapacity, snake_case JSON
- [07-either-matchers.md](./best_practices/test/data-layer/07-either-matchers.md) - Either matchers, fpdart matchers, isRight, isLeft, isLeftWithCode, isRightWith, DomainFailure, matcher mismatch messages
- [data-layer-supabase-testing.md](./best_practices/test/data-layer/data-layer-supabase-testing.md) - Supabase testing, repository tests, data layer tests, PostgrestException, error mapping, DTO tests, data source mocks, PGRST codes, pagination boundaries
- [integration_test.md](./best_practices/integration_test.md) - integration test, robot pattern, pumpUntilFound, ModuleLocator reset, mocking, mock data sources, widget keys, Patrol, test sharding, CI

## Feature Specs
- [Spec: Auth](./specs/20260113143000_spec_auth.md) - AuthService, AuthState, magic link, OTP, CachedUserStore, UserBootstrapService, offline-first, recovery upsert, session management
- [Spec: Home Screen](./specs/20260105234900_spec_home_screen.md) - HomeView, stack screen, protocol cards, subscription banner, trial modal, deactivation modal, bottom navigation, empty state
- [Spec: Library Screen](./specs/20260106213520_spec_library_screen.md) - LibraryView, protocol activation, badge states, detail sheet, paywall, spotlight card, locked protocols, category grouping
- [Spec: Progress Screen](./specs/20260108232500_spec_progress_screen.md) - ProgressView, week grid, adherence tracking, CellState, backdate flow, DateTimeRange, weekStart, weekEnd, protocol row
- [Spec: Session](./specs/20260113151500_spec_session.md) - Session aggregate, SessionDraft, SessionDuration value object, LogSessionUseCase, INV-S2 future timestamp, INV-S3 positive duration, append-only persistence
- [Spec: Onboarding](./specs/20260103223600_spec_onboarding_screens.md) - OnboardingView, PageView, SharedPreferences, auth integration, orientation lock, existing user migration, EnumPageView, disclaimer checkbox
- [Spec: Log Session Modal](./specs/20260113180000_spec_log_session_modal.md) - LogSessionModal, offline-first, SessionSyncService, eligibility check, backdate 7 days, haptic feedback, accessibility announcements
- [Spec: Trial Expiration Cronjob](./specs/20260122150000_spec_trial_expiration_cronjob.md) - pg_cron, trial_ends_at, trial_expired_at, expire_trials(), idempotent transition, subscription status free, UTC timezone
- [Spec: Paywall Modal](./specs/20260123220000_spec_paywall_modal.md) - RevenueCat integration, entitlement mapping, customer identification, webhook architecture, trial reminder

## Investigations
- [Investigation: Protocol Names Missing](./investigations/20260108223900_investigation_progress_protocol_names.md) - ProgressGrid, layout collapse, nameWidth, narrow screen, responsive, horizontal scroll, widget overflow
- [Investigation: DTO Type Cast](./investigations/20260108214300_investigation_is_as_subtype_string_in_cast.md) - type cast error, int to String, ProtocolDto, SessionDto, Supabase bigint, fromJson, json_serializable
- [Investigation: Trial Expiration Race Condition](./investigations/20260122180000_investigation_trial_expiration_race_condition.md) - modal repeat, cron gap, SharedPreferences, TrialExpirationDecisionStore, once-only trigger, app restart, decision persistence

## Implementation Plans
- [Plan: Trial Expiration Modal](../plan_trial_expiration_modal.md) - trial expired modal, TrialExpiredChoice, blocking dialog, upgrade card, downgrade card, CachedUserStore, free tier transition
- [Plan: Trial Expiration Cronjob](../plan_trial_expiration_cron_job.md) - pg_cron, trial_ends_at, expire_trials(), CHECK constraint, TrialPeriodDto endDate, TrialExpirationDecisionStore, SharedPreferences, race condition fix
- [Plan: Paywall Modal](../plan_paywall_modal.md) - RevenueCat SDK setup, auth integration, subscription sync, paywall presentation, webhook edge function, trial reminder

## Changelogs
- [Changelog: Home Screen](./changelogs/20260106153900_home_screen_changelog.md) - HomeViewModel, HomeViewState, status banner, protocol card, bottom nav, connectivity, route config
- [Changelog: Library Screen](./changelogs/20260107224528_library_screen_changelog.md) - LibraryViewModel, LibraryViewState, protocol cache, offline mode, detail sheet, add remove protocol
- [Changelog: Progress Screen](./changelogs/20260109105000_progress_screen_changelog.md) - ProgressViewModel, ProgressState, week cache, backdate session, SessionDraft, optimistic UI, grid overflow fix

### Core Infrastructure (Well-Documented in Code)
- **Connectivity Service** - `lib/core/utils/connectivity/connectivity_service.dart` - NetworkStatus enum, online/offline detection, ValueNotifier status, connectivity_plus
- **Supabase Error Mapper** - `lib/core/data/supabase_error_mapper.dart` - mapPostgrestError, PGRST codes, 23505 duplicate, 23503 foreign key, 42501 permission, aggregate prefix
- **Router Service** - `lib/core/utils/navigation/router_service.dart` - GoRouter wrapper, route config, navigation, deep linking
- **Navigation Utilities** - `lib/core/utils/navigation/` - route parsing, URL strategy, navigation intent store
- **Toast/Notification** - `lib/core/utils/internal_notification/` - ToastViewModel, ToastEvent, HapticFeedbackListener, in-app notifications
- **Data Source Abstraction** - `lib/core/utils/data_source/data_source_abstraction.dart` - Supabase client wrapper, testability, mocking
- **Localization (l10n)** - `lib/core/utils/l10n/` - ARB files, generated localizations, translate helpers
- **HTTP Abstraction** - `lib/core/utils/http/` - HTTP clients, interceptors, native/web adapters
- **App Environment** - `lib/core/utils/app_environment.dart` - environment flags and config access
- **App Lifecycle Service** - `lib/core/utils/app_lifecycle_service.dart` - app lifecycle hooks and foreground/background handling
- **Service Locator** - `lib/core/utils/locator.dart` - locator access helpers and instance lookup

### App Configuration (Implemented)
- **Route Configuration** - `lib/config/route_config.dart` - route definitions, screen wiring, navigation entry points
- **Service Registration** - `lib/config/locator_config.dart` - dependency registration graph and service setup

### Core UI Widgets (Well-Documented in Code)
- **EnumPageView** - `lib/core/ui/widgets/enum_page_view.dart` - generic PageView driven by enum, smooth transitions, onboarding flows
- **AppPrimaryCta** - `lib/core/ui/widgets/app_primary_cta.dart` - primary CTA button, loading state, disabled state
- **AppGridBackground** - `lib/core/ui/widgets/app_grid_background.dart` - decorative grid background, brand visual

### Design Tokens (Implemented)
- **Spacing** - `lib/core/ui/constants/spacing.dart` - 4px grid, AppSpacing constants
- **Border Radius** - `lib/core/ui/constants/border_radius.dart` - AppBorderRadius, consistent corners
- **Shadows** - `lib/core/ui/constants/shadows.dart` - AppShadows, elevation system
- **Curves** - `lib/core/ui/constants/curves.dart` - CustomCurves, emphasizedDecelerate, animation curves
- **Durations** - `lib/core/ui/constants/durations.dart` - standardized animation timings
- **Colors** - `lib/core/ui/constants/kit_colors.dart` - core palette and semantic color roles
- **Text Styles** - `lib/core/ui/constants/text_styles.dart` - typography scale and text theme helpers
- **Breakpoints** - `lib/core/ui/constants/breakpoints.dart` - responsive breakpoints, mobile/tablet/desktop
- **Widget Keys** - `lib/core/ui/constants/widget_keys.dart` - WidgetKeys, test accessibility

### Feature Modules (Implemented)
- **Auth Feature Module** - `lib/features/auth/` - AuthService, AuthState, magic link views, bootstrap
- **Onboarding Feature Module** - `lib/features/onboarding/` - onboarding steps, scaffolds, view model
- **Protocol Feature Module** - `lib/features/protocol/` - protocol aggregates, DTOs, repository/data source, cache
- **Session Feature Module** - `lib/features/session/` - session aggregates, logging use case, repository
- **User Feature Module** - `lib/features/user/` - user aggregates, subscription status, DTOs, repository

### UI Modules (Implemented)
- **Home UI Module** - `lib/home/` - home view model, widgets, bottom tab coordinator
- **Library UI Module** - `lib/library/` - library view model, widgets, protocol detail sheet
- **Progress UI Module** - `lib/progress/` - progress view model, grid widgets, week cache store
- **Startup UI Module** - `lib/startup/` - splash/startup routing and bootstrap logic
- **Offline UI Module** - `lib/offline/` - offline retry view and view model
- **Paywall UI Module** - `lib/paywall/` - paywall view and view model
- **Not Found UI Module** - `lib/not_found/` - fallback routing view and view model

### Environment & Backend (Implemented)
- **Environment Template** - `env/default.env.json` - expected config keys and defaults
- **Supabase Config** - `supabase/config.toml` - local Supabase project configuration
- **Supabase Migrations** - `supabase/migrations/` - schema history, RLS, auth triggers
- **Supabase Auth Templates** - `supabase/auth/email/` - magic link email templates

### Integration Tests (Code Locations)
- **Integration Test Utilities** - `integration_test/utils/` - test app harness, pump helpers
- **Integration Test Flows** - `integration_test/flows/` - end-to-end flow definitions
- **Integration Test Mocks** - `integration_test/mocks/` - mock states and mock data sources

---

## Template: Bootstrap Missing Spec

For each area where you have code but no spec, start a fresh Claude Code session:
```
I have an existing Flutter app with [X feature] already implemented.
I want to reverse-engineer a specification from the existing code.

Pin: docs/README.md

Use the search tool to find how [feature] is currently implemented,
then generate a spec at docs/specs/YYYYMMDDHHMMSS_spec_[feature].md that documents:
- Current behavior
- Business rules / invariants
- Key files and hunks involved

Then update docs/README.md with the new link and descriptors.
```
