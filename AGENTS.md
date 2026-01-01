# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds the Flutter app. Key areas: `config/` (routing + DI), `core/` (domain mixins, failures, UI constants, utilities), and `features/{feature}/` split into `domain/`, `data/`, and `presentation/`.
- `{simple_feature}/` is a flat folder for small features (<=5 files).
- `test/` mirrors `lib/` and contains factories, constants, and custom matchers.
- `env/` contains `default.env.json` (copy to `env/env.json` for local config).
- `supabase/` has database config and migrations.
- Platform targets live in `android/`, `ios/`, `macos/`, and `web/`.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run` launches the app (use `-d chrome` for web).
- `flutter run --dart-define-from-file=env/env.json` runs with Supabase config.
- `flutter pub run build_runner build` generates code; `flutter pub run build_runner watch` runs watch mode.
- `flutter test` runs unit tests; `flutter test test/domain/user/` runs a subset; `flutter test --coverage` generates coverage.
- `flutter analyze` runs static analysis; `dart format lib/ test/` formats code.
- `flutter clean && flutter pub get` resets build output.

## Architecture Overview
- MVVM + Domain-Driven Design with `ValueNotifier` state (no external state management packages).
- Decision framework: simple CRUD -> MVVM only; validation -> add Value Objects; multiple repositories -> add Use Case; complex rules -> add Aggregate Root.
- Aggregate roots use mixins (`EntityMixin`, `AggregateRootMixin`), reference other aggregates by ID, and keep business logic in the domain layer.

## Coding Style & Naming Conventions
- Use Dart formatting (2-space indent) and keep files in `lower_snake_case.dart`.
- Types are `UpperCamelCase`, variables/functions `lowerCamelCase`.
- ViewModels expose a single `ValueNotifier` and no `BuildContext` access.
- Domain failures use `Aggregate.Invariant` codes (example: `Session.CapacityExceeded`).
- Use `fpdart` `Either` for domain results; do not throw for business rules.
- DTOs map Supabase `snake_case` fields via `@JsonKey`, with `toDomain()` returning `Either` and `fromDomain(T)` for serialization.

## Testing Guidelines
- Framework: `flutter test` with custom matchers in `test/matchers/`.
- Use factories from `test/factories/` and follow AAA (Arrange-Act-Assert).
- Test naming: `{method}_{scenario}_{expectedResult}` (example: `create_withInvalidName_returnsFailure`).
- Widget tests use ViewModels (no mocking).

## Commit & Pull Request Guidelines
- Commit messages are short, lower-case, and imperative (examples: `setup supabase`, `fix unit tests`).
- PRs should include a summary, testing notes/commands, and screenshots for UI changes.
- Link relevant issues and call out config changes (e.g., `env/env.json`).

## Configuration & Secrets
- Copy `env/default.env.json` to `env/env.json` for local development.
- Do not commit credentials or environment-specific values.
