import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/data/user_bootstrap_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../mocks/mock_services.dart';

class MockDataSourceAbstraction extends Mock implements DataSourceAbstraction {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class MockUserBootstrapService extends Mock implements UserBootstrapService {}

class MockNavigationIntentStore extends Mock implements NavigationIntentStore {}

class MockCachedUserStore extends Mock implements CachedUserStore {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

void main() {
  late MockDataSourceAbstraction mockDataSource;
  late MockGoTrueClient mockGoTrueClient;
  late MockUserBootstrapService mockUserBootstrapService;
  late MockNavigationIntentStore mockNavigationIntentStore;
  late MockCachedUserStore mockCachedUserStore;
  late MockRouterService mockRouterService;
  late MockConnectivityService mockConnectivityService;
  late MockAppLifecycleService mockAppLifecycleService;
  late MockRevenueCatService mockRevenueCatService;
  late MockUserOrientService mockUserOrientService;

  late AuthService authService;

  setUpAll(() {
    registerFallbackValue(supabase.SignOutScope.local);
  });

  setUp(() {
    mockDataSource = MockDataSourceAbstraction();
    mockGoTrueClient = MockGoTrueClient();
    mockUserBootstrapService = MockUserBootstrapService();
    mockNavigationIntentStore = MockNavigationIntentStore();
    mockCachedUserStore = MockCachedUserStore();
    mockRouterService = MockRouterService();
    mockConnectivityService = MockConnectivityService();
    mockAppLifecycleService = MockAppLifecycleService();
    mockRevenueCatService = MockRevenueCatService();
    mockUserOrientService = MockUserOrientService();

    when(() => mockDataSource.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockConnectivityService.status,
    ).thenReturn(ValueNotifier(NetworkStatus.online));

    authService = AuthService(
      dataSource: mockDataSource,
      userBootstrapService: mockUserBootstrapService,
      navigationIntentStore: mockNavigationIntentStore,
      cachedUserStore: mockCachedUserStore,
      routerService: mockRouterService,
      connectivityService: mockConnectivityService,
      appLifecycleService: mockAppLifecycleService,
      revenueCatService: mockRevenueCatService,
      userOrientService: mockUserOrientService,
    );
  });

  group('AuthService UserOrient cleanup', () {
    group('logout()', () {
      test('calls UserOrientService.clearCache()', () async {
        // Arrange: stub all logout dependencies
        when(
          () => mockRevenueCatService.logout(),
        ).thenAnswer((_) async {});
        when(
          () => mockUserOrientService.clearCache(),
        ).thenAnswer((_) async {});
        when(
          () => mockGoTrueClient.signOut(
            scope: any(named: 'scope'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockCachedUserStore.clearUser()).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.clearIntendedRoute(),
        ).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.clearAuthEmail(),
        ).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.setForceOnboarding(),
        ).thenAnswer((_) async {});
        when(
          () => mockAppLifecycleService.restartApp(),
        ).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(() => mockUserOrientService.clearCache()).called(1);
      });

      test('continues logout even if clearCache() throws', () async {
        when(
          () => mockRevenueCatService.logout(),
        ).thenAnswer((_) async {});
        when(
          () => mockUserOrientService.clearCache(),
        ).thenThrow(Exception('cache error'));
        when(
          () => mockGoTrueClient.signOut(
            scope: any(named: 'scope'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockCachedUserStore.clearUser()).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.clearIntendedRoute(),
        ).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.clearAuthEmail(),
        ).thenAnswer((_) async {});
        when(
          () => mockNavigationIntentStore.setForceOnboarding(),
        ).thenAnswer((_) async {});
        when(
          () => mockAppLifecycleService.restartApp(),
        ).thenAnswer((_) async {});

        // Should not throw -- clearCache failure is caught
        await authService.logout();

        // Supabase signOut still called
        verify(
          () => mockGoTrueClient.signOut(
            scope: any(named: 'scope'),
          ),
        ).called(1);
      });
    });

    group('_handleAuthChange signedOut', () {
      test('calls UserOrientService.clearCache() on signedOut event',
          () async {
        // Arrange: stub auth stream to emit signedOut
        final authStreamController =
            StreamController<supabase.AuthState>.broadcast();
        when(() => mockGoTrueClient.onAuthStateChange)
            .thenAnswer((_) => authStreamController.stream);
        when(() => mockGoTrueClient.currentSession).thenReturn(null);
        when(() => mockConnectivityService.init()).thenAnswer((_) async {});

        when(
          () => mockRevenueCatService.logout(),
        ).thenAnswer((_) async {});
        when(
          () => mockUserOrientService.clearCache(),
        ).thenAnswer((_) async {});
        when(() => mockCachedUserStore.clearUser()).thenAnswer((_) async {});
        when(() => mockCachedUserStore.loadUser()).thenAnswer((_) async => null);

        // Init to wire up the auth subscription
        await authService.init();

        // Act: emit signedOut event
        authStreamController.add(
          const supabase.AuthState(
            supabase.AuthChangeEvent.signedOut,
            null,
          ),
        );

        // Allow microtask queue to process
        await Future<void>.delayed(Duration.zero);

        // Assert
        verify(() => mockUserOrientService.clearCache()).called(1);

        // Cleanup
        await authStreamController.close();
        authService.dispose();
      });
    });
  });
}
