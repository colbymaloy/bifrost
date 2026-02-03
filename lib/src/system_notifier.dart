/// Interface for handling system-wide API events.
///
/// Implement this to handle errors globally (show snackbars, redirect to login, etc.).
/// The repository calls these methods when API errors occur.
///
/// Example:
/// ```dart
/// class AppNotifier implements SystemNotifier {
///   @override
///   void onNetworkError() {
///     showSnackbar('No internet connection');
///   }
///
///   @override
///   void onUnauthorized() {
///     // Clear tokens and redirect to login
///     authService.logout();
///     navigator.pushReplacementNamed('/login');
///   }
///
///   @override
///   void onForbidden() {
///     showSnackbar('Access denied');
///   }
///
///   @override
///   void onServerError(int statusCode, String? body) {
///     showSnackbar('Server error. Please try again later.');
///   }
///
///   @override
///   void onApiError(int statusCode, String? body) {
///     showSnackbar('Error: $statusCode');
///   }
/// }
/// ```
abstract class SystemNotifier {
  /// Called when a network error occurs (no connection, timeout, etc.).
  void onNetworkError();

  /// Called when the server returns 401 Unauthorized.
  /// Typically used to redirect to login or refresh tokens.
  void onUnauthorized();

  /// Called when the server returns 403 Forbidden.
  void onForbidden();

  /// Called when the server returns a 5xx error.
  void onServerError(int statusCode, String? body);

  /// Called for any other non-success status code (4xx except 401/403).
  void onApiError(int statusCode, String? body);
}

/// Default no-op notifier that does nothing.
/// Useful for testing or when you don't need notifications.
class NoOpNotifier implements SystemNotifier {
  const NoOpNotifier();

  @override
  void onNetworkError() {}

  @override
  void onUnauthorized() {}

  @override
  void onForbidden() {}

  @override
  void onServerError(int statusCode, String? body) {}

  @override
  void onApiError(int statusCode, String? body) {}
}
