import 'package:neurostack/home/home_view.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/not_found/not_found_view.dart';

final routes = [
  RouteEntry(path: '/', builder: (key, routeData) => const HomeView()),
  RouteEntry(path: '/404', builder: (key, routeData) => const NotFoundView()),
];
