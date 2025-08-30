// lib/core/models/auth_status.dart

enum AuthStatus {
  initial, // App is starting, we don't know the state yet
  authenticated, // User is logged in and profile is complete
  unauthenticated, // User is not logged in
  requiresProfileCompletion, // User is logged in but needs to complete their profile
  error, // Authentication or profile loading error, user can retry
}
