# Changelog

## 0.1.1

- readme



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
