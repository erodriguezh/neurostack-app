import 'package:neurostack/home/home_view.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/not_found/not_found_view.dart';
import 'package:neurostack/features/auth/presentation/auth_view.dart';
import 'package:neurostack/features/auth/presentation/check_email_view.dart';

final routes = [
  RouteEntry(
    path: '/',
    requiresAuth: true,
    builder: (key, routeData) => const HomeView(),
  ),
  RouteEntry(path: '/auth', builder: (key, routeData) => const AuthView()),
  RouteEntry(
    path: '/auth/check-email',
    builder: (key, routeData) => const CheckEmailView(),
  ),
  RouteEntry(path: '/404', builder: (key, routeData) => const NotFoundView()),
];
