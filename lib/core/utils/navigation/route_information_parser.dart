import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/utils.dart';

class AppRouteInformationParser extends RouteInformationParser<RouteData> {
  AppRouteInformationParser({required this.routes});

  final List<RouteEntry> routes;

  @override
  Future<RouteData> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    return SynchronousFuture(
      RouteData(uri: uri, routePattern: findMatchingRoutePattern(uri, routes)),
    );
  }

  @override
  RouteInformation? restoreRouteInformation(RouteData configuration) {
    if (configuration.pathWithParams.isNotEmpty) {
      return RouteInformation(uri: configuration.uri);
    }

    return null;
  }
}
