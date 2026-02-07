import 'dart:convert';

import 'package:bifrosted/bifrosted.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('BifrostRepository', () {
    late _TestRepo repo;
    late _MockStorage storage;
    late _MockNotifier notifier;
    late _MockConnectionChecker connectionChecker;

    setUp(() {
      storage = _MockStorage();
      notifier = _MockNotifier();
      connectionChecker = _MockConnectionChecker();

      // Set up service locator to return our mocks
      bifrostServiceLocator = <T>() {
        if (T == StorageService) return storage as T;
        if (T == SystemNotifier) return notifier as T;
        if (T == ConnectionChecker) return connectionChecker as T;
        throw StateError('Unknown type: $T');
      };

      repo = _TestRepo();
    });

    group('fetch', () {
      test('deserializes successful response', () async {
        repo.mockResponse = http.Response(
          jsonEncode({'name': 'Odin', 'age': 1000}),
          200,
        );

        final result = await repo.fetchUser();

        expect(result, isNotNull);
        expect(result!.name, 'Odin');
        expect(result.age, 1000);
      });

      test('returns null on null response', () async {
        repo.mockResponse = null;

        final result = await repo.fetchUser();

        expect(result, isNull);
        expect(notifier.networkErrorCalled, isTrue);
      });

      test('returns null on 401 and notifies', () async {
        repo.mockResponse = http.Response('Unauthorized', 401);

        final result = await repo.fetchUser();

        expect(result, isNull);
        expect(notifier.unauthorizedCalled, isTrue);
      });

      test('returns null on 403 and notifies', () async {
        repo.mockResponse = http.Response('Forbidden', 403);

        final result = await repo.fetchUser();

        expect(result, isNull);
        expect(notifier.forbiddenCalled, isTrue);
      });

      test('returns null on 5xx and notifies', () async {
        repo.mockResponse = http.Response('Server error', 500);

        final result = await repo.fetchUser();

        expect(result, isNull);
        expect(notifier.serverErrorCalled, isTrue);
        expect(notifier.lastStatusCode, 500);
      });

      test('returns null on 4xx and notifies', () async {
        repo.mockResponse = http.Response('Bad request', 400);

        final result = await repo.fetchUser();

        expect(result, isNull);
        expect(notifier.apiErrorCalled, isTrue);
        expect(notifier.lastStatusCode, 400);
      });

      test('returns null on deserialization error', () async {
        repo.mockResponse = http.Response('not json', 200);

        final result = await repo.fetchUser();

        expect(result, isNull);
      });
    });

    group('fetchList', () {
      test('deserializes list response', () async {
        repo.mockResponse = http.Response(
          jsonEncode([
            {'name': 'Odin', 'age': 1000},
            {'name': 'Thor', 'age': 500},
          ]),
          200,
        );

        final result = await repo.fetchUsers();

        expect(result, isNotNull);
        expect(result!.length, 2);
        expect(result[0].name, 'Odin');
        expect(result[1].name, 'Thor');
      });

      test('returns null on error', () async {
        repo.mockResponse = http.Response('Error', 500);

        final result = await repo.fetchUsers();

        expect(result, isNull);
      });
    });

    group('mutate', () {
      test('returns deserialized response on success', () async {
        repo.mockResponse = http.Response(
          jsonEncode({'name': 'NewUser', 'age': 25}),
          201,
        );

        final result = await repo.createUser();

        expect(result, isNotNull);
        expect(result!.name, 'NewUser');
      });

      test('returns null on error', () async {
        repo.mockResponse = http.Response('Error', 500);

        final result = await repo.createUser();

        expect(result, isNull);
      });

      test('invalidates cache keys on success', () async {
        // Pre-populate cache
        storage.data['bifrost_cache_data_users_list'] = '[]';
        storage.data['bifrost_cache_exp_users_list'] =
            DateTime.now().add(const Duration(hours: 1)).toIso8601String();

        repo.mockResponse = http.Response(
          jsonEncode({'name': 'NewUser', 'age': 25}),
          201,
        );

        await repo.createUser();

        expect(
            storage.data.containsKey('bifrost_cache_data_users_list'), isFalse);
      });

      test('does not invalidate cache on failure', () async {
        storage.data['bifrost_cache_data_users_list'] = '[]';
        storage.data['bifrost_cache_exp_users_list'] =
            DateTime.now().add(const Duration(hours: 1)).toIso8601String();

        repo.mockResponse = http.Response('Error', 500);

        await repo.createUser();

        expect(
            storage.data.containsKey('bifrost_cache_data_users_list'), isTrue);
      });
    });

    group('send', () {
      test('returns true on success', () async {
        repo.mockResponse = http.Response('', 204);

        final result = await repo.deleteUser('123');

        expect(result, isTrue);
      });

      test('returns false on error', () async {
        repo.mockResponse = http.Response('Error', 500);

        final result = await repo.deleteUser('123');

        expect(result, isFalse);
      });

      test('invalidates cache on success', () async {
        storage.data['bifrost_cache_data_user_123'] = 'data';
        storage.data['bifrost_cache_exp_user_123'] = 'exp';

        repo.mockResponse = http.Response('', 204);

        await repo.deleteUser('123');

        expect(
            storage.data.containsKey('bifrost_cache_data_user_123'), isFalse);
      });
    });

    group('caching', () {
      test('caches successful response', () async {
        repo.mockResponse = http.Response(
          jsonEncode({'name': 'Odin', 'age': 1000}),
          200,
        );

        await repo.fetchUserWithCache('123');

        expect(storage.data.containsKey('bifrost_cache_data_user_123'), isTrue);
        expect(storage.data.containsKey('bifrost_cache_exp_user_123'), isTrue);
      });

      test('does not cache error response', () async {
        repo.mockResponse = http.Response('Error', 500);

        await repo.fetchUserWithCache('123');

        expect(
            storage.data.containsKey('bifrost_cache_data_user_123'), isFalse);
      });

      test('returns cached data when offline', () async {
        // First, cache some data
        storage.data['bifrost_cache_data_user_123'] =
            jsonEncode({'name': 'Cached Odin', 'age': 999});
        storage.data['bifrost_cache_exp_user_123'] =
            DateTime.now().add(const Duration(hours: 1)).toIso8601String();

        // Go offline
        connectionChecker.connected = false;

        final result = await repo.fetchUserWithCache('123');

        expect(result, isNotNull);
        expect(result!.name, 'Cached Odin');
      });

      test('returns null when offline with no cache', () async {
        connectionChecker.connected = false;

        final result = await repo.fetchUserWithCache('123');

        expect(result, isNull);
      });

      test('ignores expired cache', () async {
        // Cache expired data
        storage.data['bifrost_cache_data_user_123'] =
            jsonEncode({'name': 'Expired', 'age': 0});
        storage.data['bifrost_cache_exp_user_123'] =
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();

        // Go offline
        connectionChecker.connected = false;

        final result = await repo.fetchUserWithCache('123');

        expect(result, isNull);
      });

      test('does not cache when caching disabled', () async {
        repo.cachingEnabled = false;
        repo.mockResponse = http.Response(
          jsonEncode({'name': 'Odin', 'age': 1000}),
          200,
        );

        await repo.fetchUserWithCache('123');

        expect(storage.data.isEmpty, isTrue);
      });
    });

    group('clearCache', () {
      test('removes cached data for key', () async {
        storage.data['bifrost_cache_data_test'] = 'data';
        storage.data['bifrost_cache_exp_test'] = 'exp';

        await repo.clearCache('test');

        expect(storage.data.containsKey('bifrost_cache_data_test'), isFalse);
        expect(storage.data.containsKey('bifrost_cache_exp_test'), isFalse);
      });
    });

    group('clearAllCache', () {
      test('does not wipe non-bifrost data', () async {
        // Add non-bifrost data
        storage.data['user_token'] = 'abc123';
        storage.data['app_theme'] = 'dark';

        await repo.clearAllCache();

        // Non-bifrost data should survive
        expect(storage.data['user_token'], 'abc123');
        expect(storage.data['app_theme'], 'dark');
      });
    });
  });
}

// =============================================================================
// Test Doubles
// =============================================================================

class _User {
  _User({required this.name, required this.age});

  factory _User.fromJson(Map<String, dynamic> json) {
    return _User(
      name: json['name'] as String,
      age: json['age'] as int,
    );
  }

  final String name;
  final int age;
}

class _MockStorage implements StorageService {
  final Map<String, String> data = {};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) => data[key];

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  int? getInt(String key) => null;

  @override
  Future<void> setInt(String key, int value) async {}

  @override
  bool getBool(String key) => false;

  @override
  Future<void> setBool(String key, bool value) async {}

  @override
  List<String>? getStringList(String key) => null;

  @override
  Future<void> setStringList(String key, List<String> value) async {}

  @override
  Future<void> remove(String key) async => data.remove(key);

  @override
  Future<void> clear() async => data.clear();

  @override
  Future<void> reload() async {}
}

class _MockNotifier implements SystemNotifier {
  bool networkErrorCalled = false;
  bool unauthorizedCalled = false;
  bool forbiddenCalled = false;
  bool serverErrorCalled = false;
  bool apiErrorCalled = false;
  int? lastStatusCode;
  String? lastBody;

  @override
  void onNetworkError() => networkErrorCalled = true;

  @override
  void onUnauthorized() => unauthorizedCalled = true;

  @override
  void onForbidden() => forbiddenCalled = true;

  @override
  void onServerError(int statusCode, String? body) {
    serverErrorCalled = true;
    lastStatusCode = statusCode;
    lastBody = body;
  }

  @override
  void onApiError(int statusCode, String? body) {
    apiErrorCalled = true;
    lastStatusCode = statusCode;
    lastBody = body;
  }
}

class _MockConnectionChecker implements ConnectionChecker {
  bool connected = true;

  @override
  bool get isConnected => connected;
}

class _TestRepo extends BifrostRepository {
  http.Response? mockResponse;
  bool cachingEnabled = true;

  @override
  bool get enableCaching => cachingEnabled;

  Future<_User?> fetchUser() => fetch<_User>(
        apiRequest: () async => mockResponse,
        fromJson: _User.fromJson,
      );

  Future<List<_User>?> fetchUsers() => fetchList<_User>(
        apiRequest: () async => mockResponse,
        fromJson: _User.fromJson,
      );

  Future<_User?> fetchUserWithCache(String id) => fetch<_User>(
        apiRequest: () async => mockResponse,
        fromJson: _User.fromJson,
        cacheKey: 'user_$id',
      );

  Future<_User?> createUser() => mutate<_User>(
        apiRequest: () async => mockResponse,
        fromJson: _User.fromJson,
        invalidateKeys: ['users_list'],
      );

  Future<bool> deleteUser(String id) => send(
        apiRequest: () async => mockResponse,
        invalidateKeys: ['user_$id'],
      );
}

