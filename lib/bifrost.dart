/// Bifrost - The rainbow bridge connecting your app to APIs.
///
/// A lightweight, opinionated REST API client and repository pattern for Dart/Flutter.
///
/// ## Features
/// - Abstract REST API client with GET, POST, PUT, PATCH, DELETE
/// - Repository pattern with automatic caching
/// - Offline-first support with cache fallback
/// - System-wide error notification via [SystemNotifier]
/// - Pluggable storage via [StorageService]
/// - Pluggable logging via [BifrostLogger]
///
/// ## Quick Start
///
/// 1. Implement the interfaces:
/// ```dart
/// class MyAPI extends RestAPI { ... }
/// class MyStorage implements StorageService { ... }
/// class MyNotifier implements SystemNotifier { ... }
/// class MyConnectivity implements ConnectionChecker { ... }
/// ```
///
/// 2. Create your repository:
/// ```dart
/// class UserRepo extends BifrostRepository<MyConnectivity, MyStorage, MyNotifier> {
///   final api = MyAPI();
///
///   Future<User?> getUser(String id) => fetch<User>(
///     apiRequest: () => api.get('/users/$id'),
///     fromJson: User.fromJson,
///   );
/// }
/// ```
library;

// Interfaces
export 'src/connection_checker.dart';
export 'src/logger.dart';
export 'src/storage_service.dart';
export 'src/system_notifier.dart';

// Core
export 'src/repository.dart';
export 'src/rest_api.dart';
