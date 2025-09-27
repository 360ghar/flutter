#!/bin/bash
# Ensure pub-cache bin is in PATH for FVM
export PATH="$HOME/.pub-cache/bin:$PATH"

# Check common FVM installation paths
FVM_PATHS=(
    "fvm"  # Now in PATH
    "$HOME/fvm/flutter/bin/flutter"
    "/opt/homebrew/bin/fvm"
    "/usr/local/bin/fvm"
)

# Find FVM
FVM_CMD=""
for path in "${FVM_PATHS[@]}"; do
    if command -v "$path" &> /dev/null; then
        FVM_CMD="$path"
        break
    fi
done

# If FVM not found, try flutter directly
if [[ -z "$FVM_CMD" ]]; then
    if command -v flutter &> /dev/null; then
        flutter analyze
        exit $?
    else
        echo "Error: Neither FVM nor Flutter found in PATH"
        exit 1
    fi
fi

# Run with FVM
$FVM_CMD flutter analyze