# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Flutter source using feature-first GetX layers.
  - Features: `lib/features/<feature>/{views,controllers,bindings}` (e.g., `discover`, `profile`).
  - Shared: `lib/core/` (`core/data/models`, providers, routing, `core/widgets`).
- `assets/`: images and static files (declare in `pubspec.yaml`).
- Platforms: `android/`, `ios/`, `web/` for configs and builds.
- Config: `.env.development`, `.env.production` (do not commit secrets).
- Lint: `analysis_options.yaml` defines rules used by CI/local.

## Build, Test, and Development Commands
- Install deps: `flutter pub get` — fetches packages.
- Run app: `flutter run -d <device_id>` — launches on simulator/device.
- Analyze: `flutter analyze` — static checks; fix all warnings.
- Format: `dart format .` — apply standard Dart formatting.
- Codegen: `flutter pub run build_runner build --delete-conflicting-outputs` — generates `*.g.dart`.
- Tests: `flutter test` — run unit/widget tests locally.
- Releases: `flutter build apk` / `flutter build ios` — production builds.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; follow `analysis_options.yaml`.
- Files: `snake_case.dart` (e.g., `property_details_view.dart`).
- Classes: `UpperCamelCase`; variables/methods: `lowerCamelCase`.
- Suffixes: `*_view.dart`, `*_controller.dart`, `*_binding.dart`.
- Placement: new screens under `lib/features/<feature>/...`; shared utilities in `lib/core/`.

## Testing Guidelines
- Framework: Flutter/Dart tests.
- Location: `test/` mirrors `lib/` paths; name files `*_test.dart`.
- Types: widget tests for views; unit tests for controllers/services and business logic.
- Run: `flutter test` (use `--plain-name` to filter when needed).

## Commit & Pull Request Guidelines
- Commits: imperative, scope-first (e.g., "Refactor filters: unify models"). Keep them focused.
- Before PR: run `flutter analyze`, `dart format .`, `flutter test`, and regenerate code (`build_runner`).
- PRs: include summary, linked issues, test plan, and screenshots for UI changes. Note any env/config or docs updates.

## Security & Configuration
- Never hardcode secrets; load via `.env.*` or secure stores.
- When adding assets, update `pubspec.yaml` and verify both dev/prod configs.

