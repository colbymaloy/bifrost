# Bifrosted

The rainbow bridge connecting your app to APIs.

```yaml
dependencies:
  bifrosted: ^0.2.0
```
"Bifrost" was taken..

This is mostly built for my own internal use and don't expect anyone to use this. It's purely to speed up MY development.
I'm using this package to host my common shared patterns across apps, hence the name Bifrost - the bridge that connects everything.

I'm providing myself abstract classes for utility and ensure i match functionality across projects.

The first release focuses on a simple API abstractions that I use:

The ViewModel(not here yet) gets data from Repository, which uses RestAPI classes to make http requests.

Repository expects you to provide implementation of Caching, Network Connection, and System Notifier that implement their respective base class.

Also includes a custom dummy data annotation for data models to generate the fields with empty data for mocking scenarios.

Goal is to have this be used across Flutter, Jaspr web, and Dart Frog



## Features

- **REST API Client** - Abstract base class with GET, POST, PUT, PATCH, DELETE
- **Repository Pattern** - Automatic deserialization and caching
- **Offline-First** - Cache fallback when offline
- **Error Notifications** - System-wide error handling via `SystemNotifier`
- **Pluggable** - Bring your own storage, logging, and connectivity


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

## Fake Data Generation

### `@generateFake` Annotation

Add the annotation to your freezed models to auto-generate `.fake()` factory methods:

```dart
@freezed
@generateFake
class User with _$User {
  factory User({
    int? id,
    String? name,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// After running build_runner:
final user = UserFake.fake(); // Generates fake data based on field names
```

Add to your `build.yaml`:

```yaml
builders:
  fake_generator:
    import: 'package:bifrosted/builder.dart'
    builder_factories: ['fakeGeneratorBuilder']
    auto_apply: dependents
    build_extensions: {".dart": [".fake.g.dart"]}
    build_to: source
    applies_builders: ["source_gen|combining_builder"]

targets:
  $default:
    builders:
      your_package|fake_generator:
        enabled: true
        generate_for:
          - lib/data/models/**
```

### `FakeUtils`

Generate fake data based on field names:

```dart
FakeUtils.fakeForKey('email');     // -> "john@example.com"
FakeUtils.fakeForKey('firstName'); // -> "John"
FakeUtils.fakeForKey('age');       // -> 42
FakeUtils.fakeForKey('isActive');  // -> true/false
FakeUtils.fakeForKey('createdAt'); // -> ISO8601 date string

// Generate generic fake JSON
final json = FakeUtils.fakeJson();
final users = FakeUtils.fakeJsonList(count: 10);
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
│    └── SystemNotifier (error handling)                      │
├─────────────────────────────────────────────────────────────┤
│  Logging (via logger package)                               │
│    └── bifrostLogger (customize via bifrostLogger = ...)    │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT
