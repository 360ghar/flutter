#!/bin/bash

# Source the user's shell profile to get PATH and environment variables
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true

# Run the command with all arguments
exec "$@"