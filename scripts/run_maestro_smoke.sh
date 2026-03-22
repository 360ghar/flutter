#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="${1:-ios}"

"${SCRIPT_DIR}/run_maestro_ci.sh" "${PLATFORM}" smoke
