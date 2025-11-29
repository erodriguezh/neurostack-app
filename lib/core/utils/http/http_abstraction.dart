import 'package:neurostack/core/utils/http/http_interceptor.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'http_native.dart' if (dart.library.js_interop) 'http_web.dart';

/// A wrapper around the http package that allows for interceptors
/// to be applied to requests and responses.
class HttpAbstraction {
  final http.Client _client;
  final List<HttpInterceptor> _interceptors;

  HttpAbstraction({List<HttpInterceptor>? interceptors})
    : _client = httpClient(),
      _interceptors = interceptors ?? [];

  /// Adds an interceptor to the chain
  void addInterceptor(HttpInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  /// Processes a request through all interceptors
  Future<http.BaseRequest> _processRequest(http.BaseRequest request) async {
    var processedRequest = request;
    for (final interceptor in _interceptors) {
      processedRequest = await interceptor.interceptRequest(processedRequest);
    }
    return processedRequest;
  }

  /// Processes a response through all interceptors (in reverse order)
  Future<http.BaseResponse> _processResponse(http.BaseResponse response) async {
    var processedResponse = response;
    for (final interceptor in _interceptors.reversed) {
      processedResponse = await interceptor.interceptResponse(
        processedResponse,
      );
    }
    return processedResponse;
  }

  /// Sends a request with all interceptors applied
  Future<http.Response> send(http.BaseRequest request) async {
    final processedRequest = await _processRequest(request);
    final streamedResponse = await _client.send(processedRequest);
    final processedResponse = await _processResponse(streamedResponse);

    if (processedResponse is http.StreamedResponse) {
      return await http.Response.fromStream(processedResponse);
    }

    throw Exception(
      'Unexpected response type: ${processedResponse.runtimeType}',
    );
  }

  /// Performs an HTTP request with the given method, applying all interceptors
  Future<http.Response> _performRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final request = http.Request(method, url);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      }
    }
    if (encoding != null) {
      request.encoding = encoding;
    }
    return await send(request);
  }

  /// Performs a GET request with interceptors
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return _performRequest('GET', url, headers: headers);
  }

  /// Performs a POST request with interceptors
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequest(
      'POST',
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// Performs a PUT request with interceptors
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequest(
      'PUT',
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// Performs a DELETE request with interceptors
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequest(
      'DELETE',
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// Performs a PATCH request with interceptors
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _performRequest(
      'PATCH',
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// Closes the client when done
  void close() {
    _client.close();
  }
}
