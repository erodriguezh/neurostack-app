import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/home/home_state.dart';

class HomeBottomTabCoordinator {
  HomeBottomTabCoordinator({
    required RouterService routerService,
  }) : _routerService = routerService;

  final RouterService _routerService;

  void onSelect(HomeBottomTab tab, {required HomeBottomTab currentTab}) {
    if (tab == currentTab) {
      return;
    }

    switch (tab) {
      case HomeBottomTab.stack:
        _routerService.replaceAll([Path(name: '/')]);
        break;
      case HomeBottomTab.library:
        _routerService.replaceAll([Path(name: '/library')]);
        break;
      case HomeBottomTab.progress:
        _routerService.replaceAll([Path(name: '/week')]);
        break;
    }
  }
}
