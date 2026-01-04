import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/best_router.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Navigation Tests', () {
    late RouterService routerService;
    late List<RouteEntry> testRoutes;

    setUp(() {
      // Define test routes
      testRoutes = [
        RouteEntry(path: '/', builder: (key, routeData) => const HomePage()),
        RouteEntry(
          path: '/details',
          builder: (key, routeData) => DetailsPage(
            id: routeData.queryParameters['id'],
            category: routeData.queryParameters['category'],
          ),
        ),
        RouteEntry(
          path: '/products/:id',
          builder: (key, routeData) => ProductPage(
            id: routeData.pathParameters['id'] ?? '',
            color: routeData.queryParameters['color'],
            size: routeData.queryParameters['size'],
          ),
        ),
        RouteEntry(
          path: '/users/:userId/posts/:postId',
          builder: (key, routeData) => UserPostPage(
            userId: routeData.pathParameters['userId'] ?? '',
            postId: routeData.pathParameters['postId'] ?? '',
          ),
        ),
        RouteEntry(
          path: '/settings',
          builder: (key, routeData) => const SettingsPage(),
        ),
        RouteEntry(
          path: '/404',
          builder: (key, routeData) => const NotFoundPage(),
        ),
        RouteEntry(
          path: '/pop-scope',
          builder: (key, routeData) {
            final canPop = routeData.queryParameters['canPop'] != 'false';
            return PopScopePage(key: key, canPop: canPop);
          },
        ),
      ];

      // Initialize router service with test routes
      routerService = RouterService(supportedRoutes: testRoutes);
    });

    Widget createTestApp() {
      return MaterialApp.router(
        routerConfig: BestRouterConfig(routerService: routerService),
      );
    }

    testWidgets('Initial route should be home', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(routerService.navigationStack.value.length, 1);
      expect(routerService.navigationStack.value.first.pathWithParams, '/');
    });

    testWidgets('Go to should add new route to stack', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      routerService.goTo(Path(name: '/details'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(routerService.navigationStack.value.length, 2);
      expect(
        routerService.navigationStack.value.last.pathWithParams,
        '/details',
      );
    });

    testWidgets('Back should remove last route from stack', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      routerService.goTo(Path(name: '/details'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsPage), findsOneWidget);

      routerService.back();
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(DetailsPage), findsNothing);
      expect(routerService.navigationStack.value.length, 1);
      expect(routerService.navigationStack.value.last.pathWithParams, '/');
    });

    testWidgets('Replace should replace last route in stack', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      routerService.goTo(Path(name: '/details'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsPage), findsOneWidget);

      routerService.replace(Path(name: '/settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(DetailsPage), findsNothing);
      expect(routerService.navigationStack.value.length, 2);
      expect(
        routerService.navigationStack.value.last.pathWithParams,
        '/settings',
      );
    });

    testWidgets('Replace all should clear stack and set new route', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      routerService.goTo(Path(name: '/details'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsPage), findsOneWidget);

      routerService.replaceAll([Path(name: '/settings')]);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byType(DetailsPage), findsNothing);
      expect(routerService.navigationStack.value.length, 1);
      expect(
        routerService.navigationStack.value.last.pathWithParams,
        '/settings',
      );
    });

    testWidgets('Replace all should clear stack and set new routes', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      routerService.goTo(Path(name: '/details'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailsPage), findsOneWidget);

      routerService.replaceAll([
        Path(name: '/'),
        Path(name: '/settings'),
        Path(name: '/details'),
        Path(name: '/products/456'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(DetailsPage), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(ProductPage), findsOneWidget);
      expect(routerService.navigationStack.value.length, 4);
      expect(
        routerService.navigationStack.value.last.pathWithParams,
        '/products/456',
      );
    });

    testWidgets(
      'Replace all with less routes than before should clear stack and set new routes',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/details'));
        routerService.goTo(Path(name: '/products/456'));
        routerService.goTo(Path(name: '/users/123/posts/789'));
        await tester.pumpAndSettle();

        expect(find.byType(UserPostPage), findsOneWidget);

        routerService.replaceAll([Path(name: '/'), Path(name: '/settings')]);
        await tester.pumpAndSettle();

        expect(find.byType(SettingsPage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 2);
        expect(
          routerService.navigationStack.value.last.pathWithParams,
          '/settings',
        );
      },
    );

    testWidgets(
      'Go to invalid route should navigate to 404 and keep the previous route',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/invalid-route'));
        await tester.pumpAndSettle();

        expect(find.byType(NotFoundPage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 2);
        expect(routerService.navigationStack.value.last.pathWithParams, '/404');
      },
    );

    group('Route Parameters Tests', () {
      testWidgets('Should handle query parameters correctly', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/details?id=123&category=books'));
        await tester.pumpAndSettle();

        expect(find.text('Details: 123 - books'), findsOneWidget);
        expect(routerService.navigationStack.value.last.queryParameters, {
          'id': '123',
          'category': 'books',
        });
      });

      testWidgets('Should handle path parameters correctly', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/products/456'));
        await tester.pumpAndSettle();

        expect(find.text('Product: 456'), findsOneWidget);
        expect(routerService.navigationStack.value.last.pathParameters, {
          'id': '456',
        });
      });

      testWidgets('Should handle multiple path parameters correctly', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/users/123/posts/789'));
        await tester.pumpAndSettle();

        expect(find.text('User 123 - Post 789'), findsOneWidget);
        expect(routerService.navigationStack.value.last.pathParameters, {
          'userId': '123',
          'postId': '789',
        });
      });

      testWidgets('Should handle mixed query and path parameters', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        routerService.goTo(Path(name: '/products/456?color=red&size=large'));
        await tester.pumpAndSettle();

        expect(find.text('Product: 456 (red, large)'), findsOneWidget);
        expect(routerService.navigationStack.value.last.queryParameters, {
          'color': 'red',
          'size': 'large',
        });
      });
    });

    group('PopScope Tests', () {
      testWidgets('Should allow back when canPop is true', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to PopScope page
        routerService.goTo(Path(name: '/pop-scope'));
        await tester.pumpAndSettle();

        expect(find.byType(PopScopePage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 2);

        // Trigger pop through Navigator
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 1);
      });

      testWidgets('Should prevent back when canPop is false', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to PopScope page with canPop set to false
        routerService.goTo(Path(name: '/pop-scope?canPop=false'));
        await tester.pumpAndSettle();

        expect(find.byType(PopScopePage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 2);

        // Attempt to pop through Navigator
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Verify pop was prevented
        expect(find.byType(PopScopePage), findsOneWidget);
        expect(routerService.navigationStack.value.length, 2);
      });
    });
  });

  group('Onboarding Guard Tests', () {
    late RouterService routerService;
    late NavigationIntentStore intentStore;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      locator.reset();
      locator.registerMany([
        Module<NavigationIntentStore>(
          builder: () => NavigationIntentStore(prefs),
          lazy: true,
        ),
      ]);
      intentStore = locator<NavigationIntentStore>();
      routerService = RouterService(
        supportedRoutes: [
          RouteEntry(
            path: '/',
            builder: (key, routeData) => const Placeholder(),
          ),
          RouteEntry(
            path: '/details',
            builder: (key, routeData) => const Placeholder(),
          ),
          RouteEntry(
            path: '/auth',
            builder: (key, routeData) => const Placeholder(),
          ),
          RouteEntry(
            path: '/onboarding',
            builder: (key, routeData) => const Placeholder(),
          ),
        ],
      );
      routerService.setOnboardingGuard(() => true);
    });

    tearDown(() {
      locator.reset();
    });

    testWidgets('goTo_onboardingGuardTrue_redirectsToOnboarding', (tester) async {
      routerService.goTo(Path(name: '/details?from=link'));
      await tester.pump();

      expect(
        routerService.navigationStack.value.last.pathWithParams,
        '/onboarding',
      );
      expect(intentStore.getIntendedRoute(), '/details?from=link');
    });

    testWidgets(
      'goTo_onboardingGuardTrue_ineligibleRouteDoesNotOverwriteIntendedRoute',
      (tester) async {
        await intentStore.saveIntendedRoute('/details?prev=true');
        routerService.goTo(Path(name: '/auth?foo=bar'));
        await tester.pump();

        expect(intentStore.getIntendedRoute(), '/details?prev=true');
      },
    );

    testWidgets(
      'replaceAllWithRoute_onboardingGuardTrue_redirectsToOnboarding',
      (tester) async {
        final resolvedRoute = RouteData(
          uri: Uri.parse('/details?from=restore'),
          routePattern: '/details',
        );

        routerService.replaceAllWithRoute(resolvedRoute);
        await tester.pump();

        expect(routerService.navigationStack.value.length, 1);
        expect(
          routerService.navigationStack.value.first.pathWithParams,
          '/onboarding',
        );
        expect(intentStore.getIntendedRoute(), '/details?from=restore');
      },
    );
  });
}

// Test pages
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, this.id, this.category});

  final String? id;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Details: $id - $category')));
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.id, this.color, this.size});

  final String id;
  final String? color;
  final String? size;

  @override
  Widget build(BuildContext context) {
    if (color != null || size != null) {
      return Scaffold(
        body: Center(child: Text('Product: $id ($color, $size)')),
      );
    }
    return Scaffold(body: Center(child: Text('Product: $id')));
  }
}

class UserPostPage extends StatelessWidget {
  const UserPostPage({super.key, required this.userId, required this.postId});

  final String userId;
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('User $userId - Post $postId')));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Settings')));
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404')));
  }
}

// Add PopScopePage for testing PopScope behavior
class PopScopePage extends StatelessWidget {
  const PopScopePage({super.key, this.canPop = true, this.onPopInvoked});

  final bool canPop;
  final PopInvokedWithResultCallback<dynamic>? onPopInvoked;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvoked,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pop Scope Page')),
        body: const Center(child: Text('Pop Scope Page')),
      ),
    );
  }
}
