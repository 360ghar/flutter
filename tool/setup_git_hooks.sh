#!/usr/bin/env bash
set -euo pipefail

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit || true
echo "✓ Git hooks path set to .githooks and pre-commit made executable."
