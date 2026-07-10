# NeuroStack codebase audit — 2026-07-09

Adversarial, whole-repo audit (senior-staff + skeptical-consumer + adversarial-reviewer lens). Read first-hand: the full startup/DI/routing/auth/entitlement/session/protocol/paywall execution paths, all 15 SQL migrations + RPC + edge function + config, and the load-bearing view models. Four parallel sub-agents swept the UI layer, core utils + platform shells, the test suite (112 files), and all docs — every reported finding required `file:line` + a concrete scenario, and headline findings were re-verified first-hand. Baseline health at audit time: **`flutter analyze` clean, 1001 unit/widget tests pass, adaptive-color CI guard passes** — so nothing here is a compile/test failure; these are design, security, correctness, and drift issues the green suite does not catch.

Branch: `feature/adversarial-reviews`. Uncommitted (maintainer owns git). Working tree was left unchanged.

Finding IDs are stable and severity-ordered (`C1` = most severe). A fixing agent should cite these IDs.

---

## 1. Summary table

| ID | Sev | Area | One-line issue | file:line | Evidence |
|----|-----|------|----------------|-----------|----------|
| C1 | Critical | Security/RLS | Migration-2 policy DROPs use wrong names → any authenticated user can INSERT/UPDATE `protocols` & INSERT `research_citations` (shared catalog) | supabase/migrations/20251230160000_auth_trigger_and_rls.sql:77-91 | CONFIRMED |
| C2 | High | CI/process | CI triggers only on `main`; repo default is `develop` (+`master`), no `main` → CI never runs on any real push/PR | .github/workflows/test.yaml:4-9 | CONFIRMED |
| C3 | High | Monetization | Entitlement *enforcement* reads persisted DB status while UI reads RC effective status → they diverge for the whole webhook-latency window | lib/features/user/domain/entities/user.dart:120,250 | CONFIRMED |
| C4 | High | Sessions | Log-session sheet is dismissible mid-submit; session persists but success callback is skipped → duplicate session | lib/features/session/presentation/log_session_modal.dart:64; view_models/log_session_view_model.dart:251,281 | CONFIRMED |
| C5 | High | Sessions/TZ | Remote date-range queries send zone-less local ISO strings against `timestamptz` → wrong "today"/"this week" window for non-UTC users | lib/features/session/data/data_sources/session_remote_data_source.dart:40,44 | CONFIRMED |
| C6 | High | Android | `applicationId = com.example.neurostack` → unpublishable; App Links can't verify; review/rate deep-links wrong package | android/app/build.gradle.kts:10,24 | CONFIRMED |
| C7 | High | Android | Release build signed with the debug key | android/app/build.gradle.kts:36 | CONFIRMED |
| C8 | High | macOS | Release entitlements omit `network.client` (present only in Debug) → sandboxed release can't reach the network | macos/Runner/Release.entitlements:5-6 | CONFIRMED |
| C9 | High | Branding | App ships as "Flutter Kit" (iOS display name + `appName` ARB → window/tab title) | ios/Runner/Info.plist:9-10; lib/core/utils/l10n/app_en.arb:3 | CONFIRMED |
| C10 | High | Tests | Integration tests (the only behavioral pins for purchase/trial-modal/nav) execute nowhere | integration_test/**; .github/workflows/test.yaml:60 | CONFIRMED |
| C11 | High | Docs | Superseded magic-link auth documented as current; functional specs cite non-existent routes/methods | docs/specs/20260113143000_spec_auth.md; docs/best_practices/design/screen-functional-specifications.md:62,595 | CONFIRMED |
| C12 | High | Docs/agents | Agent-facing docs point to files that don't exist (`docs/agents/backlog.md`, `CONTEXT.md`) | AGENTS.md:5,13 | CONFIRMED |
| C13 | High | Tests | No unit coverage for RouterService auth guard, `replaceAll([])`, AuthService rehydrate/token-refresh, RC `CustomerInfo`→snapshot mapping, session/user data layer, or free-tier-over-limit | (see finding) | CONFIRMED |
| C14 | Medium | Data layer | `list()` returns `Left` on the first bad DTO → one malformed row breaks the whole screen (chains with C1 → global Library DoS) | lib/features/protocol/data/repositories/protocol_repository_impl.dart:60-65 | CONFIRMED |
| C15 | Medium | RevenueCat | Every logout/retry rebuilds the RC client and adds a global `CustomerInfoUpdateListener` that is never removed | lib/paywall/data/revenuecat_client_mobile.dart:143; config/locator_config.dart:72 | CONFIRMED |
| C16 | Medium | Config | Missing `SUPABASE_URL`/key `defaultValue:''` → app boots then dies at first network call, no fail-fast | lib/core/utils/data_source/data_source_init.dart:29-37 | CONFIRMED |
| C17 | Medium | Coherence | Free-tier limit "2" reimplemented in ≥8 places instead of `SubscriptionStatus.free.protocolLimit` | lib/paywall/widgets/protocol_selection_modal.dart:8; trial_expired_modal.dart:170,175 | CONFIRMED |
| C18 | Medium | i18n | l10n infra exists but only auth/startup/404 use it; the rest of the app hardcodes English → Swedish users get a half-translated app | lib/home/widgets/home_header.dart:17; lib/library/library_view.dart:190 | CONFIRMED |
| C19 | Medium | Dead code | Entire HTTP abstraction (+ `http`/`cronet_http`/`cupertino_http` deps) is registered but never called | lib/config/locator_config.dart:114-123; lib/core/utils/http/* | CONFIRMED |
| C20 | Medium | Observability | Release builds have no log/crash sink; even in debug `record.error`/`stackTrace` are dropped | lib/core/abstractions/logging_abstraction.dart:12-48 | CONFIRMED |
| C21 | Medium | UX/errors | Unmapped Postgrest errors surface raw `code: message` (possibly `"null: …"`) to end users | lib/core/data/supabase_error_mapper.dart:34-37 | CONFIRMED |
| C22 | Medium | Drift | `premiumLifetime` exists in DB CHECK + RPC + webhook TS type but not in the Dart `SubscriptionStatus` enum → writing it breaks client parse | lib/features/user/domain/enums/subscription_status.dart:4-23; supabase/migrations/20260123092258_trial_expiration_columns.sql:19-21 | CONFIRMED |
| C23 | Medium | Toolchain | Local `dart format` (Flutter 3.35.3) reformats 11 committed files; CI pins Flutter 3.32.0 → format churn / spurious failures | (measured) analysis_options.yaml; .github/workflows/test.yaml:16 | CONFIRMED |
| C24 | Medium | Platform | Three different bundle IDs across iOS/macOS/Android; macOS still carries template author's id | ios .../project.pbxproj:503; macos/.../AppInfo.xcconfig; android/app/build.gradle.kts:24 | CONFIRMED |
| C25 | Medium | Affordance | Library protocol-detail "Log Session" button only toasts "Log session flow coming soon" | lib/library/library_view_model.dart:194-196 | CONFIRMED |
| C26 | Medium | Affordance | `/settings/contact` is linked but its body is just a title — empty stub | lib/settings/contact_view.dart:29-44 | CONFIRMED |
| C27 | Medium | UX | "Restore Purchases" exposes no busy/disabled state during a multi-second call | lib/settings/settings_view_model.dart:200-241 | CONFIRMED |
| C28 | Medium | Monetization/UX | Ineligible log-session view says "Upgrade Required" but offers only "Got it" — no path to paywall | lib/features/session/presentation/views/log_session_view.dart:778-808 | CONFIRMED |
| C29 | Medium | UX/perf | Cumulative staggered fade-in leaves bottom list items blank ~2 s on every re-scroll into view | lib/core/ui/widgets/staggered_fade_in.dart:27; lib/library/library_view.dart:210 | CONFIRMED |
| C30 | Medium | Navigation | Tab switches do `replaceAll` + hashCode page keys → full State teardown/refetch; `PageStorageKey` scroll memory is dead code | lib/home/home_bottom_tab_coordinator.dart:19-28; lib/library/library_view.dart:94 | CONFIRMED |
| C31 | Medium | Correctness | "Current streak" counts back from the most recent session, not today → stale streaks (and "1 days") | lib/library/library_stats.dart:42-43 | CONFIRMED |
| C32 | Medium | DX | `tool/verify.sh` checks a different predicate than CI (different format scope, `--fatal-infos`, no golden exclude, skips the adaptive guard) | tool/verify.sh:14-20 | CONFIRMED |
| C33 | Medium | Dead code | Domain events are raised but never dispatched/cleared; `popDomainEvents`/`clearDomainEvents` have no callers | lib/core/models/common/aggregate_root.dart:14-22 | CONFIRMED |
| C34 | Medium | Config | `APP_ENV` is set nowhere → every log says `env=prod`; `AppEnvironment.isDev` is dead | lib/core/utils/app_environment.dart:2-7 | CONFIRMED |
| C35 | Medium | Affordance | "Sign in instead" runs the same callback as "Get started" — advances to disclaimer, doesn't skip to auth | lib/features/onboarding/presentation/widgets/screens/offer_screen.dart:49-54 | CONFIRMED |
| C36 | Medium | Dead code | `backdate_session_sheet` is a second, divergent log-session flow with zero production callers | lib/progress/widgets/backdate_session_sheet.dart | CONFIRMED |
| C37 | Medium | Docs | `integration_test.md` documents robots/Patrol/4-shard CI that don't exist; two arch guides mandate contradictory layouts; splash "500ms" vs code 1000ms | docs/best_practices/integration_test.md:280-662; docs/ubiquitous-language.md:503 | CONFIRMED |
| C38 | Medium | Tests | Several tests assert on mocks / assert nothing / are misnamed (e.g. "returns new instance each time" pins a singleton) | test/core/utils/locator_test.dart:47-79; test/home/post_modal_review_trigger_test.dart | CONFIRMED |
| C39 | Medium | a11y | The disclaimer "I understand" gate is a bare `GestureDetector` — no checkbox role/state for screen readers | lib/features/onboarding/presentation/widgets/onboarding_checkbox.dart:26-31 | CONFIRMED |
| C40 | Low | Design system | Hardcoded colors/fonts/dates and a duplicated offline-banner constant bypass the kit | (multi-ref, see finding) | CONFIRMED |
| C41 | Low | Navigation | Pop races & missing dismiss guards (double-pop, stacked dialogs, setState-after-dispose) | (multi-ref, see finding) | PLAUSIBLE |
| C42 | Low | Branding | Template leftovers: web manifest/description, orphan `neurostack` URL scheme, CI-guard comment path, "counter" ARB | (multi-ref, see finding) | CONFIRMED |
| C43 | Low | Lifecycle | Leak/ordering edges: connectivity init/dispose race, undisposed notifiers on `reset()`, dead `AppLifecycleService.dispose`, premium-mixin late-init | (multi-ref, see finding) | PLAUSIBLE |
| C44 | Low | Tests | Fragility: real timers/wall-clock, day/week-boundary time deps, tautologies, dead helpers | (multi-ref, see finding) | CONFIRMED |
| C45 | Low | UX papercuts | Duration hint `0` (invalid), sub-44px tap targets/missing semantics, stuck completion spinner, cached failed future, contradictory Settings premium gating, `auth_view` bypasses the data-source seam | (multi-ref, see finding) | CONFIRMED |

Counts — **Critical 1, High 12, Medium 26, Low 6** (the 6 Low IDs cluster ~30 individual issues). Evidence: CONFIRMED 41, PLAUSIBLE 2 clusters, BLOCKED 0 (no unsafe/credentialed command was needed; see blind spots).

---

## 2. System map

**What it is.** `neurostack` — a Flutter app (iOS/Android/macOS/web) for tracking science-backed health "protocols". Passwordless email one-time-code auth (Supabase), a global protocol catalog, a personal "stack" of activated protocols (free tier ≤2), offline-first session logging, weekly progress grid, and a "Neurostack Pro" subscription via RevenueCat. Backend: Supabase (Postgres + RLS + one Edge Function). ~29k LOC `lib`, ~23k LOC tests, 15 SQL migrations.

**Startup (real path).** `lib/main.dart` → `ensureInitialized` → `configureUrlStrategy` → `runApp(_AppLifecycleObserver)`; the observer forwards `AppLifecycleState` to `AppLifecycleService` (guarded by `on ModuleNotFoundException` since DI may not be ready) and renders `StartupView`. `StartupView` runs a `ValueNotifier<AppState>` machine (`InitializingApp → {AppInitialized | OfflineNoUserState | AppInitializationError}`), scheduling `initializeApp()` in a post-frame callback so the splash paints first. `_doInitializeApp` races `_bootstrap()` against a 1000 ms `minSplashDuration`. `_bootstrap()` (startup_view_model.dart:164): init Supabase (idempotent completer) → SharedPreferences → `locator.registerMany(buildModules())` → PackageInfo → logging → onboarding store + guard → **RevenueCat `init()` before auth** (so `identify()` during rehydrate finds a configured SDK) → UserOrient/InAppReview (best-effort) → `AuthService.init()`.

**DI.** Hand-rolled `ModuleLocator` (`core/utils/locator.dart`): a `Map<Type,Module>` singleton; `registerMany` throws on duplicate type; `call<T>()` throws `ModuleNotFoundException`; `reset()` nulls instances + clears the map (used on retry/logout). No scoping/async/disposal — callers dispose manually in `StartupViewModel._disposeServices()`.

**Routing.** Custom router (`core/utils/navigation/`): `RouterService` holds a `ValueNotifier<List<RouteData>>` stack and implements three guards in `goTo/replace/replaceAll/replaceAllWithRoute` — unsupported → push `/404`; onboarding guard → `/onboarding`; auth guard (`requiresAuth && !isAuthenticated`) → persist intended route, redirect `/auth`. `AppRouterDelegate` maps the stack to `MaterialPage`s keyed by `hashCode`. 12 routes declared in `config/route_config.dart`; `matchRoute` supports `:param` (unused today).

**Auth.** `AuthService` owns a sealed `ValueNotifier<AuthState>` (AuthUnknown/Unauthenticated/Authenticating/AuthenticatedOnline/AuthenticatedOffline/OfflineNoUser). Sign-in = passwordless OTP: `signInWithOtp(email)` → typed code → `verifyOTP(OtpType.email)` → `onAuthStateChange(signedIn)` → `_rehydrateFromSession` → `UserBootstrapService.rehydrateFromRemote` (fetch `users`; on `User.NotFound` do a recovery upsert then re-fetch) → cache user, RevenueCat `identify`, post-auth nav (forceOnboarding → onboarding; else intended route or `/`). Offline falls back to `CachedUserStore` (SharedPreferences JSON).

**Domain (DDD-ish).** Aggregates `User` (stack, `subscriptionStatus`, onboarding; enforces protocol-limit + `canLogSession` off the **persisted** status), `Protocol` (INV-P1 ≥1 citation only in `create`, not `reconstitute`), `Session`/`SessionDraft` (INV-S2 not future, INV-S4 ≤7 days back). fpdart `Either<DomainFailure,_>`; repos map Postgrest codes → `DomainFailure`.

**Sessions (offline-first — the most robust subsystem).** `LogSessionUseCase`: load user → `canLogSession` → `SessionDraft.create` → `SessionRepository.create` (DB assigns UUID). `SessionLocalDataSource` keeps `pending_*`/`synced_*` SharedPreferences caches per user, self-healing on corrupt JSON. `SessionSyncService` pushes pending→remote on connectivity-online and lifecycle-resumed (concurrency guard, offline-mid-loop bail, remove-from-pending-on-success dedup). `listSessions` merges synced+pending (pending IDs namespaced `pending:`).

**Monetization (the crux).** RevenueCat is the *display* authority; the `revenuecat-webhook` Edge Function is the *only* writer of `users.subscription_status`. `RevenueCatClient` is platform-split (mobile SDK / web stub returning null) via conditional import. `RevenueCatService` holds `ValueNotifier<EntitlementSnapshot?>` (null = unknown/unavailable; `.none()` = authoritative), user-scoped by `appUserId==_identifiedUserId`, never clobbering known state with null. `SubscriptionStatusResolver.resolveEffectiveStatus(user, snapshot)`: snapshot null or wrong-user → fall back to DB status; else map snapshot → status. **The catch (see C3):** view models compute display/banner hints from effective status, but `User.activateProtocol`/`canLogSession` enforce off the persisted DB status — two inputs that agree only after the webhook lands.

**Backend.** Tables: `protocols` (bigint identity id), `research_citations` (FK→protocols cascade), `sessions` (UUID id since migration 3, FK→protocols + auth.users), `users` (uuid = auth.users.id, `subscription_status` text + CHECK, `protocol_ids` jsonb, webhook bookkeeping cols). `handle_new_user` trigger inserts a `free` users row (trial columns/cron added then fully removed in the RevenueCat wave). `apply_revenuecat_event` RPC: SECURITY DEFINER, service_role-only, idempotent (`rc_last_event_id`) + monotonic (`subscription_updated_at`). Edge function verifies a shared-secret Authorization header (`verify_jwt=false`), validates UUIDs, maps RC event types → status, returns 200 for recognized events.

**Key invariants (as intended).** DB `subscription_status` written only by the webhook RPC; free tier ≤2 protocols; RC snapshot authoritative only when `appUserId==user.id`; sessions not-future/≤7-days-back; webhook writes idempotent+monotonic; splash ≥1000 ms.

---

## 3. Coverage accounting

**Read fully, first-hand (main agent):** `main.dart`; startup (`startup_view`, `startup_view_model`, splash); DI (`locator`, `locator_config`, `route_config`); all of `navigation/` (router_service, router_delegate, best_router, route_data, route_information_parser, navigation_observable, navigation_intent_store, utils); auth (`auth_service`, `auth_state`, `user_bootstrap_service`, `cached_user_store`, `check_email_view_model`); `data_source_abstraction`, `data_source_init`, `app_environment`, `app_lifecycle_service`, `connectivity_service`, `auth_helpers`, `failure_helpers`, `supabase_error_mapper`, `date_time_extensions`; user (entity/enum/stack/dto/remote/repo); session (both use cases, sync_service, local/remote data sources, repo, session/draft/duration entities, session/insert DTOs, `log_session_view_model` excerpt, `log_session_modal`); protocol (repo/remote/cached_store/dto/entity/category+evidence enums/research_citation VO); all of `paywall/` (revenuecat_service, client + mobile + stub + factories, entitlement_snapshot, entitlement, subscription_status_resolver, trial_expiry_policy, trial_reminder_service, trial_expiration_decision_store, paywall_constants, paywall_view_model); `home_view_model`, `library_view_model`, `progress_view_model`, `home_bottom_tab_coordinator`, `library_stats`. All 15 migrations + RPC + edge function + `config.toml` (root + function) + `seed.sql` + `magic-link.html`.
**Read via 4 parallel sub-agents (adversarial briefs, file:line evidence required):** (a) UI layer — `core/ui/**`, home/library/progress/settings views+widgets, onboarding, offline, not_found, paywall widgets+view, auth presentation, session presentation (81 files); (b) core utils + platform — abstractions, `http/**`, `in_app_review/**`, `internal_notification/**`, l10n (ARB parity), userorient, android/ios/macos/web shells, `tool/**`, analysis_options (74 files); (c) `test/` + `integration_test/` (112 files, ~23k LOC); (d) `docs/**` + root strays + ADR/spec drift (~74 doc files). Headline sub-agent findings re-verified first-hand.
**Excluded (why):** `build/`, `.dart_tool/`, `node_modules/`, generated iOS/macOS/Android + Pods, `.flow/` (508 tracker-state files — process artifact), `time-profiler.trace`, `*.g.dart`/`*.freezed.dart` (generated; confirmed present+committed, not audited line-by-line), `.sandcastle/`.
**Commands run (all read-only / throwaway):** `git ls-files`, `wc -l`, targeted `grep`; `flutter analyze --no-pub` → **0 issues**; `flutter test --exclude-tags=golden` → **1001 passed**; `dart format --output=none --set-exit-if-changed <lib non-generated>` → **exit 1, 11 files** (C23); `bash tool/ci/check_adaptive_white_tokens.sh` → OK. No mutating/publishing/deploy/migration/credentialed command was run. Supabase MCP tools were available but deliberately **not** used (would touch the live project).
**Blind spots:** (1) No live DB — RLS/webhook findings are from migration SQL, not a running instance (a live check would need `psql`/service-role creds — BLOCKED by the safety boundary; the exact check I would run: `SELECT polname,cmd,roles FROM pg_policies WHERE tablename IN ('protocols','research_citations');`). (2) RevenueCat dashboard config (entitlement/product IDs, webhook secret) unverifiable — code assumes exact strings. (3) No golden tests exist anywhere despite the tagged CI exclusion → visual regressions uncovered. (4) `integration_test/` is never executed here or in CI. (5) Generated code assumed correct from green analyze/test.

---

## 4. Findings by hunt category (severity order)

Findings are grouped by the 8 hunt categories below (a finding's primary category; cross-cutting ones are noted in parentheses). The **detailed blocks that follow are in severity order** and carry the stable IDs used everywhere else — each with ID, file:line, one-line issue, concrete scenario, evidence label, and recommended direction. Read the index for a category view; read the blocks in order for severity.

1. **Correctness** — C5, C14, C31 (also C3, C4, C22)
2. **Alternative / unintended paths** — C4, C29, C41
3. **Incoherences** (dead code, duplicated sources of truth, drift) — C3, C17, C18, C19, C22, C30, C33, C34, C36, C40, C42
4. **Affordance mismatches** — C25, C26, C28, C35, C45
5. **Missing functionality** (validation, observability, feedback, a11y) — C20, C27, C39
6. **Boundary & safety** (authz, injection, resource leaks, leaky abstractions) — C1, C15, C21, C43
7. **Documentation** — C11, C12, C37
8. **Developer experience** (build/run/test, CI, config, toolchain) — C2, C6, C7, C8, C9, C10, C13, C16, C23, C24, C32, C38, C44

### C1 — [Critical] Any authenticated user can write the shared protocol catalog (RLS DROPs miss)
`supabase/migrations/20251204192228_initial_schema.sql:149-164` creates `"Protocols are insertable by authenticated users"`, `"Protocols are updatable by authenticated users"`, and `"Citations are insertable by authenticated users"` (all `with check/using (auth.role()='authenticated')`). The follow-up migration means to lock writes to admins (`…:76` comment "admin-only via service role") but its DROPs name **non-existent** policies: `drop policy if exists "Users can insert protocols"` / `"Users can update protocols"` / `"Users can insert citations"` (`20251230160000_auth_trigger_and_rls.sql:77-91`). Names don't match → the DROPs are no-ops and no later migration removes the real ones (verified across all 15 migrations).
**Scenario (source → boundary → sink → exploit):** signups are open (`enable_signup=true`), so any user who requests an email code holds an `authenticated` JWT + the shipped publishable key. They call `PATCH /rest/v1/protocols?id=eq.<n>` or `POST /rest/v1/protocols` / `.../research_citations` and (a) deface/alter any global protocol, (b) inject citation text shown to all users (rendered as plain text via `fullCitation`, protocol_detail_sheet.dart:214 — phishing text, not a live link), or (c) **chain with C14**: insert one protocol whose `category`/`evidence_level` isn't a valid Dart enum, or an empty required field → `ProtocolRepositoryImpl.list` returns `Left` on that row → the Library screen becomes an error state **for every user** = an authenticated attacker can take the core catalog offline.
**Evidence:** CONFIRMED (SQL source; no live DB). **Direction:** rename the DROPs to the real policy names (or `DROP POLICY` unconditionally + recreate admin-only), keep read policies, and add a regression that asserts `pg_policies` has no `authenticated` INSERT/UPDATE on `protocols`/`research_citations`.

### C2 — [High] CI never runs on the branches anyone uses
`.github/workflows/test.yaml:4-9` triggers only on `push`/`pull_request` to `main`. The repo's default branch is `develop`; only `develop` and `master` exist (no `main`) and recent history is merges into `develop`. So lint/analyze/format/tests fire only via manual `workflow_dispatch`.
**Scenario:** every PR into `develop` (all recent work) is merged with **no automated gate** — the green suite is only ever "whatever a developer last ran locally." This is the meta-root-cause that let C23 (format drift), C9 (Flutter Kit), and the test-quality issues persist. Two sub-agents independently rated this Critical; I hold it at High because it causes no direct runtime harm — but it is the highest-leverage fix here.
**Evidence:** CONFIRMED (first-hand: `git branch -a`, workflow triggers). **Direction:** trigger on `develop` (and `master`/release branches) or `branches: ['**']`; make the check required.

### C3 — [High] Entitlement enforcement uses stale DB status; UI uses RevenueCat — they diverge
`SubscriptionStatusResolver.resolveEffectiveStatus` makes RevenueCat authoritative for **display** (Home/Library banners, card lock state), falling back to DB. But **enforcement** — `User.activateProtocol` (user.dart:120-124) and `User.canLogSession` (user.dart:250-255) — reads `subscriptionStatus.protocolLimit`, i.e. the **persisted DB column**, which is written only by the async webhook.
**Scenario A (just subscribed):** user buys Pro → RC `CustomerInfo` flips to premium instantly → effective status = premium → Library shows all cards "available". But until the `INITIAL_PURCHASE` webhook lands and the client re-`getById`s, `user.subscriptionStatus` is still `free`, so tapping a 3rd protocol → `activateProtocol` → `protocolLimitReached` → **bounced back to the paywall they just paid on**.
**Scenario B (churned):** subscription lapses; RC says none → effective = free/expired → cards show locked. But if the `EXPIRATION` webhook hasn't landed (or was dropped), `user.subscriptionStatus` still says `premiumMonthly` → `activateProtocol`/`canLogSession` still grant **unlimited** access. RC being "the authority" is cosmetic for these paths.
**Evidence:** CONFIRMED (code). **Direction:** feed the resolved effective status (or `Entitlement.of(user,snapshot)`, which already exists but isn't wired) into the aggregate's limit checks so display and enforcement share one input.

### C4 — [High] Log-session sheet dismissible mid-submit → duplicate session
`showLogSessionModal` opens `showModalBottomSheet` with **no** `isDismissible:false` / `enableDrag:false` / `PopScope` (log_session_modal.dart:64); only the X button is disabled while submitting. In `LogSessionViewModel._submit`, the pending session is persisted at `:251` and sync fired at `:269`, then `if (_isDisposed) return;` at `:281` guards the success transition.
**Scenario:** user taps "Log Session" → during the spinner, swipes the sheet down → the sheet closes and disposes the VM → the write at `:251` still completes and syncs, but `LogSessionSuccess` (and thus `onSessionLogged`) never fires → no success toast, Home/Progress still show "not logged" → user logs again → **two identical sessions persisted and synced**.
**Evidence:** CONFIRMED (traced). **Direction:** make the sheet non-dismissible while `isSubmitting` (PopScope + `isDismissible/enableDrag:false`), or move the success callback before the dispose-sensitive path / make it idempotent per draft.

### C5 — [High] Remote date-range queries use zone-less local timestamps against `timestamptz`
`SessionRemoteDataSource.getSessions` sends `from.toIso8601String()` / `to.toIso8601String()` (`:40,:44`). Callers pass **local** `DateTime`s (`now.startOfDay/endOfDay` in home_view_model.dart:491-492; `now.weekStart/weekEnd` in progress_view_model.dart:152-153). A local `DateTime.toIso8601String()` has **no** offset suffix, so Postgres casts it against the `timestamptz` column in the DB session zone (UTC on Supabase). Writes, by contrast, are correctly `.toUtc()`-normalized (session_dto.dart:101, session_insert_dto.dart:34).
**Scenario:** a UTC+2 (Swedish — the target market per `site_url` + `sv` locale) user's "today" window is shifted 2 h; sessions completed 00:00–02:00 local are excluded from the remote fetch, so on a fresh install / second device the "logged today" card and week grid are wrong until a full sync backfills the local cache (DST makes it worse). Masked on the writing device because local-cache filtering is instant-based and correct.
**Evidence:** CONFIRMED (code; independently found by two readers). **Direction:** send `from.toUtc().toIso8601String()` (or explicit `Z`) for range bounds.

### C6 — [High] Android `applicationId = com.example.neurostack`
`android/app/build.gradle.kts:10,24` keep the template `com.example.*` id/namespace while `env/env.json` ships `PLAY_STORE_PACKAGE_NAME = app.getneurostack.neurostack`. Play rejects `com.example.*`; the App Link `android:host="getneurostack.app" autoVerify="true"` (AndroidManifest.xml:38) can never verify without a matching `assetlinks.json`; `RateAppViewModel`'s Play fallback URL (rate_app_view_model.dart:119-121) and `in_app_review` both target a package that isn't the installed app.
**Evidence:** CONFIRMED. **Direction:** set the real applicationId/namespace before any Android release; align `assetlinks.json` fingerprints.

### C7 — [High] Android release is debug-signed
`android/app/build.gradle.kts:36`: `signingConfig = signingConfigs.getByName("debug")` inside `buildTypes.release`, with the template TODO intact. Debug-signed AABs are rejected by Play and break App Link fingerprint verification.
**Evidence:** CONFIRMED. **Direction:** add a real release keystore + signing config.

### C8 — [High] macOS release build cannot use the network
`macos/Runner/Release.entitlements:5-6` contains only `com.apple.security.app-sandbox=true`. `com.apple.security.network.client` is present in `DebugProfile.entitlements` but **absent** from Release. macOS is an intended target (`RevenueCatService._platformName` handles it; `AppInfo.xcconfig` exists).
**Scenario:** a sandboxed macOS **release** build cannot open outgoing sockets → Supabase init/auth/RevenueCat all fail with opaque errors, while debug builds work — a classic "works on my machine, broken in release" trap.
**Evidence:** CONFIRMED. **Direction:** add `network.client` to Release.entitlements.

### C9 — [High] The app is named "Flutter Kit"
`ios/Runner/Info.plist:9-10` sets `CFBundleDisplayName = Flutter Kit`; `app_en.arb:3`/`app_sv.arb:3` set `appName = "Flutter Kit"`, which feeds `onGenerateTitle` (startup_view.dart:64,83) → the web tab/window title. So the iOS home-screen name and web title both read "Flutter Kit" (Android label is lowercase `neurostack`).
**Evidence:** CONFIRMED. **Direction:** set the product name per platform + fix the ARB `appName`.

### C10 — [High] The integration tests — the only behavioral pins for monetization/nav — run nowhere
`integration_test/` needs `flutter test integration_test` + a device binding (`IntegrationTestWidgetsFlutterBinding`, paywall_flow_test.dart:25). CI runs only `flutter test --exclude-tags=golden`, which does not include that directory, and no workflow/script invokes it. These 17 tests are the only coverage of: the trial-expired modal actually appearing on a trial→free transition with the decision store, trial-reminder appear/throttle in the UI, purchase/restore through the real `RevenueCatService`+`HomeViewModel` wiring, and signed-in→Home navigation. They compile but never execute.
**Evidence:** CONFIRMED. **Direction:** add an integration-test job (emulator/simulator) or at least run them locally in `verify.sh`; wire it into C2's fix.

### C11 — [High] Superseded magic-link auth is documented as current; functional specs cite code that doesn't exist
Ground truth: ADR-0001 chose a one-time **code**, and the code matches it (`signInWithOtp` + `verifyOTP(OtpType.email)`; `{{ .Token }}` template). But `docs/specs/20260113143000_spec_auth.md` still documents "magic link", `auth_callback_view.dart`, `emailRedirectTo`, `resendMagicLink()`, and a `/auth/callback` route — none of which exist — with status "Documented" and no deprecation banner, and `docs/README.md:59` bills it as current. `screen-functional-specifications.md` references routes `/home`, `/onboarding/1`, and a method `updateSubscriptionStatus(...)` (`:62,:595`) that contradict both `route_config.dart` and Design Principle #3 (webhook-only writer). Screen-prompts 09/10 still say "tap the link / Resend link".
**Scenario:** an agent or newcomer implementing "the documented auth flow" builds the abandoned, known-broken PKCE magic-link path.
**Evidence:** CONFIRMED. **Direction:** add superseded banners pointing to ADR-0001; delete/rewrite the stale spec and functional-spec sections.

### C12 — [High] Agent-facing docs start every session with dead pointers
`AGENTS.md` (symlinked as `CLAUDE.md`, loaded into every agent session) says "See `docs/agents/backlog.md`" (`:5`) — absent; the real file is `docs/agents/issue-tracker.md`. It also says "Single-context layout: `CONTEXT.md` at the repo root" (`:13`) — there is no `CONTEXT.md`; `docs/agents/domain.md` itself says `ubiquitous-language.md` plays that role. `docs/agents/domain.md` further tells agents ADRs "don't exist yet" when `docs/adr/0001` is the single most load-bearing decision.
**Evidence:** CONFIRMED. **Direction:** fix the three references (or add the files/symlinks).

### C13 — [High] Critical paths have no unit coverage
Despite 1001 green tests, there is **no** unit test for: RouterService's auth-redirect guard or `replaceAll([])` (grep `requiresAuth` / `replaceAll(\[\])` in `test/` → 0 hits; only the onboarding guard is tested); `AuthService` rehydrate-failure, `tokenRefreshed`, offline↔online re-rehydrate, or intended-route consumption (the 194-line test pins only two `clearCache` calls); `RevenueCatClientMobile._mapCustomerInfo` (the actual SDK→domain translation where trial/grace/expired are derived — every resolver test starts from hand-built snapshots); `SessionRepositoryImpl`/`UserRepositoryImpl` + all three remote data sources (query building + error mapping); the `revenuecat-webhook` function (zero tests, though it's the only DB writer); and the free-tier-over-limit `tooManyActiveProtocols` branch on the real `User` entity.
**Scenario:** a regression that sends unauthenticated users into authed routes, mismaps a grace-period `CustomerInfo`, or breaks the webhook's status mapping ships green.
**Evidence:** CONFIRMED (grep-verified negatives). **Direction:** add focused tests at these seams; prioritize the RC mapping + RouterService guards + webhook.

### C14 — [Medium] One malformed row fails the whole collection
`ProtocolRepositoryImpl.list` (`:60-65`), `UserRepositoryImpl.list`, and `SessionRepositoryImpl.list` return `Left` on the first DTO whose `toDomain()` fails, discarding all good rows. `SessionLocalDataSource` already does the opposite (skip-and-log) for its cache.
**Scenario:** a single protocol row with a bad enum or empty description turns the Library into an error screen for everyone (and see C1 for how an attacker introduces such a row).
**Evidence:** CONFIRMED. **Direction:** skip-and-log invalid rows so one poison row degrades gracefully.

### C15 — [Medium] RevenueCat SDK listener leaks on every logout/retry
`RevenueCatClientMobile._setupListener` calls `Purchases.addCustomerInfoUpdateListener` (`:143`) and there is **no** `removeCustomerInfoUpdateListener` anywhere, and no `dispose` on the client. The RC modules are `lazy:true` (locator_config.dart:72-79), so `locator.reset()` (triggered by the error/offline retry **and by every `logout()` → `restartApp()`**) discards and rebuilds the client → a new global SDK listener is registered each time, the old one never removed — directly contradicting the DI comment "SINGLETONS … to prevent duplicate SDK listeners" (`:70`).
**Scenario:** after N logout/login cycles, N duplicate `CustomerInfo` listeners fire on every entitlement change, each mapping `CustomerInfo` and pushing to an orphaned controller.
**Evidence:** CONFIRMED. **Direction:** give the mobile client a `dispose` that removes its listener + closes the controller, and call it from `RevenueCatService.dispose`; or make the client a true process-singleton not rebuilt on reset.

### C16 — [Medium] Missing Supabase env keys fail silently
`initDataSource` reads `String.fromEnvironment('SUPABASE_URL', defaultValue:'')` and `SUPABASE_PUBLISHABLE_KEY` with empty defaults (`:29-37`). Running without `--dart-define-from-file=env/env.json` (plain `flutter run`, CI, `flutter test`) constructs a Supabase client on empty strings — no fail-fast; the app boots and dies at the first network call with an unrelated-looking error. (`REVENUECAT/USERORIENT/APP_STORE_ID` warn-and-disable, which is fine; only Supabase is load-bearing.)
**Evidence:** CONFIRMED. **Direction:** assert non-empty URL/key at startup and surface a clear "config missing" error.

### C17 — [Medium] The free-tier limit "2" is reimplemented in ≥8 places
Source of truth is `SubscriptionStatus.free.protocolLimit` (subscription_status.dart:10), yet the number/`2` and "limited to 2" copy are hardcoded in `protocol_selection_modal.dart:8` (`_selectionLimit=2`, which drives the modal's hard keep-count), `trial_expired_modal.dart:170,175,345,383`, `protocol_detail_sheet.dart:475`, `log_session_view.dart:787`, and `home_view*.dart` (`… ?? 2` dead fallback). Changing the enum silently desyncs the selection modal and five user-facing strings.
**Evidence:** CONFIRMED. **Direction:** derive all of them from the enum (and localize the strings — C18).

### C18 — [Medium] The l10n system is bypassed almost everywhere
Full l10n infra exists (`app_en.arb` + `app_sv.arb`, keys identical 29/29, `context.translate.X` used correctly in auth/startup/404 — 26 usages). Every other screen hardcodes English: Home ('Your Stack', 'Log Session', 'Payment Issue'), Library ('Protocol Library', all of `library_ui.dart`), Progress ('This Week'; day letters `['M','T',…]` while the dates beside them *are* localized), Settings, onboarding, offline, paywall widgets, session modal, tab labels, `error_state_view`.
**Scenario:** a Swedish user gets a Swedish auth flow and an otherwise-English app.
**Evidence:** CONFIRMED. **Direction:** route user-facing strings through `translate`; add a lint/grep gate.

### C19 — [Medium] The entire HTTP stack is dead code
`Module<HttpAbstraction>` is registered (locator_config.dart:114-123) but `locator<HttpAbstraction>()` appears nowhere in `lib/`/`test/`; `HttpAbstraction`, `LoggingInterceptor`, `http_native.dart`, `http_web.dart` are never executed, and the `http` / `cronet_http` / `cupertino_http` deps exist only for them. Latent traps if ever wired: `http_native.dart` builds a `CronetEngine` with no fallback (throws on Android without Play Services) and sets userAgent `'Flutter Kit'`.
**Evidence:** CONFIRMED. **Direction:** delete the stack + deps, or wire it and drop the raw Supabase client usage.

### C20 — [Medium] No release logging sink; errors/stacks dropped even in debug
`LoggingAbstraction` prints only in `!kReleaseMode` and only when `onLogs` is set — but the sole call site (`initializeLogging()`) passes no `onLogs`, so in release every `severe`/`warning` (auth/RC/sync failures) is silently discarded; there is no crash/telemetry sink. `_printLog` also prints only `record.message`, discarding the `record.error`/`stackTrace` callers pass, so even the debug console never shows the exception.
**Evidence:** CONFIRMED. **Direction:** add a release sink (at least device console / crash reporter) and include error+stack in output.

### C21 — [Medium] Raw database errors reach end users
`mapPostgrestError`'s fallback arm returns `message: '${e.code}: ${e.message}'` (with `e.code` possibly null → `"null: …"`), and `DomainFailure.message` is rendered user-facing (home_view_model.dart:538 `_setError(failure.message)`, failure_helpers.dart:15). Any unmapped Postgrest error shows internal SQL/PostgREST text in a banner/toast.
**Evidence:** CONFIRMED. **Direction:** map to a generic user message; log the raw detail.

### C22 — [Medium] `premiumLifetime` exists everywhere except the Dart enum
The DB CHECK (`20260123092258…:19-21`), the RPC allow-list, and the webhook's TS `SubscriptionStatus` type all include `premiumLifetime`; the Dart `SubscriptionStatus` enum does not. `UserDto.toDomain` parses via `SubscriptionStatus.values.byName(name)`, which throws on an unknown value → `Dto.InvalidSubscriptionStatus` → user load fails → auth rehydrate fails.
**Scenario:** the moment anything writes `premiumLifetime` (e.g. wiring up the currently-ignored `NON_RENEWING_PURCHASE`), affected clients can't load their user and are effectively locked out. Dormant today (nothing writes it).
**Evidence:** CONFIRMED. **Direction:** add the enum value (map to a real tier) or remove it from the DB/RPC/TS side; decide deliberately.

### C23 — [Medium] Local formatter disagrees with the committed code; CI pins an older Flutter
`dart format --output=none --set-exit-if-changed` over the CI file set exits 1 with **11 files** it would reformat (e.g. `app_theme.dart:51` — the local Flutter 3.35.3 formatter collapses a multi-line ternary the committed code keeps split). CI pins Flutter **3.32.0** (test.yaml:16). So a contributor on a current toolchain fights the formatter, and — because CI never runs (C2) — nothing reconciles the two.
**Evidence:** CONFIRMED (measured; file restored, tree clean). **Direction:** pin the Dart/Flutter version for contributors (mise/`.tool-versions` already present — align CI to it) and reformat once.

### C24 — [Medium] Three different bundle identifiers across platforms
iOS `app.getneurostack.neurostack` (project.pbxproj:503), macOS `com.hungrimind.neurostack` + `Copyright © 2025 com.hungrimind` (AppInfo.xcconfig — the template author's id), Android `com.example.neurostack`. RevenueCat/App Store/keychain identities won't line up across platforms.
**Evidence:** CONFIRMED. **Direction:** pick one reverse-DNS id and apply consistently.

### C25 — [Medium] Library "Log Session" is a dead-end
`LibraryViewModel.onLogSession` runs the real `canLogSession` eligibility check and then, on success, only shows `ToastEventInfo('Log session flow coming soon')` (library_view_model.dart:194-196). It's wired to a real "Log Session" button in the protocol-detail sheet (protocol_detail_sheet.dart:440 ← library_view.dart:322). Home's log-session opens the actual modal; Library's silently does nothing.
**Evidence:** CONFIRMED. **Direction:** open `showLogSessionModal` here too (or remove the button).

### C26 — [Medium] `/settings/contact` is an empty stub but linked
`ContactView` (contact_view.dart:29-44) renders a back button + `Text('Contact Us')` — no contact info/form/mailto — yet it's a registered route reachable from the "Contact Us" tile.
**Evidence:** CONFIRMED. **Direction:** implement it or hide the entry point.

### C27 — [Medium] "Restore Purchases" gives no busy feedback
`restorePurchases` guards re-entry with a private `_isRestoring` but exposes no notifier; the tile shows no spinner/disabled state during the multi-second RC call (settings_view_model.dart:200-241).
**Evidence:** CONFIRMED. **Direction:** expose a busy state and disable the tile while running.

### C28 — [Medium] Ineligible log-session view has no path to the paywall
`_IneligibleView` says "Upgrade Required / Free tier is limited to 2 active protocols" but its only action is a "Got it" that closes (log_session_view.dart:778-808) — contradicting `log_session_state.dart:54` ("The UI should show an upgrade prompt"). The user hits the gate with no way to convert.
**Evidence:** CONFIRMED. **Direction:** add a "Go Pro" CTA to the paywall.

### C29 — [Medium] Staggered fade-in blanks list items for ~2 s on re-scroll
`StaggeredFadeIn` delays `100ms * index` (staggered_fade_in.dart:27); Library assigns a cumulative `staggerIndex++` across sections (library_view.dart:210) so the last card's index ≈ 21 → ~2.1 s. Sliver children lose state off-screen, so scrolling away and back **replays** the full delay — bottom cards render blank for ~2 s every time.
**Evidence:** CONFIRMED. **Direction:** cap the stagger, or animate only on first build (not on every viewport re-entry).

### C30 — [Medium] Tabs are full reloads; the scroll-restore mechanism is dead
Tab taps do `replaceAll([Path('/library')])` (home_bottom_tab_coordinator.dart:19-28) and pages are keyed by `hashCode` (router_delegate.dart:29), so each switch destroys the prior tab's State → refetch, stagger replays, scroll resets. Consequently the `PageStorageKey('library-scroll')`/`'settings-scroll'` (library_view.dart:94, settings_view.dart:70) are dead (the bucket dies with the route), and Home/Progress don't even have them.
**Evidence:** CONFIRMED. **Direction:** use an `IndexedStack`/keep-alive shell for the tab surfaces, or a stable page key.

### C31 — [Medium] "Current streak" is anchored to the latest session, not today
`_calculateStreak` starts `streak=1; current=days.first` (most recent session day) and walks backward (library_stats.dart:42-53). It never checks whether the most recent session is today/yesterday.
**Scenario:** sessions on Jun 1–3, nothing since; on Jul 9 the detail sheet shows "Current streak: 3 days" (protocol_detail_sheet.dart:321). Also renders "1 days" (no pluralization).
**Evidence:** CONFIRMED. **Direction:** return 0 unless the streak includes today (or yesterday); pluralize.

### C32 — [Medium] `verify.sh` checks a different predicate than CI
`tool/verify.sh:14-20` runs `dart format` over **all** files (including generated `*.freezed.dart`/`*.g.dart`/`app_localizations*` that CI excludes), `flutter analyze --fatal-infos` (CI is plain `analyze`), and `flutter test` (CI excludes golden), and never runs `check_adaptive_white_tokens.sh` (CI does). Local-green and CI-green are different predicates in both directions.
**Evidence:** CONFIRMED. **Direction:** make `verify.sh` mirror the workflow (or vice-versa) once C2 is fixed.

### C33 — [Medium] Domain-event machinery is decorative
`AggregateRootMixin.popDomainEvents`/`clearDomainEvents`/`domainEvents` have no callers (aggregate_root.dart:14-22). Events are raised (user/protocol/session) and the only consumer is a `hasDomainEvents` dedupe guard (log_session_use_case.dart:91) — they're never dispatched or cleared. `DomainEvent.occurredAt = DateTime.now()` is local time if ever persisted.
**Evidence:** CONFIRMED. **Direction:** either wire a dispatcher or delete the machinery.

### C34 — [Medium] `APP_ENV` is never set
`AppEnvironment.tag` defaults to `'prod'` and `APP_ENV` appears in no env file / launch config / workflow, so every dev log line reads `env=prod` (auth_service.dart:247,269…) and `AppEnvironment.isDev` has no callers.
**Evidence:** CONFIRMED. **Direction:** set `APP_ENV` per build flavor or remove the abstraction.

### C35 — [Medium] "Sign in instead" doesn't
`offer_screen.dart:49-54` wires "Sign in instead" to `widget.onNext` — the same callback as "Get started" — so a returning user is pushed through the disclaimer screen exactly like a new user instead of jumping to auth.
**Evidence:** CONFIRMED. **Direction:** route it to `/auth`.

### C36 — [Medium] `backdate_session_sheet` is a dead, divergent duplicate
`showBackdateSessionSheet` has no production callers (only a brightness test greps it); ProgressView now opens `showLogSessionModal` for missed cells. It's a second "log a session for day X" implementation (auto-pops on failure, no duration/notes) left to rot.
**Evidence:** CONFIRMED. **Direction:** delete it.

### C37 — [Medium] Test/architecture docs describe things that don't exist
`integration_test.md` documents a robots pattern (`integration_test/robots/…`), Patrol native testing, a `createTestView()` helper, and a 4-shard CI matrix — none exist (no `robots/`, `patrol` not in pubspec, one CI job). Two architecture guides mandate **contradictory** layouts (`lib/<feature>/models|services|viewmodels|views` vs `lib/features/<x>/domain|data|presentation`), and the shipped tree matches neither (hybrid). `ubiquitous-language.md:503` says splash floor 500 ms; code is 1000 ms. `plan_trial_expiration_cron_job.md` has no superseded banner though the cron was fully removed.
**Evidence:** CONFIRMED. **Direction:** prune/relabel; pick one architecture and document the hybrid as intended.

### C38 — [Medium] Several tests pin mocks or nothing, and one is misnamed
`locator_test.dart:47-79` "Register and retrieve non-lazy module returns new instance each time" actually asserts singleton behavior (comment says "factory" — the opposite of the impl). `post_modal_review_trigger_test.dart` defines the orchestration as test-local closures and verifies a mock — deleting the production pattern keeps it green (and `:106-122` asserts a never-assigned var is null). `session_sync_service_test.dart:95-126` "withoutDuplicateListeners"/dispose tests assert nothing. `premium_aware_view_model_mixin_test.dart:333-350` never calls the method it names.
**Evidence:** CONFIRMED. **Direction:** rename to match behavior; assert observable outcomes, not mock calls.

### C39 — [Medium] The disclaimer gate isn't screen-reader accessible
`OnboardingCheckbox` (`:26-31`) is a bare `GestureDetector` with no `Semantics(checked:)`/`MergeSemantics`; a screen reader hears plain "I understand" with no checkbox role/state — on the one screen that blocks progression.
**Evidence:** CONFIRMED. **Direction:** wrap in a semantic checkbox.

### C40 — [Low] Design-system bypasses (cluster)
Raw hex one bit off from a token (`protocol_detail_sheet.dart:430` `Color(0xFFB71C1C)` vs `KitColors.red700 0xFFB91C1C`; dark-mode destructive uses amber `warning` despite a red palette); `_modalBackgroundColor = Color(0xFF030303)` duplicates `KitColors.background` (protocol_selection_modal.dart:9; trial_expired_modal.dart:38); raw `Colors.white`/`Colors.white.withValues(...)` instead of the whiteXX scale (onboarding_progress_dots.dart:37; protocol_selection_modal.dart:143-404); `GoogleFonts.jetBrainsMono` vs the theme's `robotoMono` (protocol_selection_modal.dart:168,325); hand-rolled English month abbreviations beside `intl` elsewhere (protocol_detail_sheet.dart:338-355); the `'Offline mode'` banner constant defined three times (library_view.dart:30, progress_view.dart:35, home_view_model.dart:732). **CONFIRMED.**

### C41 — [Low] Navigation pop races & dismiss-guard gaps (cluster)
`log_session_view.dart:106` pops from a state listener with no `ModalRoute.isCurrent` guard (double-dismiss can pop the underlying route); `trial_expired_modal.dart:189-197`, `protocol_selection_modal.dart:210`, and the Library remove dialog pop from plain InkWells (two-finger double-pop); `home_view.dart:279-322` schedules independent post-frame dialogs that can stack; `progress_view.dart:311` → `progress_view_model.dart:123` sets `state.value` with no `_isDisposed`/`mounted` guard (unlike its siblings) → debug assert if torn down mid-modal. **PLAUSIBLE** (all require precise timing/multi-touch).

### C42 — [Low] Template/branding leftovers (cluster)
`web/index.html:21` + `web/manifest.json:6-8` still "A new Flutter project." / Flutter-blue theme; iOS registers a custom URL scheme `neurostack` with no Android counterpart and no consumer (auth is OTP, no deep link); `check_adaptive_white_tokens.sh:31-32` comment references a non-existent `lib/offline/`; `app_en.arb`/`app_sv.arb` keep a template `counter` string and a mixed-language `authCompletingSignIn`; `docs/README.md` is still the stock Hungrimind boilerplate. **CONFIRMED.**

### C43 — [Low] Lifecycle / leak edges (cluster)
`ConnectivityService.init/dispose` could race if `dispose()` runs during the awaited `checkConnectivity()` (guarded today only by call order — and connectivity ownership living inside `AuthService.init` is itself an incoherence); `locator.reset()` nulls instances without disposing and `_disposeServices` misses `AppLifecycleService`/`NotifyService`/`RouterService` notifiers (GC-recoverable), while `AppLifecycleService.dispose` has no callers; `premium_aware_view_model_mixin` uses `late final` fields that throw on double-init or pre-init listener fire; `auth_helpers.resolveCachedUser` returns the previous user when unauthenticated. **PLAUSIBLE** (guarded by current call order).

### C44 — [Low] Test fragility (cluster)
Real timers / wall-clock assertions (session_sync_service_test.dart:169; revenuecat_service_test.dart:116-133 asserts across a 10ms-vs-50ms window; log_session_view_model_test.dart:596); day/week-boundary time-dependent tests (log_session_view_model_test.dart:151-199, progress_view_model_test.dart:392-530); tautologies (entitlement_snapshot_test.dart:265-296, contrast_ratio_test.dart:122-130, app_grid_background_test.dart:294-323); dead helpers (`integration_test/mocks/mock_auth_states.dart`, unused `pump_helpers`); misleading factory `createExpiredTrialOverLimit` (no "expired" is representable). **CONFIRMED.**

### C45 — [Low] UX papercuts & minor incoherences (cluster)
Duration field `hintText:'0'` while 0 fails validation (log_session_view.dart:496); sub-44px tap targets / missing button-and-selected semantics (home_empty_state.dart:43, home_bottom_nav.dart:90, library_protocol_card `_Badge`); `_CompletionState` "Completing sign-in…" has no timeout/fallback if post-auth nav never fires (check_email_view.dart:461); `protocol_detail_sheet.dart:41` caches a failed stats future forever (no retry until reopened); Settings shows a trial user both the "Unlock All Protocols" banner (`!isPremium`) and "Manage Subscription" (`canAccessPremium`) (settings_view.dart:102,114); `trial_reminder_alert.dart:10` doc says "Trial expires tomorrow" but renders "Your trial ends soon"; the in-app-review index can fire on consecutive sessions (in_app_review_service.dart:105-122); `auth_view.dart:351` calls `Supabase.instance.client.auth` directly, bypassing the `DataSourceAbstraction` seam every other caller uses; `seed.sql` ships test data ("Deprecated Protocol", "Test Author") that would pollute any DB it's `db reset` against; `endOfDay`'s `microseconds:1` subtraction is a no-op on Flutter web (dart2js ms precision) so `weekEnd`/`endOfDay` land exactly on the next boundary. **CONFIRMED.**

---

## 5. Design tensions (structural — the approach, not a line)

**DT1 — Two sources of truth for entitlement, reconciled only by an async webhook; enforcement reads one, UI reads the other.** (See C3.) `users.subscription_status` (DB, webhook-only) and the RC `EntitlementSnapshot` are two authorities for the same fact. Display/gating hints use RC-effective status; domain enforcement uses the persisted DB column. The `Entitlement.of(user, snapshot)` seam that would unify them exists but isn't wired into the aggregate's guards. **Alternative:** pass the resolved effective status into `User.activateProtocol`/`canLogSession`, or make the client treat the RC snapshot as authoritative for enforcement and stop gating on the DB column.

**DT2 — A hand-rolled DI locator plus `reset()` fights the "app-lifetime singleton" intent.** `ModuleLocator` has no lifetime/scope/disposal; `reset()` tears down and rebuilds the whole graph on every retry *and every logout*, re-`configure`-ing RevenueCat and leaking a global SDK listener (C15), and forcing defensive `on ModuleNotFoundException` (main.dart:47) plus manual dispose ordering. **Alternative:** a container with explicit singleton-vs-scoped lifetimes + disposal, or a "soft reset" that re-runs only the failed bootstrap step.

**DT3 — Collections fail closed on one bad row.** (C14.) `list()` Lefts the whole result on the first invalid DTO; combined with a writable shared `protocols` table (C1) this is a global-outage primitive. **Alternative:** skip-and-log invalid rows (as the local session cache already does).

**DT4 — "MVVM+DDD" is applied to half the tree.** `features/{auth,onboarding,protocol,session,user}` are DDD; `{home,library,progress,settings,paywall,startup,not_found}` are flat root modules (paywall/progress partial). The two architecture guides mandate two *different* layouts and neither matches the shipped hybrid, so feature code can't be located by one convention. **Alternative:** pick one layout and migrate, or bless the hybrid explicitly and delete the contradicting guides.

**DT5 — Presentation view models are large, side-effectful state machines with ad-hoc reentrancy flags.** `HomeViewModel` (829 lines) juggles `_isLoading`, `_hasShownExpiredModal`, `_cached*`, banner derivation, modal orchestration, two listeners, and navigation; a `refresh()` arriving mid-`_loadHome` is silently dropped (`:421`). This is where subtle state bugs concentrate. **Alternative:** extract the (already partly pure) modal/banner decisions and a small load-state machine, leaving the VM a thin coordinator.

---

## 6. Expectation gaps (expected X, found Y)

- **Auth:** expected the documented magic-link flow (`spec_auth`, screen-prompts) → found one-time-code (ADR-0001). Docs, not code, are wrong. (C11)
- **Run/onboard:** expected `env.json` at root per README:31 → the app only reads `env/env.json` (`.vscode` + `.gitignore`); a root file is silently ignored → blank Supabase config → boot-then-die. No `flutter run`/build/test/codegen command is documented anywhere top-level; the hosted email template must be set in the Dashboard (config push won't deploy it) or sign-in silently sends the wrong (magic-link) email. (C16, C11, docs)
- **App identity:** expected "NeuroStack" → iOS/web show "Flutter Kit", Android shows "neurostack", three bundle IDs. (C9, C24)
- **Subscribe then use:** expected activating a 3rd protocol right after purchasing Pro to work → bounced to the paywall until the webhook lands. (C3)
- **Log from Library:** expected the protocol-detail "Log Session" to log → toast "coming soon". (C25)
- **Contact us:** expected contact options → empty page. (C26)
- **Tabs:** expected tab state/scroll to persist → every switch is a full reload; the scroll-restore keys are dead. (C30)
- **Streak:** expected "current streak = 0" after a lapse → shows the old streak. (C31)
- **CI:** expected the workflow to gate PRs → it never runs on `develop`. (C2)

## 7. What held up (sound under scrutiny — spend effort elsewhere)

- **Webhook idempotency + monotonicity.** `apply_revenuecat_event` is genuinely safe: NULL guards, status allow-list, `rc_last_event_id` dedup, `subscription_updated_at` monotonic guard, service_role-only grant. Out-of-order/duplicate deliveries handled correctly.
- **Auth one-time-code flow matches ADR-0001** end-to-end (method, template `{{ .Token }}`, 6-digit/15-min config); the PKCE-prefetch failure it was created to fix is genuinely avoided.
- **Offline-first session queue** — concurrency guard, offline-mid-loop bail, remove-from-pending-on-success dedup, self-healing corrupt caches, `pending:`-namespaced IDs. The most robust subsystem.
- **RevenueCat unknown-vs-none nullability contract** honored consistently across client/service/resolver (web-stub null → DB fallback).
- **RLS on user-owned rows** (`sessions`, `users`) correctly scopes by `auth.uid()`; no UPDATE/DELETE on `sessions` gives immutability; a client can't forge another user's rows.
- **Trial-expiry boundary logic** (exactly-24h, expires-now, 24h+1s, null-expiration) is thoroughly unit-tested at the resolver level.
- **l10n key parity** (en/sv identical, no placeholder drift) and the **seed↔protocols.json checksum** are consistent; **INTERNET permission** and **iOS ATS** are fine.
- **Baseline:** `flutter analyze` clean, 1001 tests pass, adaptive-color guard passes.

## 8. Open questions (code alone can't resolve — maintainer to answer)

1. Is authenticated write to `protocols`/`research_citations` (C1) a deliberate "signed-in users can contribute" design, or the intended-but-failed admin lock (the migration comment says admin-only)? This decides whether C1 is a security bug or a doc gap.
2. Does the live RevenueCat dashboard use entitlement id `"Neurostack Pro"` and products `neurostack_monthly`/`neurostack_yearly` verbatim? A mismatch silently downgrades everyone to DB fallback.
3. Is `premiumLifetime` (C22) a planned tier? If yes it must be added to the Dart enum before anything writes it; if no, remove it from the DB CHECK/RPC/TS.
4. Is the root-`env.json` vs `env/env.json` mismatch the reason config "doesn't work" for new contributors, and is the hosted email template set in the Dashboard?
5. Is `seed.sql` (test fixtures incl. "Deprecated Protocol"/"Test Author") ever applied to a shared/staging DB via `supabase db reset`? It would inject fixtures and diverge from the migration-seeded catalog.
6. Are integration tests (C10) and golden tests expected to run anywhere? Nothing executes `integration_test/`, and there are no golden tests despite the tagged CI exclusion.
