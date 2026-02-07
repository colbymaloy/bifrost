import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logger/logger.dart';

import 'fake_utils.dart';
import 'logger.dart';

// =============================================================================
// Global Client Factory
// =============================================================================

/// Factory function type for creating HTTP clients.
typedef ClientFactory = http.Client Function();

/// Global client factory used by all [RestAPI] instances.
///
/// Defaults to creating a real [http.Client].
/// Override with [setClientFactory] or use [useMockClient] for testing.
ClientFactory _clientFactory = () => http.Client();

/// Set a custom client factory for all [RestAPI] instances.
///
/// Example:
/// ```dart
/// setClientFactory(() => MyCustomClient());
/// ```
void setClientFactory(ClientFactory factory) {
  _clientFactory = factory;
}

/// Reset to using real HTTP clients.
void useRealClient() {
  _clientFactory = () => http.Client();
}

/// Configure all [RestAPI] instances to use a mock client.
///
/// Call this in your test setup:
/// ```dart
/// setUp(() {
///   useMockClient(); // Success responses with fake data
/// });
///
/// // Or for error scenarios:
/// setUp(() {
///   useMockClient(shouldFail: true, failStatusCode: 500);
/// });
/// ```
///
/// The mock client returns [FakeUtils.fakeJson()] for success responses.
/// Override [responseFactory] for custom response data.
void useMockClient({
  bool shouldFail = false,
  int failStatusCode = 400,
  Map<String, dynamic> Function(http.Request request)? responseFactory,
}) {
  _clientFactory = () => MockClient((request) async {
        if (shouldFail) {
          return http.Response(
            jsonEncode({'error': 'Mock failure', 'path': request.url.path}),
            failStatusCode,
          );
        }
        final body = responseFactory?.call(request) ?? FakeUtils.fakeJson();
        return http.Response(jsonEncode(body), 200);
      });
}

// =============================================================================
// RestAPI
// =============================================================================

/// Base class for all REST API implementations.
///
/// Subclasses must override [host], [headers], and [shortname].
///
/// Example:
/// ```dart
/// class MyAPI extends RestAPI {
///   @override
///   String get host => 'api.example.com';
///
///   @override
///   Map<String, String> get headers => {
///     'Authorization': 'Bearer $token',
///     'Content-Type': 'application/json',
///   };
///
///   @override
///   String get shortname => 'my_api';
/// }
/// ```
///
/// ## Testing
///
/// Use [useMockClient] in test setup to mock all API calls:
/// ```dart
/// setUp(() {
///   useMockClient();
/// });
///
/// tearDown(() {
///   useRealClient();
/// });
/// ```
abstract class RestAPI {
  /// HTTP client for making requests.
  ///
  /// By default, uses the global client factory (set via [setClientFactory]
  /// or [useMockClient]). Override for per-API customization.
  http.Client get client => _clientFactory();

  /// The base host for API requests (e.g., "api.example.com").
  String get host;

  /// Headers to include with every request.
  Map<String, String> get headers;

  /// Short name for logging purposes.
  String get shortname;

  /// Logger instance. Override to use a custom logger.
  Logger get logger => bifrostLogger;

  // ---------------------------------------------------------------------------
  // Public API - returns null on network/client errors
  // ---------------------------------------------------------------------------

  /// Sends a GET request to [endpoint].
  Future<http.Response?> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) =>
      _send(client.get, _buildUri(endpoint, queryParams), extraHeaders);

  /// Sends a POST request to [endpoint].
  ///
  /// [body] is automatically JSON-encoded if it's a Map or List.
  /// Pass a String to send raw.
  Future<http.Response?> post(
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(
          client.post, _buildUri(endpoint), _encodeBody(body), extraHeaders);

  /// Sends a PUT request to [endpoint].
  ///
  /// [body] is automatically JSON-encoded if it's a Map or List.
  /// Pass a String to send raw.
  Future<http.Response?> put(
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(
          client.put, _buildUri(endpoint), _encodeBody(body), extraHeaders);

  /// Sends a PATCH request to [endpoint].
  ///
  /// [body] is automatically JSON-encoded if it's a Map or List.
  /// Pass a String to send raw.
  Future<http.Response?> patch(
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(
          client.patch, _buildUri(endpoint), _encodeBody(body), extraHeaders);

  /// Sends a DELETE request to [endpoint].
  ///
  /// [body] is automatically JSON-encoded if it's a Map or List.
  /// Pass a String to send raw.
  Future<http.Response?> delete(
    String endpoint, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(
          client.delete, _buildUri(endpoint), _encodeBody(body), extraHeaders);

  /// Send a GET request to a raw URL (bypasses [host]).
  Future<http.Response?> sendRaw(
    String url, {
    Map<String, String>? extraHeaders,
  }) =>
      _send(client.get, Uri.parse(url), extraHeaders);

  // TODO: Add multipart / file upload support.

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) => Uri(
        scheme: 'https',
        host: host,
        path: endpoint,
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
      );

  /// Encodes [body] to a JSON string if it's a Map or List.
  /// Returns the value as-is if it's already a String, or null.
  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  Future<http.Response?> _send(
    Future<http.Response> Function(Uri, {Map<String, String>? headers}) method,
    Uri uri,
    Map<String, String>? extraHeaders,
  ) async {
    logger.i('$shortname request: ${uri.path}');
    try {
      final response =
          await method(uri, headers: {...headers, ...?extraHeaders});
      return _logResponse(response);
    } on http.ClientException catch (e, s) {
      logger.e('$shortname client error: ${uri.path}', error: e, stackTrace: s);
      return null;
    }
  }

  Future<http.Response?> _sendWithBody(
    Future<http.Response> Function(Uri,
            {Object? body, Map<String, String>? headers})
        method,
    Uri uri,
    String? body,
    Map<String, String>? extraHeaders,
  ) async {
    logger.i('$shortname request: ${uri.path}');
    try {
      final response = await method(uri,
          body: body, headers: {...headers, ...?extraHeaders});
      return _logResponse(response);
    } on http.ClientException catch (e, s) {
      logger.e('$shortname client error: ${uri.path}', error: e, stackTrace: s);
      return null;
    }
  }

  http.Response _logResponse(http.Response response) {
    final status = '${response.statusCode}';
    if (response.statusCode >= 200 && response.statusCode < 300) {
      logger.i('$shortname $status');
      logger.t('$shortname body: ${response.body}');
    } else {
      logger.w('$shortname $status | ${response.body}');
    }
    return response;
  }
}
