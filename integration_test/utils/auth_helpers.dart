import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_view.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../mocks/fake_revenuecat_client.dart';
import '../mocks/fake_services.dart';
import '../mocks/fake_user_repository.dart';
import '../mocks/mock_data_sources.dart';
import 'pump_helpers.dart';
import 'test_app.dart';

/// Creates a [supabase.Session] for the given [user].
supabase.Session createTestSession(User user) {
  return supabase.Session(
    accessToken: 'test-token',
    tokenType: 'bearer',
    user: supabase.User(
      id: user.id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: user.createdAt.toIso8601String(),
    ),
  );
}

/// Sets up the full test app, initializes services, and fires the auth event
/// to land on [HomeView] with the given [user].
///
/// Returns the [StreamController] for auth state events so callers can
/// simulate additional auth transitions (sign-out, token-refresh, etc.).
///
/// Flow mirrors the real app startup:
/// 1. `rcService.init()` (SDK ready before auth rehydration)
/// 2. `authService.init()` (sees no current session → Unauthenticated)
/// 3. Navigate to `/auth` route
/// 4. Fire `signedIn` event → rehydration → AuthenticatedOnline → identify() → navigates to `/`
/// 5. [HomeView] loads with `HomeViewModel.init()`
///
/// Optional parameters:
/// - [rcClient]: A [FakeRevenueCatClient] for controlling RC behaviour.
/// - [initialSnapshot]: The initial [EntitlementSnapshot] to seed on the RC client.
/// - [prefs]: [SharedPreferences] instance. If omitted, mock-empty prefs are created.
/// - [connectivityService]: Override for [ConnectivityService].
///   Defaults to [FakeConnectivityService] (always online).
/// - [userBootstrapService]: Override for [UserBootstrapService].
///   Defaults to [FakeUserBootstrapService] returning [user].
Future<StreamController<supabase.AuthState>> pumpToHomeWithUser({
  required WidgetTester tester,
  required User user,
  required FakeRevenueCatClient rcClient,
  EntitlementSnapshot? initialSnapshot,
  SharedPreferences? prefs,
  ConnectivityService? connectivityService,
  UserBootstrapService? userBootstrapService,
  UserRepository? userRepository,
}) async {
  // Resolve defaults
  final effectivePrefs = prefs ??
      await () async {
        SharedPreferences.setMockInitialValues({});
        return SharedPreferences.getInstance();
      }();

  // Set initial snapshot if provided
  if (initialSnapshot != null) {
    rcClient.setSnapshot(initialSnapshot);
  }

  final authStateController =
      StreamController<supabase.AuthState>.broadcast();

  final mockAuth = MockGoTrueClient();
  when(() => mockAuth.onAuthStateChange)
      .thenAnswer((_) => authStateController.stream);
  when(() => mockAuth.currentSession).thenReturn(null);

  final mockDataSource = MockDataSourceAbstraction();
  when(() => mockDataSource.auth).thenReturn(mockAuth);

  final app = await createTestApp(
    sharedPreferences: effectivePrefs,
    dataSource: mockDataSource,
    connectivityService:
        connectivityService ?? FakeConnectivityService(),
    userBootstrapService:
        userBootstrapService ?? FakeUserBootstrapService(user),
    revenueCatClient: rcClient,
    userRepository: userRepository ?? FakeUserRepository(user),
  );

  await tester.pumpWidget(app);

  // Step 1: Init RevenueCat BEFORE auth (mirrors StartupViewModel order)
  final rcService = locator<RevenueCatService>();
  await rcService.init();

  // Step 2: Init auth (no current session → Unauthenticated)
  final authService = locator<AuthService>();
  await authService.init();

  // Step 3: Navigate to auth route
  final routerService = locator<RouterService>();
  routerService.replaceAll([Path(name: '/auth')]);
  await tester.pumpAndSettle();

  // Step 4: Fire signedIn event → rehydration → identify() → navigate to home
  authStateController.add(
    supabase.AuthState(
      supabase.AuthChangeEvent.signedIn,
      createTestSession(user),
    ),
  );

  // Step 5: Wait for HomeView to appear
  await tester.pumpUntilFound(find.byType(HomeView));

  return authStateController;
}
