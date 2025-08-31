import 'package:flutter/material.dart';
import '../../core/utils/app_exceptions.dart';
import '../../core/utils/error_mapper.dart';

class ErrorStates {
  // Generic error widget with retry functionality
  static Widget genericError({
    required dynamic error,
    VoidCallback? onRetry,
    String? customMessage,
    String? customRetryText,
  }) {
    // Derive title, message, and icon safely for both String and AppException
    String title;
    String message;
    String icon;

    if (error is AppException) {
      title = _getErrorTitle(error);
      message = error.message;
      icon = ErrorMapper.getErrorIcon(error);
    } else if (error is String) {
      title = 'Error';
      message = error;
      icon = '❌';
    } else {
      title = 'Error';
      message = 'An unexpected error occurred. Please try again.';
      icon = '❌';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),

            // Error title
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error message
            Text(
              customMessage ?? message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null &&
                ((error is AppException && ErrorMapper.isRetryable(error)) ||
                    error is! AppException)) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  customRetryText ??
                      ((error is AppException)
                          ? ErrorMapper.getRetryActionText(error)
                          : 'Retry'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Network error specifically
  static Widget networkError({VoidCallback? onRetry, String? customMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),

            const Text(
              'Connection Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              customMessage ??
                  'Please check your internet connection and try again.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Empty state
  static Widget emptyState({
    required String title,
    required String message,
    IconData? icon,
    String? emoji,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or emoji
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 64))
            else if (icon != null)
              Icon(icon, size: 64, color: Colors.grey[400])
            else
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionText)),
            ],
          ],
        ),
      ),
    );
  }

  // Search empty state
  static Widget searchEmpty({
    required String searchQuery,
    VoidCallback? onClearSearch,
    VoidCallback? onTryDifferentSearch,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),

            const Text(
              'No Results Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'We couldn\'t find any properties matching "$searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onClearSearch != null) ...[
                  ElevatedButton(
                    onPressed: onClearSearch,
                    child: const Text('Clear Search'),
                  ),
                  const SizedBox(width: 16),
                ],

                if (onTryDifferentSearch != null)
                  OutlinedButton(
                    onPressed: onTryDifferentSearch,
                    child: const Text('Try Different Search'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // No location permission state
  static Widget locationPermissionDenied({
    VoidCallback? onRequestPermission,
    VoidCallback? onOpenSettings,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),

            const Text(
              'Location Access Needed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'We need location access to show properties near you.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Column(
              children: [
                if (onRequestPermission != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRequestPermission,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Grant Permission'),
                  ),
                  const SizedBox(height: 12),
                ],

                if (onOpenSettings != null)
                  TextButton(
                    onPressed: onOpenSettings,
                    child: const Text('Open Settings'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Swipe deck empty state
  static Widget swipeDeckEmpty({
    VoidCallback? onRefresh,
    VoidCallback? onChangeFilters,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),

            const Text(
              'No More Properties',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              'You\'ve seen all properties matching your criteria.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onChangeFilters != null) ...[
                  ElevatedButton.icon(
                    onPressed: onChangeFilters,
                    icon: const Icon(Icons.tune),
                    label: const Text('Change Filters'),
                  ),
                  const SizedBox(width: 16),
                ],

                if (onRefresh != null)
                  OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Inline error for smaller spaces
  static Widget inlineError({
    required String message,
    VoidCallback? onRetry,
    bool showIcon = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(Icons.error_outline, color: Colors.red[400], size: 20),
            const SizedBox(width: 8),
          ],

          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
          ),

          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  // Error banner (can be dismissed)
  static Widget errorBanner({
    required String message,
    VoidCallback? onDismiss,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[800], fontSize: 14),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry != null) ...[
                TextButton(onPressed: onRetry, child: const Text('Retry')),
                const SizedBox(width: 4),
              ],

              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Profile loading error with retry and sign out options
  static Widget profileLoadError({
    VoidCallback? onRetry,
    VoidCallback? onSignOut,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),

            // Error title
            const Text(
              'Profile Load Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error message
            Text(
              customMessage ??
                  'Unable to load your profile. Please try again or sign out to start fresh.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                if (onRetry != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (onSignOut != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _getErrorTitle(AppException error) {
    if (error is NetworkException) {
      return 'Connection Problem';
    } else if (error is AuthenticationException) {
      return 'Authentication Required';
    } else if (error is ValidationException) {
      return 'Invalid Input';
    } else if (error is NotFoundException) {
      return 'Not Found';
    } else if (error is ServerException) {
      return 'Server Error';
    }
    return 'Something Went Wrong';
  }
}
