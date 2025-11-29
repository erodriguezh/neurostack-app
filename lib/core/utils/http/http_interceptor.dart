import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Contract for HTTP interceptors that can modify requests and responses
abstract class HttpInterceptor {
  /// Intercepts and potentially modifies a request before it's sent
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request);

  /// Intercepts and potentially modifies a response after it's received
  Future<http.BaseResponse> interceptResponse(http.BaseResponse response);
}

/// A simplified HTTP interceptor that logs essential request and response info
class LoggingInterceptor implements HttpInterceptor {
  final Logger _logger = Logger('HttpClient');
  final bool logBody;

  LoggingInterceptor({this.logBody = false});

  @override
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request) async {
    _logger.info('--> ${request.method} ${request.url}');

    if (logBody && request is http.Request) {
      final bodyPreview = _truncateBodyIfNeeded(request.body);
      _logger.info('--> Body: $bodyPreview');
    }

    return request;
  }

  @override
  Future<http.BaseResponse> interceptResponse(
    http.BaseResponse response,
  ) async {
    _logger.info('<-- ${response.statusCode} ${response.request?.url}');

    if (logBody && response is http.Response) {
      final bodyPreview = _truncateBodyIfNeeded(response.body);
      _logger.info('<-- Body: $bodyPreview');
    }

    return response;
  }

  /// Truncates body if it's too long
  String _truncateBodyIfNeeded(String body) {
    const maxLength = 500;
    if (body.length > maxLength) {
      return '${body.substring(0, maxLength)}... (${body.length} bytes total)';
    }
    return body;
  }
}
