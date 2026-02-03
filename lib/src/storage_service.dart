/// Abstract interface for local storage operations.
///
/// Implement this to support different storage backends:
/// - SharedPreferences
/// - GetStorage
/// - Hive
/// - SecureStorage
/// - etc.
///
/// Example:
/// ```dart
/// class SharedPrefService implements StorageService {
///   late SharedPreferences _prefs;
///
///   @override
///   Future<void> init() async {
///     _prefs = await SharedPreferences.getInstance();
///   }
///
///   @override
///   String? getString(String key) => _prefs.getString(key);
///
///   @override
///   Future<void> setString(String key, String value) =>
///       _prefs.setString(key, value);
///   // ... etc
/// }
/// ```
abstract class StorageService {
  /// Initialize the storage backend. Call before any read/write operations.
  Future<void> init();

  // ===========================================================================
  // Read Operations
  // ===========================================================================

  String? getString(String key);
  int? getInt(String key);

  /// Returns stored bool or `false` if key doesn't exist.
  bool getBool(String key);

  List<String>? getStringList(String key);

  // ===========================================================================
  // Write Operations
  // ===========================================================================

  Future<void> setString(String key, String value);
  Future<void> setInt(String key, int value);
  Future<void> setBool(String key, bool value);
  Future<void> setStringList(String key, List<String> value);

  // ===========================================================================
  // Utilities
  // ===========================================================================

  Future<void> remove(String key);
  Future<void> clear();
  Future<void> reload();
}
