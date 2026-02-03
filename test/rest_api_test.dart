import 'package:bifrosted/bifrosted.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('RestAPI', () {
    late _TestAPI api;

    group('successful requests', () {
      setUp(() {
        api = _TestAPI(
          mockClient: MockClient((request) async {
            return http.Response('{"success": true}', 200);
          }),
        );
      });

      test('GET returns response', () async {
        final response = await api.get('/users');

        expect(response, isNotNull);
        expect(response!.statusCode, 200);
        expect(response.body, contains('success'));
      });

      test('GET with query params builds correct URI', () async {
        Uri? capturedUri;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedUri = request.url;
            return http.Response('{}', 200);
          }),
        );

        await api.get('/search', queryParams: {'q': 'test', 'limit': '10'});

        expect(capturedUri!.queryParameters['q'], 'test');
        expect(capturedUri!.queryParameters['limit'], '10');
      });

      test('POST sends body', () async {
        String? capturedBody;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedBody = request.body;
            return http.Response('{}', 201);
          }),
        );

        final response =
            await api.post('/users', body: '{"name": "Odin"}');

        expect(response!.statusCode, 201);
        expect(capturedBody, '{"name": "Odin"}');
      });

      test('PUT sends body', () async {
        String? capturedBody;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedBody = request.body;
            return http.Response('{}', 200);
          }),
        );

        await api.put('/users/1', body: '{"name": "Thor"}');

        expect(capturedBody, '{"name": "Thor"}');
      });

      test('PATCH sends body', () async {
        String? capturedBody;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedBody = request.body;
            return http.Response('{}', 200);
          }),
        );

        await api.patch('/users/1', body: '{"name": "Loki"}');

        expect(capturedBody, '{"name": "Loki"}');
      });

      test('DELETE works', () async {
        api = _TestAPI(
          mockClient: MockClient((request) async {
            return http.Response('', 204);
          }),
        );

        final response = await api.delete('/users/1');

        expect(response!.statusCode, 204);
      });

      test('sendRaw bypasses host', () async {
        Uri? capturedUri;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedUri = request.url;
            return http.Response('{}', 200);
          }),
        );

        await api.sendRaw('https://other-api.com/data');

        expect(capturedUri!.host, 'other-api.com');
        expect(capturedUri!.path, '/data');
      });
    });

    group('headers', () {
      test('includes default headers', () async {
        Map<String, String>? capturedHeaders;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedHeaders = request.headers;
            return http.Response('{}', 200);
          }),
        );

        await api.get('/test');

        expect(capturedHeaders!['Content-Type'], 'application/json');
        expect(capturedHeaders!['X-Custom'], 'test-value');
      });

      test('merges extra headers', () async {
        Map<String, String>? capturedHeaders;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedHeaders = request.headers;
            return http.Response('{}', 200);
          }),
        );

        await api.get('/test', extraHeaders: {'Authorization': 'Bearer token'});

        expect(capturedHeaders!['Content-Type'], 'application/json');
        expect(capturedHeaders!['Authorization'], 'Bearer token');
      });

      test('extra headers override defaults', () async {
        Map<String, String>? capturedHeaders;
        api = _TestAPI(
          mockClient: MockClient((request) async {
            capturedHeaders = request.headers;
            return http.Response('{}', 200);
          }),
        );

        await api.get('/test', extraHeaders: {'Content-Type': 'text/plain'});

        expect(capturedHeaders!['Content-Type'], 'text/plain');
      });
    });

    group('error responses', () {
      test('returns 4xx responses', () async {
        api = _TestAPI(
          mockClient: MockClient((request) async {
            return http.Response('{"error": "Not found"}', 404);
          }),
        );

        final response = await api.get('/missing');

        expect(response!.statusCode, 404);
        expect(response.body, contains('Not found'));
      });

      test('returns 5xx responses', () async {
        api = _TestAPI(
          mockClient: MockClient((request) async {
            return http.Response('Internal error', 500);
          }),
        );

        final response = await api.get('/broken');

        expect(response!.statusCode, 500);
      });
    });

    group('network errors', () {
      test('returns null on ClientException', () async {
        api = _TestAPI(
          mockClient: MockClient((request) async {
            throw http.ClientException('Connection failed');
          }),
        );

        final response = await api.get('/test');

        expect(response, isNull);
      });
    });
  });
}

/// Test implementation of RestAPI with injectable mock client.
class _TestAPI extends RestAPI {
  _TestAPI({required MockClient mockClient}) : _mockClient = mockClient;

  final MockClient _mockClient;

  @override
  http.Client get client => _mockClient;

  @override
  String get host => 'api.test.com';

  @override
  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'X-Custom': 'test-value',
      };

  @override
  String get shortname => 'test_api';
}
