import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';

class LibraryViewModel {
  LibraryViewModel({required RouterService routerService})
      : _routerService = routerService;

  final RouterService _routerService;

  void navigateToHome() {
    _routerService.replaceAll([Path(name: '/')]);
  }
}
