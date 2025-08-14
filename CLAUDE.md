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
dart run build_runner build

# Watch for changes and auto-generate
dart run build_runner watch

# Clean generated files
dart run build_runner clean

# Force regenerate with conflict resolution
dart run build_runner build --delete-conflicting-outputs
```

### Testing and Quality
```bash
# Run unit and widget tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Analyze code for issues
flutter analyze

# Fix lint issues automatically
dart fix --apply

# Format code according to Dart style
dart format .

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

### Platform-Specific Setup
```bash
# iOS setup after dependency changes
cd ios && pod install

# Clean Flutter build cache
flutter clean

# Get all dependencies
flutter pub get
```

## Architecture Overview

### GetX Clean Architecture Pattern
The app follows a modular architecture with clear separation of concerns:

```
lib/
├── app/
│   ├── bindings/          # Dependency injection
│   ├── controllers/       # Business logic and state management
│   │   ├── auth_controller.dart         # Authentication management
│   │   ├── analytics_controller.dart    # User behavior tracking
│   │   ├── booking_controller.dart      # Property booking system
│   │   ├── location_controller.dart     # Location services
│   │   ├── localization_controller.dart # Multi-language support
│   │   ├── property_controller.dart     # Property listings
│   │   ├── theme_controller.dart        # Theme management (light/dark)
│   │   ├── user_controller.dart         # User profile
│   │   ├── explore_controller.dart      # Map functionality
│   │   ├── swipe_controller.dart        # Swipe mechanics
│   │   └── visits_controller.dart       # Scheduled visits
│   ├── data/
│   │   ├── models/        # Data models with JSON serialization
│   │   ├── providers/     # API clients and data sources
│   │   └── repositories/  # Data access layer
│   ├── middlewares/       # Route guards and interceptors
│   ├── modules/           # Feature modules (views + bindings)
│   ├── routes/            # Navigation configuration
│   └── utils/             # Theme, constants, helpers
├── widgets/               # Reusable UI components
└── main.dart             # App entry point
```

### Key Architecture Components

#### 1. Controllers (GetX State Management)
- **AuthController**: User authentication and session management
- **PropertyController**: Manages property listings, favorites, filtering
- **UserController**: Handles user profile and preferences
- **ExploreController**: Map functionality and location services
- **SwipeController**: Swipe mechanics for Bumble-style interface
- **BookingController**: Property booking and scheduling
- **VisitsController**: Manages property visits and appointments
- **AnalyticsController**: Tracks user behavior and app usage
- **LocationController**: Handles location permissions and services
- **LocalizationController**: Multi-language support and localization
- **ThemeController**: Light/dark theme management and user preferences
- **DashboardController**: Manages dashboard data and navigation
- **DiscoverController**: Discovery and recommendation features
- **FiltersController**: Property filtering and search parameters
- **LikesController**: Manages liked properties and favorites

#### 2. Data Layer
- **Models**: JSON serializable with `json_annotation`
  - PropertyModel, PropertyImageModel for property data
  - UserModel with authentication details
  - BookingModel, VisitModel for scheduling
  - UnifiedPropertyResponse for API responses
  - AnalyticsModels for tracking events
  - FiltersModel for search and filter parameters
  - SwipeHistoryModel for tracking user interactions
  - UnifiedFilterModel for advanced filtering
- **Providers**: 
  - ApiService: Real API integration with error handling
  - ApiClient: Modern API client with Dio integration
  - ApiProvider: Legacy API provider (still in use)
- **Repositories**: Abstraction layer between controllers and data sources
  - PropertiesRepository: Property data access and caching
  - PropertyRepository: Single property operations
  - SwipesRepository: Swipe interaction tracking
  - UserRepository: User profile and preferences

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
- **AuthMiddleware** for protected routes
- **Bottom navigation** with 5 tabs: Profile → Discover → Properties → Liked → Visits
- **Route definitions** in `app/routes/app_routes.dart`
- **Page configuration** in `app/routes/app_pages.dart`
- **Deep linking** support for sharing properties and direct navigation
- **Localized navigation** with multi-language support

## Theme and Design System

### Bumble-Inspired Color Palette
Defined in `lib/app/utils/theme.dart`:
- **Primary**: `Color(0xFFFFBC05)` (Bumble yellow)
- **Accent**: `Color(0xFFFF6B35)` (Real estate orange)
- **Background**: `Color(0xFFFFFFFF)` and `Color(0xFFF8F9FA)`
- **Text**: Dark `Color(0xFF2C2C2C)`, Gray `Color(0xFF666666)`

### Dark Theme Support
Complete dark theme implementation with:
- **Dark backgrounds**: `Color(0xFF000000)` and `Color(0xFF1C1C1E)`
- **Dark surfaces**: `Color(0xFF2C2C2E)` for cards and components
- **Adaptive text**: `Color(0xFFFFFFFF)` primary, `Color(0xFFE5E5E7)` secondary
- **Consistent accent colors**: Primary yellow maintained across themes

### Typography
- **Google Fonts Inter** integration
- **Responsive text scales** for different screen sizes
- **Consistent spacing** and letter spacing
- **Dark theme aware** text colors

## API Integration

### Backend Services
The app supports multiple backend integrations:
- **Supabase**: Backend as a Service with PostgreSQL database, real-time subscriptions, and authentication
- **Real API**: Production backend with full CRUD operations
- **Development**: Environment-based configuration switching
- **Error Handling**: Centralized error management with user-friendly messages
- **Authentication**: Token-based authentication system with Supabase Auth

### API Service Architecture
Located in `lib/app/data/providers/api_service.dart`:
- Centralized error handling with comprehensive exception types
- Response wrapper with type-safe responses
- Authentication token management
- Retry logic for failed requests
- Environment-based endpoint configuration

### Supabase Integration
The app uses Supabase as the primary backend service:
- **Database**: PostgreSQL database for property listings, user profiles, and bookings
- **Authentication**: Built-in authentication with social login support
- **Real-time**: Live updates for property availability and new listings
- **Storage**: File storage for property images and user avatars
- **Row Level Security**: Database-level security policies for data protection

## Environment Configuration

### Environment Files
- **`.env.development`**: Development environment variables
- **`.env.production`**: Production environment variables
- **Loaded in main.dart**: `await dotenv.load(fileName: ".env.development");`

### Required Environment Variables
```
API_BASE_URL=your_api_base_url
API_TOKEN=your_api_token
DATABASE_URL=your_database_url
STORAGE_BUCKET=your_storage_bucket
```

### Platform Support
- **iOS**: Minimum deployment target iOS 14.0
- **Android**: Minimum SDK version 21
- **Web**: Chrome support enabled

## Key Dependencies

### Core Framework
- **flutter**: SDK framework
- **get**: ^4.6.6 - State management and routing
- **json_annotation/json_serializable**: Model serialization
- **dio**: ^5.3.0 - HTTP client for API calls
- **supabase_flutter**: ^2.8.0 - Backend as a Service integration
- **get_storage**: ^2.1.1 - Local data persistence

### UI/UX
- **google_fonts**: ^6.1.0 - Typography (Inter font family)
- **cached_network_image**: ^3.3.0 - Image caching and optimization
- **flutter_svg**: ^2.0.9 - SVG icon support
- **shimmer**: ^3.0.0 - Loading animations and skeletons
- **flutter_rating_bar**: ^4.0.1 - Property ratings
- **cupertino_icons**: ^1.0.2 - iOS-style icons
- **image_network**: ^2.1.2 - Advanced network image handling
- **flutter_cache_manager**: ^3.3.1 - Advanced caching management

### Functionality
- **geolocator**: ^14.0.1 - Location services and GPS
- **geocoding**: ^3.0.0 - Address geocoding
- **flutter_map**: ^8.1.1 - Interactive map integration
- **latlong2**: ^0.9.0 - Latitude/longitude calculations
- **webview_flutter**: ^4.4.2 - 360° tour viewing
- **webview_flutter_web**: ^0.2.2+4 - Web platform support for WebView
- **connectivity_plus**: ^5.0.2 - Network connectivity status
- **flutter_localizations**: Internationalization support
- **intl**: ^0.20.2 - Date/time formatting and localization
- **shared_preferences**: ^2.2.2 - Platform-specific persistent storage
- **flutter_dotenv**: ^5.1.0 - Environment variable management

## Development Guidelines

### Change Scope and Minimal-Change Policy
- Implement only what is explicitly requested. Avoid opportunistic refactors or UI changes unless asked.
- Make the least necessary edits to achieve the requirement while upholding best practices for Flutter, GetX, and Dio.
- Prefer modifying existing code over adding parallel/new implementations. Do not keep legacy code alongside new code; remove obsolete code paths.
- Avoid redundant code intended for backward compatibility. The codebase is in active development; prioritize cleanliness over temporary shims.
- Reuse existing widgets, controllers, repositories, and helpers whenever possible. Do not create duplicates.
- Keep behavior and public APIs stable unless the task requires changes. If APIs change, update all affected call sites and remove the old API.
- Do not introduce new UI components or visual tweaks unless the task requests them. Preserve current UI/UX.
- Keep commits small, focused, and reversible. Include clear rationale in PR descriptions.
- Maintain testability and quality: update or add only the minimal tests needed for the change; fix broken tests caused by removed code instead of adding workarounds.
- Remove dead code and unused assets/imports discovered in the touched areas as part of the edit.

### When minimal edits require refactor
- If a small, surgical refactor reduces complexity or eliminates duplication in the touched scope, do it; keep it scoped.
- Prefer in-place refactors over broad rewrites. Avoid wide-ranging renames that are not required for the task.

### Code Organization
1. **Follow existing module structure** when adding new features
2. **Use GetX controllers** for all state management
3. **Create reusable widgets** in `lib/widgets/` directory
4. **Implement proper error handling** with user-friendly messages
5. **Add loading states** for all async operations
6. **Module structure**: Place feature code under `lib/app/modules/<feature>/{views,controllers,bindings,widgets}`
7. **Use dependency injection** through bindings instead of `Get.put` in widgets
8. **Apply route guards** with `AuthMiddleware` where needed

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

// ✅ Error handling with proper error mapping
void loadProperties() async {
  try {
    isLoading.value = true;
    properties.value = await repository.getProperties();
  } catch (error, stackTrace) {
    ErrorHandler.handle(ErrorMapper.map(error));
    DebugLogger.error('Failed to load properties', error, stackTrace);
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
- **Extend SafeGetView<T>** from `lib/app/widgets/safe_get_view.dart` for typed controller access
- **Use guard clauses** to avoid deep nesting
- **No hardcoded strings** - use translation keys with `.tr` from `app_translations.dart`

### Error Handling
The app uses centralized error handling:
- **ErrorHandler** utility in `lib/app/utils/error_handler.dart`
- **Custom exceptions** for different error types
- **User-friendly error messages** with Get.snackbar
- **DebugLogger** for development logging and debugging
- **Graceful fallbacks** for network and API failures

### Dependency Management
Use `DependencyManager` in `lib/app/utils/dependency_manager.dart`:
- Tracks initialized services and controllers
- Handles proper cleanup and disposal
- Prevents duplicate registrations
- Manages controller lifecycle efficiently
- **SafeGetView** wrapper for safe widget disposal

## Testing

### Test Structure
- **Model tests**: `test/model_test.dart` - JSON serialization testing
- **Widget tests**: `test/widget_test.dart` - UI component testing
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
dart run build_runner build --delete-conflicting-outputs
```

### iOS Build Issues
- Ensure Xcode is updated to latest version
- Run `cd ios && pod install` if CocoaPods issues occur
- Check iOS deployment target in `ios/Podfile`

### Android Build Issues
- Verify Android SDK and build tools are installed
- Check `android/app/build.gradle` for compatibility
- Ensure proper signing configuration

### GetX Controller Issues
- Use `Get.find()` with proper tags
- Ensure controllers are registered in bindings
- Check for duplicate registrations
- Use `Get.delete()` for proper cleanup

## Authentication Flow

### Login/Signup Process
1. User enters credentials in auth views (LoginView/SignupView)
2. AuthController validates input and calls ApiService
3. Backend handles authentication and returns tokens
4. Session stored in secure local storage
5. User redirected to home or profile completion based on setup status

### Profile Completion Flow
- **ProfileCompletionView**: Collects additional user information
- **Progressive disclosure**: Step-by-step profile setup
- **Validation**: Real-time form validation
- **Image upload**: Profile picture selection and upload

### Protected Routes
- **AuthMiddleware**: Checks authentication status for protected routes
- **Automatic redirect**: Redirects to login if not authenticated
- **Route preservation**: Maintains intended route for post-login redirect
- **Session management**: Handles token refresh and expiration

## State Management Patterns

### Controller Communication
- Use GetX's reactive programming for inter-controller communication
- Example: PropertyController listens to UserController favorites
- Avoid direct controller dependencies when possible

### Data Flow
1. View triggers controller action
2. Controller calls repository method
3. Repository uses provider (API/Mock)
4. Data flows back through layers
5. Controller updates reactive state
6. View rebuilds automatically

## Performance Optimizations

### Image Handling
- Use CachedNetworkImage for all remote images
- Implement proper placeholders and error widgets
- Lazy load images in lists
- Optimize image sizes for different screen densities

### List Performance
- Use ListView.builder for long lists
- Implement pagination for property listings
- Add pull-to-refresh functionality
- Cache frequently accessed data

### Memory Management
- Dispose controllers properly with SafeGetView
- Clear image cache periodically
- Use const constructors where possible
- Minimize widget rebuilds with GetX reactivity
- Implement proper controller lifecycle management

## Internationalization

### Multi-Language Support
The app supports multiple languages with complete localization:
- **LocalizationController**: Manages language preferences
- **AppTranslations**: Contains all translation strings
- **Dynamic switching**: Users can change language in preferences
- **Persistent storage**: Language preference saved locally

### Supported Languages
- **English**: Default language
- **Hindi**: Complete Hindi translation
- **RTL Support**: Ready for Arabic/Hebrew if needed

### Adding New Languages
1. Add translation strings to `app/translations/app_translations.dart`
2. Update LocalizationController with new locale
3. Test all screens with new language
4. Ensure proper text overflow handling