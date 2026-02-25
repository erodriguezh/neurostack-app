# AGENTS.md (Neurostack app)

## Purpose
- Bootstrap instructions for coding agents (keep this file small; link out for details).
- Success = build, run, test, format, and locate the relevant spec/plan with minimal context.

## Repo map
- App code: `lib/` (feature-first: `lib/features/<feature>/{domain,data,presentation}`; shared: `lib/core/`)
- Tests: `test/` (mirrors `lib/`; helpers in `test/factories/`, `test/helpers/` + `test/matchers/`)
- Specs: `docs/specs/` (example: `docs/specs/20260113180000_spec_log_session_modal.md`)
- Plans: `plan_*.md` at repo root (example: `plan_log_session_modal.md`)

## Local config
- Copy `env/default.env.json` → `env/env.json` (do not commit secrets).

## Canonical commands

### Setup
- Install deps: `flutter pub get`

### Code generation (freezed/json_serializable/build_runner)
- Build once: `dart run build_runner build --delete-conflicting-outputs`
- Watch: `dart run build_runner watch --delete-conflicting-outputs`

### Format / Analyze
- Format: `dart format lib test`
- Analyze: `flutter analyze`

### Tests
- All: `flutter test`
- Subset example: `flutter test test/domain/session/`
- Coverage: `flutter test --coverage`

### Run (dev)
- Default: `flutter run -d 1EA9596A-EBDF-4B22-9781-181F20DEB836 --dart-define-from-file=env/env.json`
- Web: `flutter run -d chrome --dart-define-from-file=env/env.json`

## When commands fail
- Typical recovery: `flutter pub get` → codegen → `flutter analyze` → `flutter test`
- If build output is corrupted: `flutter clean && flutter pub get`
- If the agent repeatedly fails the same command, add ONE minimal hint here (or link to a runbook).

<!-- BEGIN FLOW-NEXT -->
## Flow-Next

This project uses Flow-Next for task tracking. Use `.flow/bin/flowctl` instead of markdown TODOs or TodoWrite.

**Quick commands:**
```bash
.flow/bin/flowctl list                # List all epics + tasks
.flow/bin/flowctl epics               # List all epics
.flow/bin/flowctl tasks --epic fn-N   # List tasks for epic
.flow/bin/flowctl ready --epic fn-N   # What's ready
.flow/bin/flowctl show fn-N.M         # View task
.flow/bin/flowctl start fn-N.M        # Claim task
.flow/bin/flowctl done fn-N.M --summary-file s.md --evidence-json e.json
```

**Rules:**
- Use `.flow/bin/flowctl` for ALL task tracking
- Do NOT create markdown TODOs or use TodoWrite
- Re-anchor (re-read spec + status) before every task

**More info:** `.flow/bin/flowctl --help` or read `.flow/usage.md`
<!-- END FLOW-NEXT -->