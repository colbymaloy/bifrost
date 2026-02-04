# Changelog

## 0.2.0

- Added `Faker` utility class for generating mock/test data
  - Strings: `uuid()`, `name()`, `email()`, `username()`, `string()`, `sentence()`, `paragraph()`
  - Numbers: `integer()`, `decimal()`, `boolean()`
  - Dates: `dateTime()`, `pastDate()`, `futureDate()`
  - Collections: `element()`, `list()`
  - JSON: `fakeJson()`, `fakeJsonList()`
- Added model annotations
  - `@bifrostModel` - marker annotation for data models
  - `@primaryKey` - marks primary identifier field
  - `@ignore` - marks field to exclude from serialization

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
