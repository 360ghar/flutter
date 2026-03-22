# AppToast Usage Guidelines

This document provides comprehensive guidelines for using the `AppToast` notification system in the 360Ghar Flutter application.

## Overview

**AppToast** is the centralized toast notification system located at `lib/core/utils/app_toast.dart`. It provides a consistent, minimal, and user-friendly way to display notifications across the application.

## Key Requirements

**ALWAYS use `AppToast` for all notifications/toasts** - Never use `Get.snackbar()` directly in any view, controller, or service.

## Why AppToast?

1. **Consistent Position**: All toasts appear at the top of the screen (`SnackPosition.TOP`)
2. **Minimal Design**: Clean, non-intrusive styling with proper spacing
3. **Unified Appearance**: Consistent colors and typography via `AppDesign` tokens
4. **Simplified API**: Type-safe methods for common use cases
5. **Maintainability**: Single point of control for toast behavior

## Usage Methods

### 1. Success Messages

Use for successful operations, confirmations, and positive feedback.

```dart
AppToast.success('Profile saved', 'Your changes have been saved successfully');

// Or with just title
AppToast.success('Visit scheduled');
```

**When to use:**
- Profile updates saved
- Visit booked successfully
- Preferences saved
- Data synchronized
- Actions completed successfully

### 2. Error Messages

Use for failures, errors, and negative feedback.

```dart
AppToast.error('Error', 'Failed to load properties. Please try again.');

// Or with just title
AppToast.error('Network error');
```

**When to use:**
- API failures
- Network errors
- Validation errors
- Permission denied
- Action failed

### 3. Warning Messages

Use for cautionary messages that require user attention but aren't errors.

```dart
AppToast.warning('Warning', 'Please check your internet connection');

// Or with just title
AppToast.warning('Location services disabled');
```

**When to use:**
- Location services disabled
- Low storage warning
- Session expiring soon
- Missing optional information
- Connection issues

### 4. Info Messages

Use for informational messages and general notifications.

```dart
AppToast.info('Info', 'New features are now available');

// Or with just title
AppToast.info('Language changed');
```

**When to use:**
- Feature announcements
- Tips and hints
- Status updates
- Language changed
- General information

### 5. Custom Styling (Rarely Needed)

For special cases where standard styling doesn't fit:

```dart
AppToast.custom(
  title: 'Coming Soon',
  message: 'This feature will be available in the next update',
  backgroundColor: AppDesign.accentBlue,
  textColor: AppDesign.textDark,
  duration: const Duration(seconds: 4),
);
```

**When to use:**
- Feature coming soon
- Special announcements
- Beta features
- Custom branding needs

## Migration Guide

### From Get.snackbar

**Before:**
```dart
// ❌ DON'T use Get.snackbar directly
Get.snackbar(
  'Error',
  'Failed to load data',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.red,
  colorText: Colors.white,
  duration: const Duration(seconds: 3),
);

Get.snackbar(
  'Success',
  'Profile saved',
  snackPosition: SnackPosition.TOP,
  backgroundColor: Colors.green,
);
```

**After:**
```dart
// ✅ DO use AppToast
AppToast.error('Error', 'Failed to load data');
AppToast.success('Success', 'Profile saved');
```

### Common Patterns

**Controller Error Handling:**
```dart
try {
  await repository.saveData(data);
  AppToast.success('Saved', 'Your data has been saved');
} catch (e) {
  AppToast.error('Error', 'Failed to save data');
}
```

**View Actions:**
```dart
void _handleButtonPress() {
  if (!isValid) {
    AppToast.warning('Warning', 'Please fill all required fields');
    return;
  }
  // Proceed with action
}
```

**Auth Flow:**
```dart
Future<void> login() async {
  try {
    await authRepository.login(credentials);
    AppToast.success('Welcome back!', 'You are now logged in');
  } on AuthException catch (e) {
    AppToast.error('Login failed', e.message);
  }
}
```

## Styling Defaults

### Position
- **Default**: `SnackPosition.TOP`
- **Margin**: 12px from edges
- **Never use**: `SnackPosition.BOTTOM`

### Appearance
- **Border Radius**: 8px
- **Padding**: 16px horizontal, 12px vertical
- **Duration**: 3 seconds (default)
- **Dismissible**: Yes (swipe horizontally)

### Colors
All colors use the `AppDesign` token system:
- **Success**: `AppDesign.successGreen`
- **Error**: `AppDesign.errorRed`
- **Warning**: `AppDesign.warningAmber`
- **Info**: `AppDesign.accentBlue`
- **Text**: Automatically determined based on background

## Best Practices

1. **Keep messages concise**: Title should be 1-3 words, message should be brief
2. **Use appropriate types**: Success for good news, Error for problems, Warning for caution, Info for neutral
3. **Avoid stacking**: Don't show multiple toasts at once; they will queue
4. **Translate strings**: Use translation keys with `.tr` for internationalization
5. **Test in both themes**: Verify visibility in both light and dark modes

## Examples by Feature

### Authentication
```dart
AppToast.success('otp_sent'.tr, 'otp_resent_message'.tr);
AppToast.error('auth_required'.tr, 'login_to_book_visit'.tr);
```

### Property/Likes
```dart
AppToast.success('Removed', '${property.title} removed from liked properties');
AppToast.success('Added', '${property.title} moved to liked properties');
```

### Visits
```dart
AppToast.success('visit_scheduled'.tr, 'Your visit has been scheduled');
AppToast.error('error'.tr, 'could_not_cancel_visit'.tr);
```

### Location
```dart
AppToast.warning('location_services'.tr, 'enable_location_services_message'.tr);
AppToast.error('location_error'.tr, 'failed_to_get_location_message'.tr);
```

### Profile
```dart
AppToast.success('success'.tr, 'profile_updated_successfully'.tr);
AppToast.info('change_password_snackbar_title'.tr, 'change_password_snackbar_message'.tr);
```

## Troubleshooting

### Toast not showing
- Ensure you have imported `AppToast`: `import 'package:ghar360/core/utils/app_toast.dart';`
- Check that the overlay context is available (not during app initialization)

### Wrong position
- Never pass `position` parameter to custom method unless absolutely necessary
- Default is always `SnackPosition.TOP`

### Styling issues
- Don't override colors unless necessary
- Use `AppToast.custom()` only when standard colors don't fit

## File Location

```
lib/core/utils/app_toast.dart
```

## Related Files

- `lib/core/design/app_design_extensions.dart` - Design tokens
- `lib/core/utils/error_handler.dart` - Error handling utilities
- `lib/core/utils/error_mapper.dart` - Error mapping utilities

## Enforcement

All new code must use `AppToast`. Direct `Get.snackbar()` usage will be flagged during code review. The codebase has been fully migrated - no legacy `Get.snackbar()` calls should remain.
