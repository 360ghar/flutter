#!/bin/bash

# Function to convert relative imports to package imports
convert_imports() {
    local file="$1"
    echo "Processing: $file"
    
    # Use sed to replace relative imports with package imports
    # Pattern: import '../something.dart'; -> import 'package:ghar360/path/to/something.dart';
    
    # Handle different levels of relative imports
    # ../../../core/utils/error_handler.dart -> package:ghar360/core/utils/error_handler.dart
    sed -i '' 's|import '\''\.\./\.\./\.\./\([^'\'']*\)\.dart'\'';|import '\''package:ghar360/\1.dart'\'';|g' "$file"
    
    # ../../core/utils/error_handler.dart -> package:ghar360/core/utils/error_handler.dart  
    sed -i '' 's|import '\''\.\./\.\./\([^'\'']*\)\.dart'\'';|import '\''package:ghar360/\1.dart'\'';|g' "$file"
    
    # ../data/auth_repository.dart -> package:ghar360/features/FEATURE/data/auth_repository.dart
    # This is more complex as we need to know which feature we're in
    
    # For files in features/*/controllers/ -> ../data/ -> features/FEATURE/data/
    sed -i '' 's|import '\''\.\./data/\([^'\'']*\)\.dart'\'';|import '\''package:ghar360/features/auth/data/\1.dart'\'';|g' "$file"
    
    # For files in features/*/views/ -> ../controllers/ -> features/FEATURE/controllers/
    sed -i '' 's|import '\''\.\./controllers/\([^'\'']*\)\.dart'\'';|import '\''package:ghar360/features/auth/controllers/\1.dart'\'';|g' "$file"
}

# Find all Dart files and process them
find lib -name "*.dart" -type f | while read -r file; do
    convert_imports "$file"
done

echo "Import conversion complete!"
