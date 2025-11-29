import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/navigation/utils.dart';

class RouteEntry {
  RouteEntry({required this.path, required this.builder});

  final String path;
  final Widget Function(ValueKey<String>? key, RouteData routeData) builder;
}

class Path {
  Path({required this.name, this.extra});

  final String name;
  final Object? extra;
}

class RouteData {
  const RouteData({required this.uri, required this.routePattern, this.extra});

  final Uri uri;
  final String routePattern;
  final Object? extra;

  String get pathWithParams => uri.toString();

  Map<String, String> get queryParameters => uri.queryParameters;

  Map<String, String> get pathParameters {
    final params = <String, String>{};
    final pathSegments = uri.pathSegments;
    final patternSegments = getSegments(routePattern);

    if (patternSegments.length != pathSegments.length) return params;

    for (var i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) {
        final paramName = patternSegments[i].substring(1);
        params[paramName] = pathSegments[i];
      }
    }

    return params;
  }

  @override
  String toString() {
    return 'RouteData(uri: $uri, routePattern: $routePattern, queryParameters: $queryParameters, pathParameters: $pathParameters, extra: $extra)';
  }

  @override
  bool operator ==(Object other) {
    return other is RouteData &&
        uri == other.uri &&
        routePattern == other.routePattern &&
        extra == other.extra;
  }

  @override
  int get hashCode => uri.hashCode;
}
