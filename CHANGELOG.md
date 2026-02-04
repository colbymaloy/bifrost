# Changelog

## 0.2.2

- Fixed build.yaml to correctly combine generated code into `.g.dart` files
  - Changed `build_to: cache` and `build_extensions: .fake.g.part`
  - Generator output now properly merges with json_serializable/freezed

## 0.2.1

- Added `build.yaml` for auto-discovery by build_runner
  - No manual configuration needed - just add the dependency and run build_runner
  - Works like freezed/json_serializable out of the box

## 0.2.0

- Added `@generateFake` annotation for code generation
- Added `FakeUtils` utility class (uses `faker` package)
  - `fakeForKey(String key)` - generates fake data based on field name
  - `create<T>()` - generates fake model from factory
  - `fakeJson()` / `fakeJsonList()` - generic JSON generators
- Added `FakeGenerator` for build_runner integration
  - Generates `.fake()` extension methods for annotated classes
  - Works with freezed models

## 0.1.1

- Updated README

## 0.1.0

- Initial release
- `RestAPI` abstract class for REST API clients
  - GET, POST, PUT, PATCH, DELETE methods
  - Automatic error handling and logging
  - Header management with extra headers support
- `BifrostRepository` for repository pattern with caching
  - `fetch<T>()` and `fetchList<T>()` for automatic deserialization
  - Offline-first with cache fallback
  - Automatic cache expiration
- `SystemNotifier` interface for global error handling
  - `onNetworkError()`, `onUnauthorized()`, `onForbidden()`
  - `onServerError()`, `onApiError()`
- `StorageService` interface for pluggable storage backends
- `ConnectionChecker` interface for connectivity detection
- Uses `logger` package for logging
- Comprehensive test suite
