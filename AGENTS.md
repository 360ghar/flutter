# Repository Guidelines

## Project Structure & Modules
- `lib/`: Flutter app source. Organized by feature using GetX-style layers:
  - `features/<feature>/{views,controllers,bindings}` (e.g., `discover`, `profile`).
  - `core/`: shared data, models (`core/data/models`), providers, routing, widgets.
- `assets/`: images and other static assets. Declare in `pubspec.yaml`.
- `android/`, `ios/`, `web/`: platform code and configs.
- `analysis_options.yaml`: lint rules for Dart/Flutter.
- `.env.development`, `.env.production`: environment variables (do not commit secrets).

## Build, Test, and Dev Commands
- Install deps: `flutter pub get`
- Run app: `flutter run -d <device_id>`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Codegen (for *.g.dart): `flutter pub run build_runner build --delete-conflicting-outputs`
- Build Android: `flutter build apk`
- Build iOS: `flutter build ios`

## Coding Style & Naming
- Indentation: 2 spaces; follow `analysis_options.yaml`.
- Filenames: `snake_case.dart` (e.g., `property_details_view.dart`).
- Classes: `UpperCamelCase`; members: `lowerCamelCase`.
- Suffix patterns: `*_view.dart`, `*_controller.dart`, `*_binding.dart`, reusable UI in `lib/widgets/...`.
- Prefer feature-first structure under `lib/features/<feature>/` and shared utilities in `lib/core/`.

## Testing Guidelines
- Framework: Flutter/Dart tests (`flutter test`).
- Location: `test/` mirrors `lib/` paths; name files `*_test.dart`.
- Write widget tests for views and unit tests for controllers/services. Aim for meaningful coverage of business logic.

## Commit & Pull Requests
- Commit messages: imperative mood, concise scope-first summary (e.g., "Refactor filters: unify models").
- Group related changes; keep commits focused.
- PRs: include summary, linked issues, test plan, and screenshots for UI changes. Note any env/config updates and docs touched.
- Run `flutter analyze`, `dart format .`, and tests before opening or merging.

## Security & Configuration
- Keep API keys and secrets in env files or secure stores; never hardcode.
- Validate both dev/prod configs. If adding assets, update `pubspec.yaml`.
- If build_runner outputs change, include regenerated `*.g.dart` files in the PR.

