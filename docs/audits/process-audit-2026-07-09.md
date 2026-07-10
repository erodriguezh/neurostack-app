# NeuroStack process audit — 2026-07-09

Process-level audit of the product's end-to-end workflows. Not a line-by-line code review: the question here is whether the processes the repo *promises* (in README, `AGENTS.md`, the `docs/` guides, the agent harness, and the backend config) actually compose into complete, walkable journeys — for a first-time human following only the docs, and for an autonomous agent chaining commands. Every documented journey was walked twice with those two personas.

Method: built a throwaway clone of `HEAD` (`develop` @ `f7d2e77`) in an isolated scratchpad and ran the real dev-lifecycle commands there (analyze, test, `tool/verify.sh`, `build_runner`, `gen-l10n`, the two dev-tools, seed regeneration). Read-only GitHub (`gh`) checks against `erodriguezh/neurostack-app`. No mutating, publishing, deploy, migration, or credentialed command touched the maintainer's data or any external system. Supabase local stack and the Sandcastle Docker loop could not be executed here (no Docker daemon; Codex creds absent) — those steps are marked **BLOCKED** with the exact command that would confirm them.

**This audit is scoped to workflow composition.** Where a defect is fundamentally a code/design bug already captured in the companion `docs/audits/codebase-audit-2026-07-09.md` (finding IDs `C1`–`C45`), it is cross-referenced, and only the *end-to-end journey evidence* that the code audit did not establish is reported here as new.

Finding IDs (`P1`, `P2`, …) are stable and severity-ordered. A fixing agent should cite these.

Working tree was left unchanged. Maintainer owns git.

---

## 1. Summary table

| ID | Sev | Process | One-line issue | Evidence |
|----|-----|---------|----------------|----------|
| P1 | High | Dev green-gate / agent preflight | `tool/verify.sh` exits 1 on a pristine checkout (format step); it is also the Sandcastle `onSandboxReady` preflight, so the autonomous loop likely aborts before any issue is worked | CONFIRMED (local); PLAUSIBLE (sandbox) |
| P2 | High | Onboarding → config → first run | README says copy env to root `env.json`; the app only reads `env/env.json`, so following the docs yields blank Supabase config → no fail-fast → app boots then dies at first network call | CONFIRMED |
| P3 | High | Onboarding (docs → ready state) | No `flutter run`/`test`/`build_runner`/backend step is documented anywhere top-level, and README is still the upstream "Hungrimind Boilerplate" (wrong product) — a docs-only newcomer cannot reach a running app or a green suite | CONFIRMED |
| P4 | High | Agent onboarding | The canonical agent entry doc (`CLAUDE.md`→`AGENTS.md`) points to `docs/agents/backlog.md` and root `CONTEXT.md` — both missing; the real content lives under different filenames | CONFIRMED |
| P5 | Medium | Backend provisioning / monetization | No committed command or runbook deploys the `revenuecat-webhook` function, sets its secret/service-role key, or provisions the magic-link email template (Dashboard-only for hosted) — the subscription + sign-in-email backbone is manual and undocumented | BLOCKED (deploy) / CONFIRMED (doc gap) |
| P6 | Medium | Local DB bootstrap | `supabase db reset` seeds `seed.sql` (enabled in `config.toml`), injecting a `Deprecated Protocol` + `Test Author` fixture into the real protocol catalog | PLAUSIBLE |
| P7 | Medium | Autonomous agent loop (Sandcastle) | Sandbox pins Flutter `3.44.0` while CI pins `3.32.0` and local is `3.35.3` (format drift), and the review phase's `{{TARGET_BRANCH}}` is never substituted → review-diff command errors | PLAUSIBLE / BLOCKED |
| P8 | Medium | Subscription state machine | `premiumLifetime` is accepted by the DB CHECK + webhook RPC but is unwritable by the edge function and unparseable by the Dart enum → if it ever lands, the user's profile fetch fails with no client path out (dead-end state) | CONFIRMED (static) |
| P9 | Medium | Integration-test authoring / CI | `docs/best_practices/integration_test.md` prescribes `robots/`, `native/`, session/onboarding flows, Patrol, 4-shard CI — none exist (2 flow tests, no robots); and nothing executes `integration_test/` | CONFIRMED / BLOCKED (exec) |
| P10 | Low | Session lifecycle | Sessions are append-only (RLS INSERT/SELECT only; no client edit/delete) → a mis-logged session has no in-app correction path | PLAUSIBLE |
| P11 | Low | Dependency pinning | `flutter pub get` rewrites the committed `pubspec.lock` on a clean checkout; CI doesn't `--enforce-lockfile`, so the pin silently drifts across environments | CONFIRMED |

Severity counts: **High 4 · Medium 5 · Low 2** (11 total).
Evidence counts: **CONFIRMED 6 · CONFIRMED+PLAUSIBLE/BLOCKED split 3 · PLAUSIBLE 1 · PLAUSIBLE/BLOCKED 1**.

---

## 2. Process map (real workflows, states, and owning commands)

### 2.1 Human onboarding journey (docs-only newcomer)

```
clone ─▶ README.md ──────────────▶ [WRONG PRODUCT: "Hungrimind Boilerplate"] (P3)
          │
          └▶ "copy env/default.env.json to env.json"  ──▶ creates ROOT env.json (P2)
                                                            │
   app run config reads env/env.json (.vscode define) ─────┘ ✗ root file never read
          │
          ▼
   flutter pub get ✓ ──▶ build_runner (undocumented) ──▶ gen-l10n (undocumented)
          │
          ▼
   flutter run  ─── CLI: no --dart-define-from-file documented ──▶ blank Supabase URL/key
          │                                                          (defaultValue:'')
          ▼
   app boots (no fail-fast) ──▶ first network call ──▶ dies with unrelated-looking error
          │                                             (DEAD END for docs-only user)
          ▼
   VS Code F5 ─── uses env/env.json ✓ ── the ONLY working documented-ish path
```

Owning commands/config: `README.md:31`, `.vscode/settings.json` (`dart.flutterRunAdditionalArgs`), `lib/core/utils/data_source/data_source_init.dart:29-37`.

### 2.2 Dev green-gate journey

```
contributor asks "am I green?"
   ├─ tool/verify.sh  ──▶ dart format --set-exit-if-changed (lib test integration_test tool)
   │                        └─▶ EXIT 1 on clean checkout (30 files reformat under local Flutter) (P1)
   ├─ flutter analyze ──▶ 0 issues ✓
   └─ flutter test    ──▶ 1001 pass ✓

CI (.github/workflows/test.yaml)  ── triggers on `main` only; repo default is `develop` ──▶ never runs (audit C2)
   └─ format scope = find-based (11 files reformat locally) ≠ verify.sh scope (30) (audit C23/C32)

Sandcastle onSandboxReady hook = `flutter pub get && ./tool/verify.sh`  ──▶ inherits P1 (P7)
```

### 2.3 Subscription state machine (owning writer = `revenuecat-webhook` → `apply_revenuecat_event` RPC)

```
                     handle_new_user trigger
                              │  (INSERT 'free')
                              ▼
   ┌──────────────────────▶ free ◀──────────────────┐
   │                          │ purchase (paywall→RC) │ EXPIRATION(TRIAL)
   │                          ▼                        │
   │        ┌── trial ──renewal──▶ premiumMonthly/Annual ──┐
   │        │  (period=TRIAL)         │      ▲             │ EXPIRATION(non-trial)
   │        │                         │      │ BILLING_ISSUE_RESOLVED
   │        │              BILLING_ISSUE│      │            ▼
   │        │                         ▼      │        expired ──resubscribe──▶ premium
   │        └────────────────────▶ grace ───┘
   │                                                   ▲
   │  premium→free downgrade with >2 protocols:        │
   │  handleUseFreeTier() ──▶ showDeactivationModal ──▶ protocol-selection ──▶ applyProtocolLimitSelection ✓
   │                                                   (forward transition EXISTS — see §6)
   │
   └── premiumLifetime  ◀── DB CHECK ✓ / RPC allow-list ✓ / edge fn writes it? NO
                         ── Dart enum parses it? NO  ──▶ UserDto.toDomain() = Left  ──▶ profile fetch fails
                                                          (UNREACHABLE-by-process yet DEAD-END-if-reached) (P8)
```

Owning surfaces: `supabase/functions/revenuecat-webhook/index.ts:85-153,432-527`, `supabase/migrations/20260212192846_revenuecat_webhook_rpc.sql:49-72`, `lib/features/user/data/dtos/user_dto.dart:58-68`, `lib/features/user/domain/enums/subscription_status.dart:4-23`, `lib/home/home_view_model.dart:244-282`.

### 2.4 Session lifecycle

```
LogSessionUseCase ──▶ SessionDraft.create (INV-S2 not-future, INV-S4 ≤7d) ──▶ create()
   ├─ online  ──▶ remote INSERT (DB assigns UUID) ──▶ synced_* cache
   └─ offline ──▶ pending_* cache ──▶ SessionSyncService (on connectivity/lifecycle) ──▶ synced_*
                                                     │
   list = merge(synced, pending[pending:*])          │
                                                     ▼
   EDIT / DELETE a logged session?  ── no RLS UPDATE/DELETE, no client command ──▶ NONE (append-only) (P10)
```

### 2.5 Agent journey (autonomous + interactive)

```
CLAUDE.md (symlink) ─▶ AGENTS.md
   ├─ "See docs/agents/backlog.md"  ──▶ MISSING (P4)      [real content: docs/agents/issue-tracker.md]
   ├─ "CONTEXT.md at the repo root" ──▶ MISSING (P4)      [real content: docs/ubiquitous-language.md, per docs/agents/domain.md]
   └─ triage-labels.md ──▶ labels match live tracker ✓

Sandcastle loop (.sandcastle/main.mts):
   createSandbox(branch) ─▶ onSandboxReady: pub get && verify.sh  ──▶ P1/P7 risk
      ├─ Phase 1 implementer: gh issue list --label ready-for-agent ──▶ RGR ──▶ commit ──▶ close
      └─ Phase 2 reviewer: git diff {{TARGET_BRANCH}}...{{BRANCH}}  ──▶ {{TARGET_BRANCH}} unsubstituted (P7)
```

**Dead ends / unreachable states found:** the docs-only human run (§2.1, P2/P3); the `premiumLifetime` state (§2.3, P8 — unreachable by the webhook, brick-on-load if reached by any other means); session correction (§2.4, P10); the agent's first two onboarding instructions (§2.5, P4).

---

## 3. Process coverage accounting

**Workflows fully walked (CONFIRMED via command sequence):**
- Fresh clone → README env step → `flutter pub get` → `flutter build web --dart-define-from-file=env/env.json` (probed the missing-file exit).
- Dev green-gate: `flutter analyze --no-pub`, `flutter test`, `tool/verify.sh`, both format predicates (verify.sh scope vs CI scope), adaptive-token guard.
- Codegen re-run semantics: `build_runner build --delete-conflicting-outputs` twice (idempotent), `flutter gen-l10n`, git-dirty snapshot before/after.
- Dev-tools: `verify_protocols_json.dart` (green), `generate_seed_sql.dart` twice (deterministic), regenerated seed diffed against the committed migration (byte-identical), plus both tools from a wrong CWD (error UX).
- Read-only GitHub: default branch, label set, open-issue list, CI run history.

**Fixtures / workspaces created (all disposable, in scratchpad):**
- `…/scratchpad/neurostack-fresh` — full throwaway clone of `develop@f7d2e77`; root `env.json` created per README; `pubspec.lock` + generated files left dirty locally. Never pushed, never merged.
- `…/scratchpad/seed_gen_1.sql`, `seed_gen_2.sql`, `walk_log.txt` — captured tool outputs.

**Partially walked:**
- Subscription state machine — traced statically across the edge function, RPC, DB CHECK, DTO, and enum (no live DB).
- Downgrade→trim path — traced through `home_view_model.dart` (code path exists; not exercised in a running app).

**BLOCKED (dependency/credential/safety boundary — exact command I would have run):**
- Supabase local stack / migrations / seed / RLS: `supabase start && supabase db reset` — **no Docker daemon** (`docker info` failed). Would confirm P6 (fixture injection) and the RLS state.
- Edge-function deploy + webhook round-trip (P5): `supabase functions deploy revenuecat-webhook` + a signed test POST — needs the live project ref `etzzkjskpdpltmuioakg`, `REVENUECAT_WEBHOOK_SECRET`, and `SUPABASE_SERVICE_ROLE_KEY`. Not run (external-service + credential boundary).
- Sandcastle autonomous loop (P1 preflight, P7): `npm run ralph` / `npx tsx .sandcastle/main.mts` — needs Docker + host Codex subscription creds + `GH_TOKEN` with write. Not run (would create branches/commits/issue-closures on the real repo).
- `flutter test integration_test` (P9): needs a device/emulator + `--dart-define-from-file`; integration tests execute nowhere today.

**Blind spots:**
1. No live DB — the `premiumLifetime` dead-end (P8) and seed pollution (P6) are traced from SQL/config, not a running instance.
2. Sandcastle behaviour on a failing `onSandboxReady` hook is inferred from the template, not observed — whether it hard-aborts the iteration or logs-and-continues changes P1/P7 severity.
3. Whether `sandcastle` injects a built-in `TARGET_BRANCH` (beyond `promptArgs`) is unverified; P7's review-diff break assumes it does not.
4. Concurrency: not exercised — the only shared-state local workflow (offline session cache) needs a running app; the code audit already reviewed its concurrency guards.

---

## 4. Gaps / errors by process (severity order)

### P1 — [High] The repo's own green-gate `tool/verify.sh` fails on a pristine checkout, and it gates the agent loop
**Where:** `tool/verify.sh:14-19`; wired as the Sandcastle preflight at `.sandcastle/main.mts:66`.
**Reproduce (CONFIRMED, in throwaway clone with local Flutter 3.35.3):**
```
$ bash tool/verify.sh
Changed integration_test/mocks/fake_services.dart
Changed integration_test/utils/auth_helpers.dart
… (30 files) …
Formatted 345 files (30 changed)
$ echo $?      # → 1
```
`flutter analyze` (0 issues) and `flutter test` (1001 pass) are green; only the `dart format --set-exit-if-changed` step fails, on files nobody touched.
**Stranded scenario:** (a) A new contributor runs the repo's only committed "am I green?" script on untouched `develop` and gets a RED wall of format diffs — indistinguishable from "I broke something." (b) More seriously, `.sandcastle/main.mts:66` runs `flutter pub get && ./tool/verify.sh` in `onSandboxReady`; if the hook's non-zero exit aborts the iteration (template default behaviour), **every autonomous RALPH iteration dies at preflight before the implementer picks an issue** — the loop does no work and the failure looks like an environment error, not a format nit.
**Evidence:** CONFIRMED (local red); PLAUSIBLE (sandbox-abort — BLOCKED on Docker). Extends codebase-audit **C23/C32** with the walked-gate + agent-preflight blast radius.
**Direction:** Pin the toolchain (`.fvmrc`/`fvm`, or a `.tool-versions`) to the single version CI uses; make the preflight run `dart format` as a *fix* (drop `--set-exit-if-changed`) or move the format check to a separate advisory step so a formatter-version delta can't gate analyze/test or the agent loop.

### P2 — [High] Following the README's env step yields config the app never reads → boot-then-die
**Where:** `README.md:31` ("copy `env/default.env.json` to `env.json`") vs `.vscode/settings.json` (`--dart-define-from-file=env/env.json`) and `lib/core/utils/data_source/data_source_init.dart:29-37` (`defaultValue: ''`).
**Reproduce (CONFIRMED):**
```
$ cp env/default.env.json env.json         # exactly what README says
$ flutter build web --dart-define-from-file=env/env.json
Did not find the file passed to "--dart-define-from-file". Path: env/env.json   # exit 1
```
The run config reads `env/env.json`; the README tells you to create root `env.json`. Even once the path is right, `initDataSource` supplies `defaultValue: ''` for `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY`, so a missing/misplaced file produces **no fail-fast** — `Supabase.initialize` is called on empty strings.
**Stranded scenario:** A newcomer copies the template to root `env.json` as instructed, hits F5 or `flutter run`, the app paints the splash and reaches the home/auth screen, then the first Supabase call fails with an opaque network/URL error that never points back at "your env file is in the wrong place / not loaded." They have no signal that config is the problem.
**Evidence:** CONFIRMED. Cross-ref codebase-audit **C16** (empty-default, no fail-fast); the onboarding-*walk* (wrong file location produced by literally following the README) is the new evidence.
**Direction:** Fix `README.md:31` to `env/env.json`; add a startup assertion that fails fast with a named error when `SUPABASE_URL`/key are empty; document the CLI run command with `--dart-define-from-file=env/env.json`.

### P3 — [High] No documented path from clone to a running app or green suite; README is the wrong product
**Where:** `README.md:1-38` (upstream "Hungrimind Flutter Boilerplate": a "CLI", "Discord", generic boilerplate copy). `grep` for `flutter run|test|build|analyze|pub get|build_runner` across `README.md` + `AGENTS.md` → **none**.
**Stranded scenario:** A first-time human reading only the reader-facing docs finds (1) a README about a different product with a nonexistent CLI, and (2) zero instructions to install deps, run codegen (`build_runner` is *required* — 38 generated outputs), start the app, run tests, or stand up the backend. The working knowledge lives only in `.vscode/settings.json`, `tool/verify.sh`, and `.github/workflows/test.yaml`, which a newcomer must reverse-engineer. The `docs/README.md` index is thorough for *architecture* but never states the run/test/setup commands.
**Evidence:** CONFIRMED. Related to codebase-audit **C9/C42** (branding) but the missing-quickstart *journey* is the process gap.
**Direction:** Replace `README.md` with a NeuroStack quickstart: prerequisites (Flutter version, Docker for Supabase), `env/env.json` setup, `flutter pub get`, `dart run build_runner build`, `flutter gen-l10n`, the run command with the define-file, `flutter test`, and a pointer to the backend runbook (P5).

### P4 — [High] The agent entry doc dead-references its first two instructions
**Where:** `AGENTS.md:5` → `docs/agents/backlog.md` (**missing**); `AGENTS.md:13` → `CONTEXT.md` at repo root (**missing**). `CLAUDE.md` is a symlink to `AGENTS.md`, so this is the canonical entry for both humans and agents.
**Reproduce (CONFIRMED):**
```
$ test -e docs/agents/backlog.md || echo MISSING   # → MISSING
$ test -e CONTEXT.md || echo MISSING               # → MISSING
```
The real content exists under other names: the backlog workflow is in `docs/agents/issue-tracker.md`; the "CONTEXT.md role" is played by `docs/ubiquitous-language.md` (as `docs/agents/domain.md` explains).
**Stranded scenario:** An autonomous or interactive agent told to "read `CLAUDE.md` first" follows the Backlog instruction to `docs/agents/backlog.md`, gets a file-not-found, and either fabricates the backlog convention or stalls; likewise for `CONTEXT.md`. Only an agent that *additionally* opens `docs/agents/domain.md` self-heals to the glossary.
**Evidence:** CONFIRMED. Same underlying gap as codebase-audit **C12**; reported here because it breaks the agent's *primary onboarding journey* at step one.
**Direction:** Either create `docs/agents/backlog.md` (or repoint `AGENTS.md:5` to `docs/agents/issue-tracker.md`), and change the `CONTEXT.md` reference to `docs/ubiquitous-language.md` (or add a root `CONTEXT.md` that links to it).

### P5 — [Medium] The backend/monetization provisioning journey is undocumented and unautomated
**Where:** `supabase/functions/revenuecat-webhook/index.ts:4` ("the ONLY writer of subscription status"); `supabase/config.toml:174-176` (magic-link template `content_path`); no top-level doc references `supabase functions deploy`, `supabase db push`, `REVENUECAT_WEBHOOK_SECRET`, or `SUPABASE_SERVICE_ROLE_KEY` (only `plan_*.md`/specs mention pieces).
**Stranded scenario:** A maintainer or agent bringing up a fresh environment has no committed runbook or script to: deploy the webhook function, set its shared secret + service-role key, apply migrations to the hosted project, or install the magic-link email template. Per the project's own record, `supabase config push` deploys only scalar auth settings — the email *body/subject* must be set in the Dashboard — so sign-in silently falls back to Supabase's default (magic-link) email unless a human does that Dashboard step. The subscription-write path and the sign-in-email path both depend on out-of-band manual state that no documented process establishes or verifies.
**Evidence:** BLOCKED to exercise (needs the live project + secrets + Docker); the doc/automation gap is CONFIRMED. Cross-ref codebase-audit open-question #4.
**Direction:** Add `docs/backend-setup.md` (or a `tool/` script): migrate → deploy function → set secrets → **explicit "set the magic-link template in the Dashboard" step** → a smoke test (signed TEST webhook POST expecting `200 {"status":"ok"}`).

### P6 — [Medium] `supabase db reset` injects test fixtures into the protocol catalog
**Where:** `supabase/config.toml:59-63` (`[db.seed] enabled = true`, `sql_paths = ["./seed.sql"]`); `supabase/seed.sql:86` (`'Deprecated Protocol'`), `:281` (`'Test Author'` citation).
**Stranded scenario:** `supabase db reset` is the standard local bootstrap (and `seed.sql`'s own header says "Run with: supabase db reset"). It runs the migrations (which seed 59 real protocols) and then `seed.sql`, which appends a `Deprecated Protocol` and a fake `Test Author` citation. Any developer's local Library screen then shows a fixture protocol; if this seed is ever run against a shared/staging project it pollutes the shared catalog. `ON CONFLICT DO NOTHING` makes it idempotent but not clean, and there is no "remove fixtures" step.
**Evidence:** PLAUSIBLE (config + SQL confirmed; not executed — Docker BLOCKED). To confirm: `supabase db reset && psql -c "select name from public.protocols where name='Deprecated Protocol';"`. Cross-ref codebase-audit open-question #5.
**Direction:** Move dev fixtures out of the `db.seed` path (e.g. a separate `supabase/seeds/dev_fixtures.sql` run only on demand), or clearly namespace/flag fixture rows so they can be excluded and never reach a shared DB.

### P7 — [Medium] The Sandcastle autonomous loop has a toolchain split and an unsubstituted review variable
**Where:** `.sandcastle/Dockerfile:33` (`FLUTTER_VERSION=3.44.0`) vs `.github/workflows/test.yaml:13` (`3.32.0`) vs local `3.35.3`; `.sandcastle/review-prompt.md:9,13` (`{{TARGET_BRANCH}}`) vs `.sandcastle/main.mts:163-165` (passes only `BRANCH`).
**Stranded scenario:** (a) The sandbox builds Flutter `3.44.0` — a real tag (confirmed via `git ls-remote`), but three minor versions ahead of CI. `dart format` output is version-sensitive (the root cause of P1/C23), so the `verify.sh` preflight will reformat committed files and exit non-zero in the sandbox too, compounding P1. (b) In the review phase, `main.mts` provides `BRANCH` but never `TARGET_BRANCH`; the reviewer prompt runs `git diff {{TARGET_BRANCH}}...{{BRANCH}}` with the literal token, which is not a valid ref → the "## Branch diff" context is an error, so the reviewer reviews an empty/broken diff and rubber-stamps.
**Evidence:** PLAUSIBLE / BLOCKED (no Docker + no Codex creds to run the loop). To confirm: `npx tsx .sandcastle/main.mts` and inspect the reviewer's captured diff.
**Direction:** Set `ARG FLUTTER_VERSION` to the exact CI version; pass `TARGET_BRANCH` (the sandbox base, e.g. `develop`) in `promptArgs`; combined with P1's fix, make the preflight format-tolerant.

### P8 — [Medium] `premiumLifetime` is a reachable DB/RPC state that bricks the client on load, with no exit path
**Where:** `supabase/migrations/20260123092258_trial_expiration_columns.sql:19-21` (CHECK includes `premiumLifetime`); `supabase/migrations/20260212192846_revenuecat_webhook_rpc.sql:52-54` (RPC allow-list includes it); `supabase/functions/revenuecat-webhook/index.ts:85-104` (no code path *returns* it); `lib/features/user/domain/enums/subscription_status.dart:4-23` (enum omits it); `lib/features/user/data/dtos/user_dto.dart:58-68` (`values.byName` → `Left(Dto.InvalidSubscriptionStatus)` on unknown).
**Stranded scenario:** The webhook never writes `premiumLifetime` today (there is no lifetime product ID and `determineStatusFromProduct` only yields `trial`/`premiumMonthly`/`premiumAnnual`). But the DB and RPC accept it, so the moment it arrives by any other route — a manual admin/support write, a data migration, or a future lifetime product wired into RevenueCat *before* a client release adds the enum case — every fetch of that user's row fails `toDomain()`. The app renders an error state and there is **no client command or UI** to move the user off `premiumLifetime`; recovery requires a manual DB edit. It is simultaneously unreachable-by-process and a hard dead-end-if-reached.
**Evidence:** CONFIRMED (static contract mismatch). Same defect as codebase-audit **C22**; the state-machine reachability/dead-end analysis is the process contribution.
**Direction:** Add `premiumLifetime` to the Dart enum (mapping to unlimited/premium) *before* anything can write it, or remove it from the DB CHECK, RPC allow-list, and the edge-function TS union so the state is impossible on every surface.

### P9 — [Medium] The documented integration-test journey doesn't match the tree and executes nowhere
**Where:** `docs/best_practices/integration_test.md:280-372,617-662,708-729` (prescribes `robots/robots.dart`, `robots/home_robot.dart`, `native/`, `flows/session_flow_test.dart`, `flows/onboarding_flow_test.dart`, Patrol, a 4-shard CI job). Actual tree: `integration_test/flows/{auth,paywall}_flow_test.dart` + `utils/` + `mocks/` — **no `robots/`, no `native/`, 2 flow tests**. CI runs unit/widget only (`.github/workflows/test.yaml:60`).
**Stranded scenario:** A developer or agent following the guide to add an integration test writes `import '../robots/robots.dart';` / `home_robot.dart` and references a `session_flow_test` pattern that doesn't exist → compile/reference failure. The guide's "Shard Tests in CI" and Patrol sections describe infrastructure that was never built, so an agent may "wire up" against a phantom setup. Separately, nothing runs `integration_test/`, so the two flows that *do* exist are never gated.
**Evidence:** CONFIRMED (structure via `find`); BLOCKED to execute (`flutter test integration_test` needs a device + define-file). Cross-ref codebase-audit **C10/C37**.
**Direction:** Reconcile the guide to the real harness (`createTestApp`, `fake_*` in `mocks/`), delete the robots/Patrol/shard sections or mark them explicitly aspirational, and either add an integration-test CI job (device matrix) or state that these run manually only.

### P10 — [Low] Logged sessions have no correction path
**Where:** `supabase/migrations/20251230160000_auth_trigger_and_rls.sql:62-65` (sessions: INSERT + SELECT policies only; no UPDATE/DELETE); no client edit/delete command in the session feature.
**Stranded scenario:** A user who logs a session with the wrong protocol, date, or duration cannot fix or remove it from the app — the record is permanent. This is consistent with the stated append-only invariant, but no documented recovery exists for ordinary user error, and the UI offers no "undo."
**Evidence:** PLAUSIBLE (RLS + absence of a command). To confirm behaviourally would need a running app + DB.
**Direction:** Confirm intent; if sessions should be user-correctable, add a delete/relog affordance (a soft-delete column + policy); if strictly immutable, say so in the log-session UI copy so the constraint is discoverable.

### P11 — [Low] `pubspec.lock` drifts on a clean `flutter pub get`; CI doesn't enforce it
**Where:** committed `pubspec.lock`; `.github/workflows/test.yaml:29-30` (`flutter pub get`, no `--enforce-lockfile`); Sandcastle hook `.sandcastle/main.mts:66` also plain `flutter pub get`.
**Reproduce (CONFIRMED, throwaway clone):**
```
$ flutter pub get
Changed 5 dependencies!
$ git status --porcelain   # →  M pubspec.lock
```
**Stranded scenario:** Because no environment enforces the lockfile, the pinned dependency set silently differs between a contributor's machine, CI, and the Sandcastle sandbox — a class of "works on my machine" drift that a committed lock is supposed to prevent, and it compounds the three-way Flutter split (P7).
**Evidence:** CONFIRMED.
**Direction:** Run `flutter pub get --enforce-lockfile` in CI and the sandbox; refresh and re-commit `pubspec.lock` so a clean `pub get` is a no-op.

---

## 5. Missing-process backlog (per documented journey, ordered by unblocking value)

1. **Quickstart / run docs (unblocks P2, P3, P11).** A README that states: prerequisites & Flutter version, `env/env.json` (correct path), `flutter pub get [--enforce-lockfile]`, `dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`, the run command *with* `--dart-define-from-file=env/env.json`, and `flutter test`.
2. **Toolchain pin (unblocks P1, P7, P11).** A single source of truth for the Flutter version (fvm/`.tool-versions`) shared by CI, local, and the Sandcastle Dockerfile; make `verify.sh`'s format check a fix step or advisory.
3. **Backend runbook + smoke test (unblocks P5, P6).** Deploy-function / set-secrets / apply-migrations steps, the explicit Dashboard email-template step, a fixture-free seed strategy, and a signed-webhook smoke test.
4. **Agent-doc repair (unblocks P4).** Create/redirect `docs/agents/backlog.md`; fix the `CONTEXT.md` reference to `docs/ubiquitous-language.md`.
5. **Sandcastle review fix (unblocks P7).** Pass `TARGET_BRANCH` in `promptArgs`; align the sandbox Flutter version.
6. **Subscription-enum reconciliation (unblocks P8).** Add or remove `premiumLifetime` consistently across enum, CHECK, RPC, and TS.
7. **Integration-test reconciliation + a place to run (unblocks P9).** Align the guide to the real harness and add (or explicitly defer) an integration-test CI job.
8. **Session correction affordance or documented immutability (unblocks P10).**

---

## 6. What held up (survived second-call / regression checks — spend effort elsewhere)

- **Codegen is idempotent and committed-current.** `dart run build_runner build --delete-conflicting-outputs` run twice: first "wrote 38 outputs," second "wrote 0 outputs"; git shows no tracked-file changes → the checked-in generated code matches the generators. `flutter gen-l10n` likewise produced no diff.
- **Seed pipeline is deterministic and coherent.** `generate_seed_sql.dart` produced byte-identical output across two runs, and that output **diffed clean (0 lines)** against the committed `supabase/migrations/20260508124758_seed_protocols_add3.sql`; `protocols.json`'s SHA-256 matches the checksum in that migration header. `verify_protocols_json.dart` exits 0.
- **Dev-tool error ergonomics are good.** Both `generate_seed_sql.dart` and `verify_protocols_json.dart` fail fast from the wrong CWD with a clear, actionable message and a non-zero exit — an agent can distinguish "my invocation was wrong" from a real failure.
- **`flutter analyze` and `flutter test` are green on a clean clone** (0 issues; 1001 pass) — the failing gate (P1) is purely the format predicate, not analysis or tests.
- **The premium→free downgrade-with-trim path is complete.** `handleUseFreeTier()` → `showDeactivationModal` → protocol-selection modal → `confirmProtocolDeactivation` → `applyProtocolLimitSelection` (`lib/home/home_view_model.dart:244-282`, `lib/home/home_view.dart:304-312,477-501`). A user over the free limit has a real forward transition, not a dead end.
- **The webhook state transitions are internally consistent for the reachable states** (`free`/`trial`/`premiumMonthly`/`premiumAnnual`/`grace`/`expired` all have a writer and a parser). Idempotency/monotonicity of the RPC was validated first-hand in the code audit and is not re-litigated here.
- **Triage labels match reality.** Every label in `docs/agents/triage-labels.md` exists in the live tracker (`gh label list`), so the documented triage vocabulary is walkable.

---

## 7. Open questions (maintainer-only)

1. **Sandcastle preflight semantics:** does a non-zero `onSandboxReady` hook abort the iteration or log-and-continue? This decides whether P1/P7 make the autonomous loop a no-op or merely noisy.
2. **`premiumLifetime` (P8):** is a lifetime tier planned? If yes, the Dart enum must gain the case before anything writes it; if no, it should be removed from the DB CHECK / RPC / edge-function type.
3. **Dev fixtures (P6):** is `seed.sql` (with `Deprecated Protocol` / `Test Author`) intended to run on every `supabase db reset`, and is it ever pointed at a shared/staging project?
4. **Email template (P5):** is the hosted project's magic-link template actually set in the Supabase Dashboard, given `config push` won't deploy the body?
5. **Session immutability (P10):** is the absence of edit/delete deliberate product policy, or a missing recovery affordance?
6. **`TARGET_BRANCH` (P7):** does the Sandcastle runtime inject a `TARGET_BRANCH` prompt variable that `main.mts` relies on implicitly, or is the review-diff genuinely running against an unsubstituted token?
