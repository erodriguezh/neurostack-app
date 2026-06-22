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
  return uri.path == '/auth/callback';
}

Uri normalizeAuthCallbackUri(Uri uri) {
  if (!isAuthCallbackUri(uri)) {
    return uri;
  }
  return Uri(path: '/auth');
}

/// Splits a path into segments, filtering out empty segments
List<String> getSegments(String path) =>
    path.split('/').where((s) => s.isNotEmpty).toList();
