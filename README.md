# Bifrost

The rainbow bridge connecting your app to APIs.

A lightweight, opinionated REST API client and repository pattern for Dart/Flutter with built-in caching and error handling.

## Features

- **REST API Client** - Abstract base class with GET, POST, PUT, PATCH, DELETE
- **Repository Pattern** - Automatic deserialization and caching
- **Offline-First** - Cache fallback when offline
- **Error Notifications** - System-wide error handling via `SystemNotifier`
- **Pluggable** - Bring your own storage, logging, and connectivity

## Installation

```yaml
dependencies:
  bifrost:
    git:
      url: https://github.com/yourusername/bifrost.git
```

## Quick Start

### 1. Implement the interfaces

```dart
// Your API client
class MyAPI extends RestAPI {
  @override
  String get host => 'api.example.com';

  @override
  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  @override
  String get shortname => 'my_api';

  @override
  BifrostLogger get logger => Get.find<AppLogger>();
}

// Your storage service
class SharedPrefService implements StorageService {
  late SharedPreferences _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  // ... implement other methods
}

// Your error notifier
class AppNotifier implements SystemNotifier {
  @override
  void onNetworkError() => showSnackbar('No internet connection');

  @override
  void onUnauthorized() => navigateTo('/login');

  @override
  void onForbidden() => showSnackbar('Access denied');

  @override
  void onServerError(int statusCode, String? body) =>
      showSnackbar('Server error');

  @override
  void onApiError(int statusCode, String? body) =>
      showSnackbar('Error: $statusCode');
}

// Your connectivity checker
class AppController implements ConnectionChecker {
  @override
  bool get isConnected => _hasConnection;
}
```

### 2. Create your repository

```dart
class UserRepo extends BifrostRepository<AppController, SharedPrefService, AppNotifier> {
  final api = MyAPI();

  @override
  AppController get connectionChecker => Get.find<AppController>();

  @override
  SharedPrefService get storageService => Get.find<SharedPrefService>();

  @override
  AppNotifier get notifier => Get.find<AppNotifier>();

  @override
  BifrostLogger get logger => Get.find<AppLogger>();

  Future<User?> getUser(String id) => fetch<User>(
    apiRequest: () => api.get('/users/$id'),
    fromJson: User.fromJson,
    cacheKey: 'user_$id',
  );

  Future<List<User>?> getUsers() => fetchList<User>(
    apiRequest: () => api.get('/users'),
    fromJson: User.fromJson,
    endpoint: '/users',
  );
}
```

### 3. Use it

```dart
final repo = UserRepo();
final user = await repo.getUser('123');

if (user != null) {
  print(user.name);
} else {
  // Error was already handled by SystemNotifier
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Your App                              │
├─────────────────────────────────────────────────────────────┤
│  Repository (UserRepo, ProductRepo, etc.)                   │
│    ├── fetch<T>() / fetchList<T>()                          │
│    ├── Caching (via StorageService)                         │
│    └── Error handling (via SystemNotifier)                  │
├─────────────────────────────────────────────────────────────┤
│  REST API (MyAPI extends RestAPI)                           │
│    ├── get(), post(), put(), patch(), delete()              │
│    └── Logging (via BifrostLogger)                          │
├─────────────────────────────────────────────────────────────┤
│  Interfaces (you implement these)                           │
│    ├── StorageService (SharedPreferences, Hive, etc.)       │
│    ├── ConnectionChecker (connectivity check)               │
│    ├── SystemNotifier (error handling)                      │
│    └── BifrostLogger (logging)                              │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT
