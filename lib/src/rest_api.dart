import 'dart:io';

import 'package:http/http.dart' as http;

import 'logger.dart';

/// Base class for all REST API implementations.
///
/// Subclasses must override [host], [headers], [shortname], and [logger].
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
///
///   @override
///   BifrostLogger get logger => Get.find<AppLogger>();
/// }
/// ```
abstract class RestAPI {
  /// HTTP client for making requests.
  /// Override to provide a custom client (e.g., for mocking).
  http.Client get client => http.Client();

  /// The base host for API requests (e.g., "api.example.com").
  String get host;

  /// Headers to include with every request.
  Map<String, String> get headers;

  /// Short name for logging purposes.
  String get shortname;

  /// Logger instance for this API.
  BifrostLogger get logger;

  // ---------------------------------------------------------------------------
  // Public API - returns null on network/client errors
  // ---------------------------------------------------------------------------

  Future<http.Response?> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) =>
      _send(client.get, _buildUri(endpoint, queryParams), extraHeaders);

  Future<http.Response?> post(
    String endpoint, {
    String? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(client.post, _buildUri(endpoint), body, extraHeaders);

  Future<http.Response?> put(
    String endpoint, {
    String? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(client.put, _buildUri(endpoint), body, extraHeaders);

  Future<http.Response?> patch(
    String endpoint, {
    String? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(client.patch, _buildUri(endpoint), body, extraHeaders);

  Future<http.Response?> delete(
    String endpoint, {
    String? body,
    Map<String, String>? extraHeaders,
  }) =>
      _sendWithBody(client.delete, _buildUri(endpoint), body, extraHeaders);

  /// Send a GET request to a raw URL (bypasses [host]).
  Future<http.Response?> sendRaw(
    String url, {
    Map<String, String>? extraHeaders,
  }) =>
      _send(client.get, Uri.parse(url), extraHeaders);

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) => Uri(
        scheme: 'https',
        host: host,
        path: endpoint,
        queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
      );

  Future<http.Response?> _send(
    Future<http.Response> Function(Uri, {Map<String, String>? headers}) method,
    Uri uri,
    Map<String, String>? extraHeaders,
  ) async {
    logger.info('$shortname request: ${uri.path}');
    try {
      final response =
          await method(uri, headers: {...headers, ...?extraHeaders});
      return _logResponse(response);
    } on SocketException catch (e, s) {
      logger.error('$shortname no network: ${uri.path}',
          error: e, stackTrace: s);
      return null;
    } on http.ClientException catch (e, s) {
      logger.error('$shortname client error: ${uri.path}',
          error: e, stackTrace: s);
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
    logger.info('$shortname request: ${uri.path}');
    try {
      final response =
          await method(uri, body: body, headers: {...headers, ...?extraHeaders});
      return _logResponse(response);
    } on SocketException catch (e, s) {
      logger.error('$shortname no network: ${uri.path}',
          error: e, stackTrace: s);
      return null;
    } on http.ClientException catch (e, s) {
      logger.error('$shortname client error: ${uri.path}',
          error: e, stackTrace: s);
      return null;
    }
  }

  http.Response _logResponse(http.Response response) {
    final status = '${response.statusCode}';
    if (response.statusCode >= 200 && response.statusCode < 300) {
      logger.info('$shortname $status');
      logger.trace('$shortname body: ${response.body}');
    } else {
      logger.warning('$shortname $status | ${response.body}');
    }
    return response;
  }
}
