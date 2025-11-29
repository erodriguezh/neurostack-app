import 'package:neurostack/core/utils/navigation/route_data.dart';

abstract class NavigationObserver {
  void onPush(RouteData route);
  void onPop(RouteData route);
  void onReplace(RouteData route);
  void onRemove(RouteData route);
}

mixin ObservableRouter {
  final List<NavigationObserver> _observers = [];

  void addObserver(NavigationObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(NavigationObserver observer) {
    _observers.remove(observer);
  }

  void notifyPush(RouteData route) {
    for (final observer in _observers) {
      observer.onPush(route);
    }
  }

  void notifyPop(RouteData route) {
    for (final observer in _observers) {
      observer.onPop(route);
    }
  }

  void notifyReplace(List<RouteData> routes) {
    for (final observer in _observers) {
      for (final route in routes) {
        observer.onReplace(route);
      }
    }
  }

  void notifyRemove(RouteData route) {
    for (final observer in _observers) {
      observer.onRemove(route);
    }
  }
}
