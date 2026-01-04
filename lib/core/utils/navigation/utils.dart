import 'package:neurostack/core/utils/navigation/route_data.dart';

bool matchRoute(String pattern, Uri path) {
  final pathSegments = path.pathSegments;
  final patternSegments = getSegments(pattern);

  if (patternSegments.length != pathSegments.length) return false;

  for (var i = 0; i < patternSegments.length; i++) {
    if (patternSegments[i].startsWith(':')) continue;
    if (patternSegments[i] != pathSegments[i]) return false;
  }

  return true;
}

String findMatchingRoutePattern(Uri path, List<RouteEntry> routes) {
  final route = routes.firstWhere(
    (route) => matchRoute(route.path, path),
    orElse: () => routes.firstWhere((route) => route.path == '/404'),
  );
  return route.path;
}

bool isAuthCallbackUri(Uri uri) {
  if (uri.path == '/auth/callback') {
    return true;
  }
  return _hasAuthTokens(uri);
}

Uri normalizeAuthCallbackUri(Uri uri) {
  if (!isAuthCallbackUri(uri)) {
    return uri;
  }
  if (uri.path == '/auth/callback') {
    return uri;
  }
  return uri.replace(path: '/auth/callback');
}

Map<String, String> parseFragmentParams(String fragment) {
  final cleaned = fragment.startsWith('#') ? fragment.substring(1) : fragment;
  if (cleaned.isEmpty) {
    return const {};
  }
  final params = <String, String>{};
  for (final part in cleaned.split('&')) {
    if (part.isEmpty) {
      continue;
    }
    final separatorIndex = part.indexOf('=');
    if (separatorIndex == -1) {
      params[Uri.decodeComponent(part)] = '';
      continue;
    }
    final key = Uri.decodeComponent(part.substring(0, separatorIndex));
    final value = Uri.decodeComponent(part.substring(separatorIndex + 1));
    params[key] = value;
  }
  return params;
}

bool _hasAuthTokens(Uri uri) {
  return _containsAuthToken(uri.queryParameters) ||
      _containsAuthToken(parseFragmentParams(uri.fragment));
}

bool _containsAuthToken(Map<String, String> params) {
  return params.containsKey('access_token') ||
      params.containsKey('refresh_token');
}

/// Splits a path into segments, filtering out empty segments
List<String> getSegments(String path) =>
    path.split('/').where((s) => s.isNotEmpty).toList();
