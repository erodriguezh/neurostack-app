import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/home/home_state.dart';

class HomeBottomTabCoordinator {
  HomeBottomTabCoordinator({
    required RouterService routerService,
    required NotifyService notifyService,
    this.comingSoonMessage = 'Coming soon',
  })  : _routerService = routerService,
        _notifyService = notifyService;

  final RouterService _routerService;
  final NotifyService _notifyService;
  final String comingSoonMessage;

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
        _notifyService.setToastEvent(
          ToastEventInfo(message: comingSoonMessage),
        );
        break;
    }
  }
}
