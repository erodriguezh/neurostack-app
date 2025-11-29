import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart'
    show RouteData;
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/navigation/utils.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppRouterDelegate extends RouterDelegate<RouteData> {
  AppRouterDelegate({required RouterService routerService})
    : _routerService = routerService;

  final RouterService _routerService;

  List<Page<dynamic>> createPages() {
    List<Page<dynamic>> pages = [];
    for (RouteData routeData in _routerService.navigationStack.value) {
      final matchedRoute = _routerService.supportedRoutes.firstWhere(
        (route) => matchRoute(route.path, routeData.uri),
      );

      Widget child = matchedRoute.builder(
        ValueKey(routeData.pathWithParams),
        routeData,
      );

      pages.add(
        MaterialPage(key: ValueKey('Page_${routeData.hashCode}'), child: child),
      );
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: createPages(),
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        if (route.didPop(result)) {
          _routerService.back();
          return true;
        }
        return false;
      },
    );
  }

  @override
  Future<bool> popRoute() async {
    if (_routerService.navigationStack.value.length > 1) {
      _routerService.back();
      return SynchronousFuture(true);
    }
    return SynchronousFuture(false);
  }

  @override
  RouteData? get currentConfiguration {
    if (_routerService.navigationStack.value.isEmpty) {
      return null;
    }
    return _routerService.navigationStack.value.last;
  }

  @override
  Future<void> setNewRoutePath(RouteData configuration) async {
    if (currentConfiguration == configuration) {
      return SynchronousFuture<void>(null);
    }
    SynchronousFuture(_routerService.replaceAllWithRoute(configuration));
  }

  @override
  void addListener(VoidCallback listener) {
    _routerService.navigationStack.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerService.navigationStack.removeListener(listener);
  }
}
