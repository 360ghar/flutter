# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ghar360** is a Flutter real estate application using GetX for state management with a Bumble-inspired swipe interface design. The app transforms property browsing into an engaging, dating-app-like experience with 360° virtual tours, exact location mapping, and detailed property information.

## Common Development Commands

### Build and Run
```bash
# Run the app in development mode
flutter run

# Run on specific device
flutter run -d ios
flutter run -d android

# Run with specific flavor
flutter run --flavor development
flutter run --flavor production

# Hot reload during development
# Press 'r' in terminal or use IDE hot reload
```

### Code Generation
```bash
# Generate model files (after modifying JSON serializable models)
flutter packages pub run build_runner build

# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# Clean generated files
flutter packages pub run build_runner clean
```

### Testing and Quality
```bash
# Run unit and widget tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Check dependencies for updates
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

### Build for Production
```bash
# Build APK for Android
flutter build apk --release

# Build App Bundle for Google Play
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Build for web
flutter build web
```

## Architecture Overview

### GetX Clean Architecture Pattern
The app follows a modular architecture with clear separation of concerns:

```
lib/
├── app/
│   ├── bindings/          # Dependency injection
│   ├── controllers/       # Business logic and state management
│   ├── data/
│   │   ├── models/        # Data models with JSON serialization
│   │   ├── providers/     # API clients and data sources
│   │   └── repositories/  # Data access layer
│   ├── modules/           # Feature modules (views + bindings)
│   ├── routes/            # Navigation configuration
│   └── utils/             # Theme, constants, helpers
├── widgets/               # Reusable UI components
└── main.dart             # App entry point
```

### Key Architecture Components

#### 1. Controllers (GetX State Management)
- **PropertyController**: Manages property listings, favorites, filtering
- **UserController**: Handles user profile and preferences
- **ExploreController**: Map functionality and location services
- **SwipeController**: Swipe mechanics for Bumble-style interface

#### 2. Data Layer
- **Models**: JSON serializable with `json_annotation`
- **Providers**: Mock API provider using local JSON files
- **Repositories**: Abstraction layer between controllers and data sources

#### 3. Module Structure
Each feature follows the same pattern:
```
module_name/
├── bindings/
│   └── module_binding.dart
├── controllers/
│   └── module_controller.dart
└── views/
    └── module_view.dart
```

### Navigation System
- **GetX routing** with named routes
- **Bottom navigation** with 5 tabs: Profile → Discover → Properties → Liked → Visits
- **Route definitions** in `app/routes/app_routes.dart`
- **Page configuration** in `app/routes/app_pages.dart`

## Theme and Design System

### Bumble-Inspired Color Palette
Defined in `lib/app/utils/theme.dart`:
- **Primary**: `Color(0xFFFFBC05)` (Bumble yellow)
- **Accent**: `Color(0xFFFF6B35)` (Real estate orange)
- **Background**: `Color(0xFFFFFFFF)` and `Color(0xFFF8F9FA)`
- **Text**: Dark `Color(0xFF2C2C2C)`, Gray `Color(0xFF666666)`

### Typography
- **Google Fonts** integration
- **Responsive text scales** for different screen sizes
- **Consistent spacing** and letter spacing

## Mock Data System

### JSON Data Sources
Located in `assets/mock_api/`:
- **properties.json**: 6 diverse properties with complete details
- **user.json**: User profile data
- **favourites.json**: Favorites tracking

### Property Data Structure
```dart
class PropertyModel {
  final String id;
  final String title;
  final double price;
  final String address;
  final int bedrooms, bathrooms;
  final double area;
  final String propertyType;
  final List<String> images;
  final String? tour360Url;
  final List<String> amenities;
  final AgentModel agent;
}
```

## Development Guidelines

### Code Organization
1. **Follow existing module structure** when adding new features
2. **Use GetX controllers** for all state management
3. **Create reusable widgets** in `lib/widgets/` directory
4. **Implement proper error handling** with user-friendly messages
5. **Add loading states** for all async operations

### GetX Best Practices
```dart
// ✅ Reactive variables
final RxList<PropertyModel> properties = <PropertyModel>[].obs;
final RxBool isLoading = false.obs;

// ✅ Proper controller lifecycle
@override
void onInit() {
  super.onInit();
  loadProperties();
}

// ✅ Error handling
void loadProperties() async {
  try {
    isLoading.value = true;
    properties.value = await repository.getProperties();
  } catch (e) {
    Get.snackbar('Error', 'Failed to load properties');
  } finally {
    isLoading.value = false;
  }
}
```

### Widget Development Standards
- **Parameterize components** for reusability
- **Use AppTheme colors** instead of hardcoded values
- **Make widgets responsive** to different screen sizes
- **Follow naming conventions**: PascalCase for classes, camelCase for variables

## Environment Configuration

### Environment Files
- **`.env.development`**: Development environment variables
- **`.env.production`**: Production environment variables
- **Loaded in main.dart**: `await dotenv.load(fileName: ".env.development");`

### Platform Support
- **iOS**: Minimum deployment target iOS 14.0
- **Android**: Minimum SDK version 21
- **Web**: Chrome support enabled

## Key Dependencies

### Core Framework
- **flutter**: SDK framework
- **get**: State management and routing
- **json_annotation/json_serializable**: Model serialization

### UI/UX
- **google_fonts**: Typography
- **cached_network_image**: Image caching
- **flutter_svg**: SVG support
- **shimmer**: Loading animations

### Functionality
- **geolocator**: Location services
- **flutter_map**: Map integration
- **webview_flutter**: 360° tour viewing
- **get_storage**: Local data persistence

## Testing

### Test Structure
- **Widget tests**: `test/widget_test.dart`
- **Unit tests**: Test business logic in controllers
- **Integration tests**: Full app flow testing

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Common Issues and Solutions

### Model Generation
If you modify models with `@JsonSerializable()`, run:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### iOS Build Issues
- Ensure Xcode is updated to latest version
- Run `cd ios && pod install` if CocoaPods issues occur
- Check iOS deployment target in `ios/Podfile`

### Android Build Issues
- Verify Android SDK and build tools are installed
- Check `android/app/build.gradle` for compatibility
- Ensure proper signing configuration

## Future Development

### Planned Features
- **Swipe Interface**: Full Bumble-style property swiping
- **Real API Integration**: Replace mock data with backend
- **Push Notifications**: Property alerts and updates
- **Social Features**: Property sharing and comparisons
- **Advanced Filtering**: ML-based property recommendations

### Performance Optimizations
- **Image lazy loading** for property galleries
- **Virtual scrolling** for large property lists
- **Background data sync** for offline capability
- **Memory management** for image caching