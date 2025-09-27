#!/bin/bash

# Setup script for 360Ghar Flutter project
# This script sets up FVM, pre-commit hooks, and normalizes line endings

set -e

echo "🚀 Setting up 360Ghar Flutter project..."

# Check if FVM is installed
if ! command -v fvm &> /dev/null; then
    echo "📦 Installing FVM..."
    dart pub global activate fvm
fi

# Install pinned Flutter version
echo "🔧 Installing Flutter version..."
fvm install

# Set up pre-commit hooks
if ! command -v pre-commit &> /dev/null; then
    echo "🪝 Installing pre-commit..."

    # Check if pip is available
    if command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    else
        echo "❌ Error: pip is not installed. Please install Python and pip first."
        exit 1
    fi
fi

# Install pre-commit hooks
echo "🔗 Installing pre-commit hooks..."
pre-commit install

# Normalize line endings (if needed)
if [ -f ".gitattributes" ]; then
    echo "📝 Normalizing line endings..."
    git add --renormalize .
    echo "✅ Line endings normalized. Please commit the changes."
fi

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env.development and fill in your credentials"
echo "2. Run 'fvm flutter pub get' to install dependencies"
echo "3. Run 'fvm dart run build_runner build --delete-conflicting-outputs' for code generation"
echo "4. Run 'fvm flutter run' to start the app"