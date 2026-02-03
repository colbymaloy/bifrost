/// Logger interface for bifrost.
///
/// Implement this to integrate with your preferred logging solution
/// (e.g., logger package, print, custom solution).
///
/// Example:
/// ```dart
/// class AppLogger implements BifrostLogger {
///   final _logger = Logger();
///
///   @override
///   void info(String message) => _logger.i(message);
///
///   @override
///   void warning(String message) => _logger.w(message);
///
///   @override
///   void error(String message, {Object? error, StackTrace? stackTrace}) =>
///       _logger.e(message, error: error, stackTrace: stackTrace);
///
///   @override
///   void trace(String message) => _logger.t(message);
/// }
/// ```
abstract class BifrostLogger {
  /// Log informational messages.
  void info(String message);

  /// Log warning messages.
  void warning(String message);

  /// Log error messages with optional error object and stack trace.
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// Log trace/verbose messages (detailed debugging).
  void trace(String message);
}

/// Default no-op logger that discards all messages.
/// Use this if you don't need logging.
class NoOpLogger implements BifrostLogger {
  const NoOpLogger();

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void trace(String message) {}
}

/// Simple print-based logger for development.
class PrintLogger implements BifrostLogger {
  const PrintLogger();

  @override
  void info(String message) => print('[INFO] $message');

  @override
  void warning(String message) => print('[WARN] $message');

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) print('  Error: $error');
    if (stackTrace != null) print('  Stack: $stackTrace');
  }

  @override
  void trace(String message) => print('[TRACE] $message');
}
