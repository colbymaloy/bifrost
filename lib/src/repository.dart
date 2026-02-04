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

  /// Fetches data from API and deserializes to a single model.
  ///
  /// [apiRequest] - The API call to execute
  /// [fromJson] - The model's fromJson factory (e.g., `User.fromJson`)
  /// [endpoint] - API endpoint (e.g., '/users/123'). Used as cache key if [cacheKey] not provided.
  /// [cacheKey] - Explicit cache key. Falls back to [endpoint] if not provided.
  /// [cacheDuration] - How long to cache the response (default: 1 hour)
  ///
  /// Returns the deserialized model, or null if request fails or offline with no cache.
  Future<T?> fetch<T>({
    required Future<http.Response?> Function() apiRequest,
    required T Function(Map<String, dynamic>) fromJson,
    String? endpoint,
    String? cacheKey,
    Duration cacheDuration = const Duration(hours: 1),
  }) async {
    final key = cacheKey ?? endpoint;
    final shouldCache = enableCaching && key != null;
    final response = await _makeRequest(
      apiRequest,
      key,
      cacheDuration: cacheDuration,
      shouldCache: shouldCache,
    );

    if (!_handleResponse(response)) return null;

    try {
      return Deserializer.deserialize<T>(jsonDecode(response!.body), fromJson);
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
  ///
  /// Returns the deserialized list, or null if request fails or offline with no cache.
  Future<List<T>?> fetchList<T>({
    required Future<http.Response?> Function() apiRequest,
    required T Function(Map<String, dynamic>) fromJson,
    String? endpoint,
    String? cacheKey,
    Duration cacheDuration = const Duration(hours: 1),
  }) async {
    final key = cacheKey ?? endpoint;
    final shouldCache = enableCaching && key != null;
    final response = await _makeRequest(
      apiRequest,
      key,
      cacheDuration: cacheDuration,
      shouldCache: shouldCache,
    );

    if (!_handleResponse(response)) return null;

    try {
      return Deserializer.deserializeList<T>(
          jsonDecode(response!.body), fromJson);
    } catch (e) {
      logger.e('Failed to deserialize list response for key: $key', error: e);
      return null;
    }
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
  // Private Cache Methods
  // ===========================================================================

  /// Cache key for the data itself
  String _dataKey(String key) => 'bifrost_cache_data_$key';

  /// Cache key for the expiration timestamp
  String _expirationKey(String key) => 'bifrost_cache_exp_$key';

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

  /// Clears cached data for a specific key
  Future<void> clearCache(String key) async {
    try {
      await storageService.remove(_dataKey(key));
      await storageService.remove(_expirationKey(key));
    } catch (e) {
      logger.e('Failed to clear cache for key: $key', error: e);
    }
  }

  /// Clears all cached data (use with caution)
  Future<void> clearAllCache() async {
    await storageService.clear();
    logger.i('All cache cleared');
  }
}

// ============================================================================
// Deserialization Utilities
// ============================================================================

/// Utility class for converting JSON responses into typed Dart models.
///
/// Example:
/// ```dart
/// final json = jsonDecode(response.body);
/// final user = Deserializer.deserialize<User>(json, User.fromJson);
/// final users = Deserializer.deserializeList<User>(jsonList, User.fromJson);
/// ```
class Deserializer {
  /// Converts a single JSON map into a typed model instance.
  static T deserialize<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return fromJson(json);
    } catch (e) {
      throw DeserializationException(
        'Failed to deserialize JSON into $T: $e',
      );
    }
  }

  /// Converts a JSON array into a typed list of model instances.
  static List<T> deserializeList<T>(
    List<dynamic> jsonArray,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return jsonArray
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DeserializationException(
        'Failed to deserialize JSON list into List<$T>: $e',
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
