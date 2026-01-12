# NeuroStack Specifications

## Architecture
- [conventions.md](./best_practices/conventions.md) - naming conventions, PascalCase, camelCase, file structure, feature folders, coding standards
- [general_structure_and_guidelines.md](./best_practices/general_structure_and_guidelines.md) - MVVM, ValueNotifier, state management, dependency injection, service locator, routing, navigation, ViewModel, StatefulWidget
- [MVVM and DDD Guide](./best_practices/architecture/mvvm_and_ddd_guide.md) - MVVM, DDD, ValueNotifier, aggregate root, EntityMixin, value objects, Either, repository pattern, sealed state, DTO, flatMap, DomainFailure
- [MVVM + DDD Supabase Magic Link Authentication](./best_practices/architecture/mvvm_and_ddd_supabase_magic_link_authentication.md) - magic link, supabase auth, deep linking, PKCE, OTP verification, AuthState listener, SupaMagicAuth, passwordless login
- [MVVM + DDD Supabase Integration Supplement](./best_practices/architecture/mvvm_and_ddd_supabase_integration_supplement.md) - supabase, DataSourceAbstraction, DTO, @JsonKey, snake_case mapping, PostgrestException, error mapping, mocking supabase, sealed state, flatMap chaining

## Domain
- [Ubiquitous Language](./ubiquitous-language.md) - domain terms, monetization, free tier, premium trial, subscription status, protocol, session, target, streak, stack, invariants, business rules

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
- [00-flutter-testing-core.md](./best_practices/test/domain/00-flutter-testing-core.md) - flutter test, unit testing, AAA pattern, arrange act assert, boundary testing, mocktail, fakeAsync, setUp tearDown
- [01-test-factories.md](./best_practices/test/domain/01-test-factories.md) - factory pattern for domain entities, domain service tests, TestConstants, abstract final class, nullable ID pattern, optional parameters,
  boundary states, createAtCapacity, barrel export, magic values, domain entity mocking
- [02-test-constants.md](./best_practices/test/domain/02-test-constants.md) - test constants, TestConstants, magic values, test data, cross-references, dynamic values, abstract final class, factory defaults
- [03-parameterized-test.md](./best_practices/test/domain/03-parameterized-test.md) - parameterized tests, Dart records, for loop tests, edge cases, boundary conditions, input validation, test cases array, overlap detection,   
    TimeRange, Email validation
- [04-result-assertions.md](./best_practices/test/domain/04-result-assertions.md) - Result assertions, Either testing, fpdart, custom matchers, domain errors, isSuccessWith, isFailureWith, sealed class errors, fold pattern
- [05-widget-tests.md](./best_practices/test/domain/05-widget-tests.md) - widget tests, testWidgets, pump, pumpAndSettle, finders, find.byKey, golden tests, form validation testing, dialog testing, navigation testing,    
WidgetTester
- [06-dto-factories.md](./best_practices/test/data-layer/06-dto-factories.md) - DTO factories, test factories, JSON parsing tests, toDomain failures, fromJson tests, createWithInvalid, createAtCapacity, snake_case JSON
- [07-either-matchers.md](./best_practices/test/data-layer/07-either-matchers.md) - Either matchers, fpdart matchers, isRight, isLeft, isLeftWithCode, isRightWith, DomainFailure, matcher mismatch messages
- [data-layer-supabase-testing.md](./best_practices/test/data-layer/data-layer-supabase-testing.md) - Supabase testing, repository tests, data layer tests, PostgrestException, error mapping, DTO tests, data source mocks, PGRST codes,
pagination boundaries
- - [integration_test.md](./best_practices/integration_test.md) - integration test, robot pattern, pumpUntilFound, ModuleLocator reset, mocking, mock data sources, widget keys, Patrol, test sharding, CI

## Feature Specs
- [Spec: Home Screen](./specs/20260105234900_spec_home_screen.md) - HomeView, stack screen, protocol cards, subscription banner, trial modal, deactivation modal, bottom navigation, empty state
- [Spec: Library Screen](./specs/20260106213520_spec_library_screen.md) - LibraryView, protocol activation, badge states, detail sheet, paywall, spotlight card, locked protocols, category grouping
- [Spec: Progress Screen](./specs/20260108232500_spec_progress_screen.md) - ProgressView, week grid, adherence tracking, CellState, backdate flow, DateTimeRange, weekStart, weekEnd, protocol row
- [Spec: Onboarding](./specs/20260103223600_spec_onboarding_screens.md) - OnboardingView, PageView, SharedPreferences, auth integration, orientation lock, existing user migration, EnumPageView, disclaimer checkbox

## Investigations
- [Investigation: Protocol Names Missing](./investigations/20260108223900_investigation_progress_protocol_names.md) - ProgressGrid, layout collapse, nameWidth, narrow screen, responsive, horizontal scroll, widget overflow
- [Investigation: DTO Type Cast](./investigations/20260108214300_investigation_is_as_subtype_string_in_cast.md) - type cast error, int to String, ProtocolDto, SessionDto, Supabase bigint, fromJson, json_serializable

## Changelogs
- [Changelog: Home Screen](./changelogs/20260106153900_home_screen_changelog.md) - HomeViewModel, HomeViewState, status banner, protocol card, bottom nav, connectivity, route config
- [Changelog: Library Screen](./changelogs/20260107224528_library_screen_changelog.md) - LibraryViewModel, LibraryViewState, protocol cache, offline mode, detail sheet, add remove protocol
- [Changelog: Progress Screen](./changelogs/20260109105000_progress_screen_changelog.md) - ProgressViewModel, ProgressState, week cache, backdate session, SessionDraft, optimistic UI, grid overflow fix

```

The descriptors (after the dash) are what boost search hits. Be generous with synonyms.

### Step 2: Bootstrap Missing Specs via Conversation

For each area where you have code but no spec, start a fresh Claude Code session:
```
I have an existing Flutter app with [X feature] already implemented.
I want to reverse-engineer a specification from the existing code.

Pin: specs/README.md

Use the search tool to find how [feature] is currently implemented,
then generate a spec at specs/[area]/[feature].md that documents:
- Current behavior
- Business rules
- Key files and hunks involved

Then update specs/README.md with the new link and descriptors.