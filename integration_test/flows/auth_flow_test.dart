import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/home/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../mocks/fake_services.dart';
import '../mocks/mock_data_sources.dart';
import '../utils/pump_helpers.dart';
import '../utils/test_app.dart';
import '../../test/factories/user_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('authFlow_signedIn_navigatesToHome', (tester) async {
    // Arrange
    final authStateController =
        StreamController<supabase.AuthState>.broadcast();
    addTearDown(authStateController.close);

    final mockAuth = MockGoTrueClient();
    when(() => mockAuth.onAuthStateChange)
        .thenAnswer((_) => authStateController.stream);
    when(() => mockAuth.currentSession).thenReturn(null);

    final mockDataSource = MockDataSourceAbstraction();
    when(() => mockDataSource.auth).thenReturn(mockAuth);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final app = await createTestApp(
      sharedPreferences: prefs,
      dataSource: mockDataSource,
      connectivityService: FakeConnectivityService(),
      userBootstrapService: FakeUserBootstrapService(
        UserFactory.createActiveTrial(),
      ),
    );
    addTearDown(locator.reset);

    final authService = locator<AuthService>();
    await authService.init();

    final routerService = locator<RouterService>();
    routerService.replaceAll([Path(name: '/auth')]);

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(WidgetKeys.authEmailField), findsOneWidget);

    final session = supabase.Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: supabase.User(
        id: 'test-user',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2024, 1, 1).toIso8601String(),
      ),
    );
    authStateController.add(
      supabase.AuthState(supabase.AuthChangeEvent.signedIn, session),
    );

    await tester.pumpUntilFound(find.byType(HomeView));

    // Assert
    expect(routerService.navigationStack.value.last.pathWithParams, '/');
  });
}
