/// Bifrosted - The rainbow bridge connecting your app to APIs.
///
/// A lightweight, opinionated REST API client and repository pattern for Dart/Flutter.
///
/// ## Features
/// - Abstract REST API client with GET, POST, PUT, PATCH, DELETE
/// - Repository pattern with automatic caching and memory singleton cache
/// - Offline-first support with cache fallback
/// - System-wide error notification via [SystemNotifier]
/// - Response unwrapping for wrapped APIs (`{"data": {...}}`)
/// - Write operations with automatic cache invalidation
/// - Pluggable storage via [StorageService]
/// - Pluggable logging via [BifrostLogger]
/// - Global service locator (works with GetX, Provider, get_it, etc.)
///
/// ## Quick Start
///
/// 1. Set the service locator:
/// ```dart
/// bifrostServiceLocator = <T>() => Get.find<T>();
/// ```
///
/// 2. Implement the interfaces:
/// ```dart
/// class MyAPI extends RestAPI { ... }
/// class MyStorage implements StorageService { ... }
/// class MyNotifier implements SystemNotifier { ... }
/// class MyConnectivity implements ConnectionChecker { ... }
/// ```
///
/// 3. Create your repository:
/// ```dart
/// class UserRepo extends BifrostRepository {
///   final api = MyAPI();
///
///   Future<User?> getUser(String id) => fetch<User>(
///     apiRequest: () => api.get('/users/$id'),
///     fromJson: User.fromJson,
///   );
///
///   Future<User?> createUser(User user) => mutate<User>(
///     apiRequest: () => api.post('/users', body: user.toJson()),
///     fromJson: User.fromJson,
///     invalidateKeys: ['users_list'],
///   );
/// }
/// ```
library;

// Re-export logger package for convenience
export 'package:logger/logger.dart' show Logger, Level;

// Annotations & Code Generation
export 'src/generate_fake.dart';

// Interfaces
export 'src/connection_checker.dart';
export 'src/logger.dart';
export 'src/storage_service.dart';
export 'src/system_notifier.dart';

// Core
export 'src/repository.dart';
export 'src/rest_api.dart';

// Testing utilities
export 'src/fake_utils.dart';
