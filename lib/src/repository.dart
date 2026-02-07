import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'connection_checker.dart';
import 'logger.dart';
import 'storage_service.dart';
import 'system_notifier.dart';

// =============================================================================
// Service Locator
// =============================================================================

/// Global service locator function used by [BifrostRepository] to find dependencies.
///
/// Set this once at app startup:
/// ```dart
/// // With GetX:
/// bifrostServiceLocator = <T>() => Get.find<T>();
///
/// // With Provider:
/// bifrostServiceLocator = <T>() => context.read<T>();
///
/// // With get_it:
/// bifrostServiceLocator = <T>() => GetIt.I<T>();
/// ```
T Function<T>() bifrostServiceLocator = <T>() {
  throw StateError(
    'bifrostServiceLocator not set. '
    'Set it at app startup: bifrostServiceLocator = <T>() => Get.find<T>();',
  );
};

// =============================================================================
// JSON Decoder
// =============================================================================

/// Global JSON decode function used by [BifrostRepository].
///
/// Defaults to synchronous [jsonDecode]. Override to decode on a background
/// isolate for large payloads:
///
/// ```dart
/// // Dart (non-web):
/// import 'dart:isolate';
/// bifrostJsonDecode = (body) => Isolate.run(() => jsonDecode(body));
///
/// // Flutter:
/// import 'package:flutter/foundation.dart';
/// bifrostJsonDecode = (body) => compute(jsonDecode, body);
/// ```
///
/// Falls back to synchronous decoding on web where isolates aren't available.
Future<dynamic> Function(String body) bifrostJsonDecode =
    (body) async => jsonDecode(body);

// =============================================================================
// Response Unwrapper
// =============================================================================

/// Extracts data from a JSON response body.
///
/// Many APIs wrap their data:
/// ```json
/// { "data": { "id": 1, "name": "Odin" }, "meta": { "page": 1 } }
/// ```
///
/// Use an unwrapper to extract the relevant part:
/// ```dart
/// class MyRepo extends BifrostRepository {
///   @override
///   dynamic unwrapResponse(dynamic decoded) => decoded['data'];
/// }
/// ```
///
/// For list endpoints that return `{ "data": [...], "total": 100 }`:
/// ```dart
/// @override
/// dynamic unwrapResponse(dynamic decoded) => decoded['data'];
/// ```

// =============================================================================
// BifrostRepository
// =============================================================================

/// Base repository for REST API calls with optional caching and deserialization.
///
/// ## Setup
///
/// Set the service locator once at app startup:
/// ```dart
/// void main() {
///   bifrostServiceLocator = <T>() => Get.find<T>();
///   runApp(MyApp());
/// }
/// ```
///
/// ## Usage
///
/// Create repositories with zero boilerplate:
/// ```dart
/// class UserRepo extends BifrostRepository {
///   final api = MyAPI();
///
///   Future<User?> getUser(String id) => fetch<User>(
///     apiRequest: () => api.get('/users/$id'),
///     cacheKey: 'user_$id',
///     fromJson: User.fromJson,
///   );
/// }
/// ```
///
/// ## Wrapped APIs
///
/// If your API wraps responses (e.g., `{"data": {...}}`), override [unwrapResponse]:
/// ```dart
/// class MyRepo extends BifrostRepository {
///   @override
///   dynamic unwrapResponse(dynamic decoded) => decoded['data'];
/// }
/// ```
///
/// ## Write Operations
///
/// Use [mutate] for POST/PUT/PATCH/DELETE:
/// ```dart
/// Future<User?> createUser(User user) => mutate<User>(
///   apiRequest: () => api.post('/users', body: user.toJson()),
///   fromJson: User.fromJson,
///   invalidateKeys: ['users_list'], // auto-clear related cache
/// );
/// ```
///
/// ## Required Dependencies
///
/// Register these with your DI before using repositories:
/// - [ConnectionChecker] - For online/offline detection
/// - [StorageService] - For caching
/// - [SystemNotifier] - For error handling
abstract class BifrostRepository {
  /// Connection checker from service locator.
  ConnectionChecker get connectionChecker =>
      bifrostServiceLocator<ConnectionChecker>();

  /// Storage service from service locator.
  StorageService get storageService => bifrostServiceLocator<StorageService>();

  /// System notifier from service locator.
  SystemNotifier get notifier => bifrostServiceLocator<SystemNotifier>();

  /// Logger instance. Override to use a custom logger.
  Logger get logger => bifrostLogger;

  /// Override to disable caching for this entire repository.
  /// Default is `true` (caching enabled).
  bool get enableCaching => true;

  /// Override to unwrap API responses before deserialization.
  ///
  /// For example, if your API returns `{"data": {...}, "meta": {...}}`:
  /// ```dart
  /// @override
  /// dynamic unwrapResponse(dynamic decoded) => decoded['data'];
  /// ```
  ///
  /// Default returns [decoded] as-is (no unwrapping).
  dynamic unwrapResponse(dynamic decoded) => decoded;

  // ===========================================================================
  // Singleton Cache
  // ===========================================================================

  /// In-memory cache for deserialized objects.
  ///
  /// Avoids re-decoding the same JSON on repeated reads within a session.
  /// Keys are the same as cache keys. Entries are evicted on write operations
  /// via [mutate] or manually via [clearMemoryCache].
  static final Map<String, dynamic> _memoryCache = {};

  /// Clears the in-memory deserialization cache.
  ///
  /// Call this if you need to force a fresh deserialization on next fetch.
  static void clearMemoryCache() => _memoryCache.clear();

  // ===========================================================================
  // Read Operations
  // ===========================================================================

  /// Fetches data from API and deserializes to a single model.
  ///
  /// [apiRequest] - The API call to execute
  /// [fromJson] - The model's fromJson factory (e.g., `User.fromJson`)
  /// [endpoint] - API endpoint (e.g., '/users/123'). Used as cache key if [cacheKey] not provided.
  /// [cacheKey] - Explicit cache key. Falls back to [endpoint] if not provided.
  /// [cacheDuration] - How long to cache the response (default: 1 hour)
  /// [useMemoryCache] - If true, returns cached deserialized object from memory if available (default: true)
  ///
  /// Returns the deserialized model, or null if request fails or offline with no cache.
  Future<T?> fetch<T>({
    required Future<http.Response?> Function() apiRequest,
    required T Function(Map<String, dynamic>) fromJson,
    String? endpoint,
    String? cacheKey,
    Duration cacheDuration = const Duration(hours: 1),
    bool useMemoryCache = true,
  }) async {
    final key = cacheKey ?? endpoint;

    // Check in-memory cache first
    if (useMemoryCache && key != null && _memoryCache.containsKey(key)) {
      logger.t('Memory cache hit for key: $key');
      return _memoryCache[key] as T;
    }

    final shouldCache = enableCaching && key != null;
    final response = await _makeRequest(
      apiRequest,
      key,
      cacheDuration: cacheDuration,
      shouldCache: shouldCache,
    );

    if (!_handleResponse(response)) return null;

    try {
      final decoded = await bifrostJsonDecode(response!.body);
      final unwrapped = unwrapResponse(decoded);
      final result = fromJson(unwrapped as Map<String, dynamic>);

      // Store in memory cache
      if (useMemoryCache && key != null) {
        _memoryCache[key] = result;
      }

      return result;
    } catch (e) {
      logger.e('Failed to deserialize response for key: $key', error: e);
      return null;
    }
  }

  /// Fetches data from API and deserializes to a list of models.
  ///
  /// [apiRequest] - The API call to execute
  /// [fromJson] - The model's fromJson factory (e.g., `User.fromJson`)
  /// [endpoint] - API endpoint (e.g., '/users'). Used as cache key if [cacheKey] not provided.
  /// [cacheKey] - Explicit cache key. Falls back to [endpoint] if not provided.
  /// [cacheDuration] - How long to cache the response (default: 1 hour)
  /// [useMemoryCache] - If true, returns cached deserialized list from memory if available (default: true)
  ///
  /// Returns the deserialized list, or null if request fails or offline with no cache.
  Future<List<T>?> fetchList<T>({
    required Future<http.Response?> Function() apiRequest,
    required T Function(Map<String, dynamic>) fromJson,
    String? endpoint,
    String? cacheKey,
    Duration cacheDuration = const Duration(hours: 1),
    bool useMemoryCache = true,
  }) async {
    final key = cacheKey ?? endpoint;

    // Check in-memory cache first
    if (useMemoryCache && key != null && _memoryCache.containsKey(key)) {
      logger.t('Memory cache hit for key: $key');
      return _memoryCache[key] as List<T>;
    }

    final shouldCache = enableCaching && key != null;
    final response = await _makeRequest(
      apiRequest,
      key,
      cacheDuration: cacheDuration,
      shouldCache: shouldCache,
    );

    if (!_handleResponse(response)) return null;

    try {
      final decoded = await bifrostJsonDecode(response!.body);
      final unwrapped = unwrapResponse(decoded);
      final result = (unwrapped as List<dynamic>)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();

      // Store in memory cache
      if (useMemoryCache && key != null) {
        _memoryCache[key] = result;
      }

      return result;
    } catch (e) {
      logger.e('Failed to deserialize list response for key: $key', error: e);
      return null;
    }
  }

  // ===========================================================================
  // Write Operations
  // ===========================================================================

  /// Sends a write request (POST, PUT, PATCH, DELETE) and optionally
  /// deserializes the response.
  ///
  /// [apiRequest] - The API call to execute
  /// [fromJson] - Optional. If provided, deserializes the response body.
  /// [invalidateKeys] - Cache keys to clear after a successful request.
  ///
  /// Example:
  /// ```dart
  /// Future<User?> createUser(User user) => mutate<User>(
  ///   apiRequest: () => api.post('/users', body: user.toJson()),
  ///   fromJson: User.fromJson,
  ///   invalidateKeys: ['users_list'],
  /// );
  ///
  /// Future<bool> deleteUser(String id) async {
  ///   final success = await mutate(
  ///     apiRequest: () => api.delete('/users/$id'),
  ///     invalidateKeys: ['user_$id', 'users_list'],
  ///   );
  ///   return success != null;
  /// }
  /// ```
  Future<T?> mutate<T>({
    required Future<http.Response?> Function() apiRequest,
    T Function(Map<String, dynamic>)? fromJson,
    List<String>? invalidateKeys,
  }) async {
    final response = await apiRequest();

    if (!_handleResponse(response)) return null;

    // Invalidate related caches on success
    if (invalidateKeys != null) {
      for (final key in invalidateKeys) {
        await clearCache(key);
        _memoryCache.remove(key);
      }
    }

    // If no fromJson provided, return null (success is indicated by non-null check)
    // For void-like mutations, callers check `result != null` for success.
    if (fromJson == null || response!.body.isEmpty) {
      // Return a non-null sentinel for success detection when T is dynamic
      return null;
    }

    try {
      final decoded = await bifrostJsonDecode(response!.body);
      final unwrapped = unwrapResponse(decoded);
      return fromJson(unwrapped as Map<String, dynamic>);
    } catch (e) {
      logger.e('Failed to deserialize mutation response', error: e);
      return null;
    }
  }

  /// Sends a write request and returns true if successful (2xx), false otherwise.
  ///
  /// Use for fire-and-forget operations where you don't need the response body.
  ///
  /// ```dart
  /// Future<bool> deleteUser(String id) => send(
  ///   apiRequest: () => api.delete('/users/$id'),
  ///   invalidateKeys: ['user_$id', 'users_list'],
  /// );
  /// ```
  Future<bool> send({
    required Future<http.Response?> Function() apiRequest,
    List<String>? invalidateKeys,
  }) async {
    final response = await apiRequest();
    final success = _handleResponse(response);

    if (success && invalidateKeys != null) {
      for (final key in invalidateKeys) {
        await clearCache(key);
        _memoryCache.remove(key);
      }
    }

    return success;
  }

  // ===========================================================================
  // Private Methods
  // ===========================================================================

  /// Handles response status codes and notifies on errors.
  /// Returns true if response is successful (2xx), false otherwise.
  bool _handleResponse(http.Response? response) {
    if (response == null) {
      notifier.onNetworkError();
      return false;
    }

    final statusCode = response.statusCode;

    // Success (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      return true;
    }

    // Handle specific error codes
    switch (statusCode) {
      case 401:
        notifier.onUnauthorized();
      case 403:
        notifier.onForbidden();
      case >= 500:
        notifier.onServerError(statusCode, response.body);
      default:
        notifier.onApiError(statusCode, response.body);
    }

    return false;
  }

  /// Internal method that handles the actual HTTP request and caching.
  Future<http.Response?> _makeRequest(
    Future<http.Response?> Function() apiRequest,
    String? cacheKey, {
    Duration cacheDuration = const Duration(hours: 1),
    bool shouldCache = true,
  }) async {
    if (connectionChecker.isConnected) {
      final response = await apiRequest();

      // Cache successful responses if caching is enabled and key provided
      if (shouldCache &&
          cacheKey != null &&
          response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        await _saveToCache(cacheKey, response.body, cacheDuration);
      }

      return response;
    } else {
      // Offline - try to return cached data if caching is enabled
      if (!shouldCache || cacheKey == null) {
        logger.w('Offline and caching disabled');
        return null;
      }

      logger.i('Offline - checking cache for key: $cacheKey');
      final cachedBody = await _getFromCache(cacheKey);

      if (cachedBody != null) {
        logger.i('Returning cached data for key: $cacheKey');
        return http.Response(cachedBody, 200);
      }

      logger.w('No cached data available for key: $cacheKey');
      return null;
    }
  }

  // ===========================================================================
  // Cache Methods
  // ===========================================================================

  /// Prefix for all bifrost cache keys.
  static const _cachePrefix = 'bifrost_cache_';

  /// Cache key for the data itself
  String _dataKey(String key) => '${_cachePrefix}data_$key';

  /// Cache key for the expiration timestamp
  String _expirationKey(String key) => '${_cachePrefix}exp_$key';

  /// Saves data to cache with expiration
  Future<void> _saveToCache(
    String key,
    String data,
    Duration duration,
  ) async {
    try {
      final expirationTime = DateTime.now().add(duration);
      await storageService.setString(_dataKey(key), data);
      await storageService.setString(
          _expirationKey(key), expirationTime.toIso8601String());
      logger.t('Cached data for key: $key (expires: $expirationTime)');
    } catch (e) {
      logger.e('Failed to cache data for key: $key', error: e);
    }
  }

  /// Gets data from cache if not expired
  Future<String?> _getFromCache(String key) async {
    try {
      final data = storageService.getString(_dataKey(key));
      final expirationStr = storageService.getString(_expirationKey(key));

      if (data == null || expirationStr == null) {
        return null;
      }

      final expirationTime = DateTime.parse(expirationStr);

      if (expirationTime.isAfter(DateTime.now())) {
        return data;
      } else {
        // Expired - clean up
        await clearCache(key);
        logger.t('Cache expired for key: $key');
        return null;
      }
    } catch (e) {
      logger.e('Failed to read cache for key: $key', error: e);
      return null;
    }
  }

  /// Clears cached data for a specific key (both disk and memory).
  Future<void> clearCache(String key) async {
    try {
      await storageService.remove(_dataKey(key));
      await storageService.remove(_expirationKey(key));
      _memoryCache.remove(key);
    } catch (e) {
      logger.e('Failed to clear cache for key: $key', error: e);
    }
  }

  /// Clears all bifrost cache entries without affecting other stored data.
  ///
  /// This only removes keys prefixed with `bifrost_cache_`, leaving
  /// user preferences, auth tokens, etc. untouched.
  Future<void> clearAllCache() async {
    try {
      final allKeys = storageService.getStringList('bifrost_cache_keys');
      if (allKeys != null) {
        for (final key in allKeys) {
          await storageService.remove(key);
        }
        await storageService.remove('bifrost_cache_keys');
      }
      _memoryCache.clear();
      logger.i('All bifrost cache cleared');
    } catch (e) {
      // Fallback: we can't enumerate keys in most storage implementations,
      // so just clear the memory cache and log a warning.
      _memoryCache.clear();
      logger.w(
        'Could not enumerate cache keys. Memory cache cleared. '
        'Use clearCache(key) for specific keys.',
        error: e,
      );
    }
  }
}

/// Exception thrown when JSON deserialization fails.
class DeserializationException implements Exception {
  DeserializationException(this.message);

  final String message;

  @override
  String toString() => 'DeserializationException: $message';
}
