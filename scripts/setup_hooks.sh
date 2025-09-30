#!/usr/bin/env bash
set -euo pipefail

git config core.hooksPath .githooks

# ensure hook is executable
chmod +x .githooks/pre-commit || true

echo "Git hooks path set to .githooks"
echo "Pre-commit hook installed. It will auto-format staged .dart files (line length 100)."

