# Maestro + Flutter Test Suite (360Ghar)

This document describes the repeatable full-app test setup for:

- Maestro E2E flows in `.maestro`
- Hard-to-reach route/widget coverage in `test/`

## Prerequisites

- Flutter SDK in `PATH`
- Maestro CLI installed:
  - `curl -Ls "https://get.maestro.mobile.dev" | bash`
  - add `$HOME/.maestro/bin` to `PATH`
- iOS: Xcode + booted simulator
- Android: Android SDK + running emulator/device (`adb devices`)
- API base URL available via one of:
  - `API_BASE_URL` env var
  - `.env.development`

## Test credentials

The shared login flow (`.maestro/_shared/login.yaml`) reads credentials from environment variables:

- `TEST_PHONE` — the phone number used to log in
- `TEST_PASSWORD` — the password for the test account

Set these before running Maestro locally:

```bash
export TEST_PHONE="your_test_phone"
export TEST_PASSWORD="your_test_password"
```

In CI, these are provided via GitHub Actions secrets (`TEST_PHONE` and `TEST_PASSWORD`).

## Local execution

From the repo root:

### Smoke

- `./scripts/run_maestro_smoke.sh ios`
- `./scripts/run_maestro_smoke.sh android`

### Full

- `./scripts/run_maestro_full.sh ios`
- `./scripts/run_maestro_full.sh android`

### Generic CI-style entrypoint

- `./scripts/run_maestro_ci.sh ios full`
- `./scripts/run_maestro_ci.sh android full`

JUnit output is written under `build/maestro/<suite>-<platform>/junit.xml`.

## CI execution

Workflow file:

- `.github/workflows/maestro-e2e.yml`

It runs Android and iOS in parallel, executes full suite, and uploads artifacts:

- `build/maestro`
- `~/.maestro/tests`

## Suite structure

- Shared subflows: `.maestro/_shared/`
- Feature flows: `.maestro/auth`, `.maestro/dashboard`, `.maestro/discover`, `.maestro/explore`, `.maestro/likes`, `.maestro/visits`, `.maestro/profile`, `.maestro/tools`, `.maestro/deeplink`
- Entrypoints:
  - `.maestro/smoke.yaml`
  - `.maestro/full.yaml`

## Selector contract

Primary selectors are stable `qa.*` keys/labels in Flutter UI, for example:

- `qa.splash.*`
- `qa.auth.*`
- `qa.dashboard.nav.*`
- `qa.profile.*`
- `qa.tools.*`

Fallback text selectors are only used where needed for dynamic content.

## Route coverage map

Covered by Maestro flows:

- `/splash`, `/phone-entry`, `/login`, `/signup`, `/forgot-password`
- `/dashboard`, `/discover`, `/explore`, `/likes`, `/visits`, `/profile`, `/edit-profile`
- `/preferences`, `/privacy`, `/help`, `/feedback`, `/about`
- `/tools`, `/tools/area-converter`, `/tools/loan-eligibility`, `/tools/emi-calculator`, `/tools/carpet-area`, `/tools/document-checklist`, `/tools/capital-gains`
- `/p/:id`, `/property/:id`

Covered by widget tests (hard-to-reach route/state):

- `/profile-completion`
- `/tour` (invalid args fallback)

## Troubleshooting

- `maestro: command not found`
  - Install Maestro and export `$HOME/.maestro/bin` in shell profile.
- `No booted iOS simulator found`
  - Boot a simulator in Xcode or with `xcrun simctl boot <UDID>`.
- `No connected Android emulator/device found`
  - Start an emulator and verify with `adb devices`.
- API/auth failures
  - Verify `API_BASE_URL` and backend reachability.
  - Verify `TEST_PHONE` and `TEST_PASSWORD` env vars are set.
- Flaky selector failures
  - Prefer `qa.*` selectors and increase `extendedWaitUntil` timeout in the specific flow.
