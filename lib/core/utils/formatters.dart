// lib/core/utils/formatters.dart

/// Common formatter utilities used across the app.
///
/// Keep helpers pure and deterministic. Avoid side effects and UI concerns.
class Formatters {
  /// Normalize Indian mobile numbers to E.164 where possible.
  ///
  /// Rules (conservative to match current behavior):
  /// - If input already starts with '+91', return as-is.
  /// - If input has exactly 10 digits, prefix with '+91'.
  /// - Otherwise, return input unchanged.
  ///
  /// Callers are expected to pass a trimmed string.
  static String normalizeIndianPhone(String phone) {
    if (phone.startsWith('+91')) {
      return phone;
    }
    if (phone.length == 10) {
      return '+91$phone';
    }
    return phone;
  }
}
