#!/usr/bin/env bash
set -euo pipefail

# Resolve Flutter binary (prefer repo-local FVM SDK)
if [[ -x ".fvm/flutter_sdk/bin/flutter" ]]; then
  FLUTTER_BIN=".fvm/flutter_sdk/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
elif command -v fvm >/dev/null 2>&1; then
  # Fallback to fvm; assumes fvm manages a Flutter SDK
  FLUTTER_BIN="fvm flutter"
else
  echo "Flutter not found. Install Flutter or set .fvm/flutter_sdk." >&2
  exit 1
fi

# Resolve Dart binary from the chosen Flutter SDK (prefer repo-local FVM SDK)
if [[ -x ".fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart" ]]; then
  DART_BIN=".fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart"
else
  if [[ "$FLUTTER_BIN" == "fvm flutter" ]]; then
    # Try repo-local first, else fall back to PATH 'dart'
    if [[ -x ".fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart" ]]; then
      DART_BIN=".fvm/flutter_sdk/bin/cache/dart-sdk/bin/dart"
    else
      DART_BIN="dart"
    fi
  else
    FLUTTER_SDK_DIR="${FLUTTER_BIN%/bin/flutter}"
    DART_BIN="$FLUTTER_SDK_DIR/bin/cache/dart-sdk/bin/dart"
  fi
fi

echo "Using Flutter: $FLUTTER_BIN"
echo "Using Dart: $($DART_BIN --version 2>/dev/null || echo unknown)"

# 0) Ensure deps (quiet unless it fails)
if [[ "$FLUTTER_BIN" == "fvm flutter" ]]; then
  fvm flutter pub get > /dev/null
else
  "$FLUTTER_BIN" pub get > /dev/null
fi

# 1) Sort and organize imports consistently (matches VS Code organize imports)
if [[ "$FLUTTER_BIN" == "fvm flutter" ]]; then
  fvm flutter pub run import_sorter:main --no-comments lib test
else
  "$FLUTTER_BIN" pub run import_sorter:main --no-comments lib test
fi

# 2) Apply analyzer-provided fixes where possible (unused imports, etc.)
"$DART_BIN" fix --apply

# 3) Format using repo line length (keep in sync with .vscode/settings.json and analysis_options.yaml)
"$DART_BIN" format --line-length 100 .

echo "✓ Formatting complete: imports sorted, fixes applied, code formatted."
