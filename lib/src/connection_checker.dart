/// Interface for checking network connectivity.
///
/// Implement this in your app controller or connectivity service.
/// The repository uses this to determine whether to fetch from API or cache.
///
/// Example:
/// ```dart
/// class AppController implements ConnectionChecker {
///   final _connectivity = Connectivity();
///
///   @override
///   bool get isConnected => _hasConnection;
///
///   bool _hasConnection = true;
///
///   Future<void> init() async {
///     _connectivity.onConnectivityChanged.listen((result) {
///       _hasConnection = result != ConnectivityResult.none;
///     });
///   }
/// }
/// ```
abstract class ConnectionChecker {
  /// Returns true if the device has network connectivity.
  bool get isConnected;
}
