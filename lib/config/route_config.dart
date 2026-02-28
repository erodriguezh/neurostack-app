import 'package:neurostack/home/home_view.dart';
import 'package:neurostack/library/library_view.dart';
import 'package:neurostack/paywall/paywall_view.dart';
import 'package:neurostack/progress/progress_view.dart';
import 'package:neurostack/settings/contact_view.dart';
import 'package:neurostack/settings/settings_view.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/not_found/not_found_view.dart';
import 'package:neurostack/features/auth/presentation/auth_callback_view.dart';
import 'package:neurostack/features/auth/presentation/auth_view.dart';
import 'package:neurostack/features/auth/presentation/check_email_view.dart';
import 'package:neurostack/features/onboarding/presentation/onboarding_view.dart';
import 'package:neurostack/features/offline/offline_retry_view.dart';

final routes = [
  RouteEntry(
    path: '/',
    requiresAuth: true,
    builder: (key, routeData) => const HomeView(),
  ),
  RouteEntry(
    path: '/library',
    requiresAuth: true,
    builder: (key, routeData) => const LibraryView(),
  ),
  RouteEntry(
    path: '/week',
    requiresAuth: true,
    builder: (key, routeData) => const ProgressView(),
  ),
  RouteEntry(
    path: '/paywall',
    requiresAuth: true,
    builder: (key, routeData) => const PaywallView(),
  ),
  RouteEntry(
    path: '/settings',
    requiresAuth: true,
    builder: (key, routeData) => const SettingsView(),
  ),
  RouteEntry(
    path: '/settings/contact',
    requiresAuth: true,
    builder: (key, routeData) => const ContactView(),
  ),
  RouteEntry(path: '/auth', builder: (key, routeData) => const AuthView()),
  RouteEntry(
    path: '/auth/callback',
    requiresAuth: false,
    builder: (key, routeData) =>
        AuthCallbackView(key: key, routeData: routeData),
  ),
  RouteEntry(
    path: '/auth/check-email',
    builder: (key, routeData) => const CheckEmailView(),
  ),
  RouteEntry(
    path: '/onboarding',
    builder: (key, routeData) => OnboardingView(key: key),
  ),
  RouteEntry(path: '/404', builder: (key, routeData) => const NotFoundView()),
  RouteEntry(
    path: '/offline',
    builder: (key, routeData) => const OfflineRetryView(),
  ),
];
