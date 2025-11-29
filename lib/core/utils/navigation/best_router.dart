import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:neurostack/core/utils/navigation/route_information_parser.dart';
import 'package:neurostack/core/utils/navigation/router_delegate.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';

class BestRouterConfig extends RouterConfig<Object> {
  BestRouterConfig({required RouterService routerService})
    : super(
        routerDelegate: AppRouterDelegate(routerService: routerService),
        routeInformationProvider: _createRouteInformationProvider(
          routerService,
        ),
        backButtonDispatcher: RootBackButtonDispatcher(),
        routeInformationParser: AppRouteInformationParser(
          routes: routerService.supportedRoutes,
        ),
      );

  /// Creates a [PlatformRouteInformationProvider] that initializes the app's
  /// navigation state based on both the platform's initial route and the app's
  /// own initial state.
  static PlatformRouteInformationProvider _createRouteInformationProvider(
    RouterService routerService,
  ) {
    // 1. Get the initial route from the platform (the browser URL).
    final String platformInitialRoute =
        PlatformDispatcher.instance.defaultRouteName;

    // 2. Get the initial route from [RouterService] logic.
    final String appInitialRoute = routerService.navigationStack.value.last.uri
        .toString();

    // 3. Decide which route to use.
    //    - If the platform URL is a deep link (not '/'), use it.
    //    - If the platform URL is just '/' but your app has a different initial
    //      state (e.g., '/home'), use your app's state.
    //    - Otherwise, default to the platform's route.
    final String initialLocation =
        (platformInitialRoute == '/' && appInitialRoute != '/')
        ? appInitialRoute
        : platformInitialRoute;

    return PlatformRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: Uri.parse(initialLocation),
      ),
    );
  }
}
