# Integration Test Best Practices - NeuroStack

Adapted for NeuroStack's architecture: Custom ModuleLocator, ValueNotifier-based MVVM, and DataSourceAbstraction.

## Quick Reference

1. [Initialize the Integration Test Binding](#1-initialize-the-integration-test-binding) — `ensureInitialized` is mandatory.
2. [Handle Animations with Explicit Pumps](#2-handle-animations-with-explicit-pumps) — SplashScreen breathing animation (2000ms loop) requires explicit handling.
3. [Use `pumpUntilFound` Instead of Arbitrary Delays](#3-use-pumpuntilfound-instead-of-arbitrary-delays) — Polling beats sleeping.
4. [Mock at DataSourceAbstraction Boundary](#4-mock-at-datasourceabstraction-boundary) — Isolate Supabase entirely.
5. [Use Key-Based Finders](#5-use-key-based-finders) — Stop using fragile text finders.
6. [Structure Tests with the Robot Pattern](#6-structure-tests-with-the-robot-pattern) — Decouple logic from UI implementation.
7. [Reset ModuleLocator Between Tests](#7-reset-modulelocator-between-tests) — Prevent state leakage.
8. [Bootstrap App with Test Modules](#8-bootstrap-app-with-test-modules) — Override modules cleanly.
9. [Use Patrol for Native UI Interaction](#9-use-patrol-for-native-ui-interaction) — Bridge the native sandbox gap.
10. [Shard Tests in CI](#10-shard-tests-in-ci) — Parallelize to cut feedback time.
11. [iOS Release Build Text Input Workaround](#11-ios-release-build-text-input-workaround) — Fix silent input failures.

---

## Practices

### 1. Initialize the Integration Test Binding

**When:** Every integration test file, before any test runs.
**Do:** Call `ensureInitialized()` as the first line of `main()`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Critical: Configures the driver for physical device execution
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can complete onboarding', (tester) async {
    // test code
  });
}
```

**Don't:** Skip initialization or call it inside a test widget.

**Why:** Without this, the test runs as a standard widget test without the necessary bindings to communicate with the driving host or real hardware.

---

### 2. Handle Animations with Explicit Pumps

**When:** Testing screens with infinite/long animations.

**NeuroStack Screens with Animations:**

| Screen | Animation | Duration | Strategy |
|--------|-----------|----------|----------|
| SplashScreen | Breathing glow | 2000ms repeating | **Explicit pump** |
| SplashScreen | Entrance animation | 500ms | pumpAndSettle OK |
| OnboardingView | Page transitions | 750ms | pumpAndSettle OK |
| ToastView | Enter/Exit | Short | pumpAndSettle OK |

**Do:** Use `pump()` with explicit duration for SplashScreen.

```dart
// SplashScreen has infinite breathing animation - NEVER use pumpAndSettle
await tester.pumpWidget(const TestApp());
await tester.pump(const Duration(seconds: 3)); // Let splash run
expect(find.byType(OnboardingView), findsOneWidget);
```

**Don't:** Call `pumpAndSettle()` on SplashScreen.

```dart
// WRONG: Will timeout after 10 minutes
// SplashScreen._breathingController repeats infinitely
await tester.pumpAndSettle();
```

**For Other Screens:** Standard pumpAndSettle with reasonable timeout works.

```dart
// OnboardingView page transitions settle within 750ms
await tester.pumpAndSettle(const Duration(seconds: 2));
```

---

### 3. Use `pumpUntilFound` Instead of Arbitrary Delays

**When:** Waiting for async operations where timing is unknown.

**Do:** Create polling helper in `integration_test/utils/pump_helpers.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

extension PumpHelpers on WidgetTester {
  /// Pumps until finder matches or timeout expires
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(interval);
      if (any(finder)) return;
    }
    throw TimeoutException('Timed out waiting for $finder');
  }

  /// Pumps until finder is gone or timeout expires
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(interval);
      if (!any(finder)) return;
    }
    throw TimeoutException('Timed out waiting for $finder to disappear');
  }

  /// Pumps past SplashScreen's infinite animation safely
  Future<void> pumpPastSplash({Duration wait = const Duration(seconds: 2)}) async {
    await pump(wait);
  }
}
```

**Usage:**

```dart
// Wait for home screen after auth
await tester.pumpUntilFound(find.byType(HomeView));

// Wait for loading indicator to disappear
await tester.pumpUntilGone(find.byType(CircularProgressIndicator));

// Navigate past splash
await tester.pumpPastSplash();
```

**Don't:** Use hardcoded `Future.delayed`.

```dart
// WRONG: Flaky on slow devices, wasteful on fast ones
await Future.delayed(const Duration(seconds: 3));
```

---

### 4. Mock at DataSourceAbstraction Boundary

**When:** Always. Integration tests must be hermetic.

**NeuroStack Architecture:** Mock at the data source level, not the Supabase client.

**Create:** `integration_test/mocks/mock_data_sources.dart`:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/user/data/user_remote_data_source.dart';
import 'package:neurostack/features/protocol/data/protocol_remote_data_source.dart';
import 'package:neurostack/features/session/data/session_remote_data_source.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';

// Data Sources
class MockDataSourceAbstraction extends Mock implements DataSourceAbstraction {}
class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}
class MockProtocolRemoteDataSource extends Mock implements ProtocolRemoteDataSource {}
class MockSessionRemoteDataSource extends Mock implements SessionRemoteDataSource {}

// Services
class MockAuthService extends Mock implements AuthService {}
class MockOnboardingStore extends Mock implements OnboardingStore {}
class MockConnectivityService extends Mock implements ConnectivityService {}
```

**Create:** `integration_test/mocks/mock_auth_states.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/user/domain/user.dart';

/// Pre-configured auth states for testing
class MockAuthStates {
  static AuthState unauthenticated() => const Unauthenticated();

  static AuthState authenticated(User user) => Authenticated(user: user);

  static AuthState authenticationInProgress() => const AuthenticationInProgress();
}

/// ValueNotifier wrapper for controllable auth state in tests
class TestAuthStateNotifier extends ValueNotifier<AuthState> {
  TestAuthStateNotifier([AuthState initial = const Unauthenticated()])
      : super(initial);

  void setAuthenticated(User user) => value = Authenticated(user: user);
  void setUnauthenticated() => value = const Unauthenticated();
  void setLoading() => value = const AuthenticationInProgress();
}
```

**Don't:** Use real Supabase client or real network calls.

---

### 5. Use Key-Based Finders

**When:** Locating any interactive widget in tests.

**Create:** `lib/core/ui/constants/widget_keys.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Centralized widget keys for testing
abstract final class WidgetKeys {
  // Auth
  static const authEmailField = Key('auth_email_field');
  static const authSubmitButton = Key('auth_submit_button');
  static const authGoogleButton = Key('auth_google_button');

  // Onboarding
  static const onboardingNextButton = Key('onboarding_next_button');
  static const onboardingSkipButton = Key('onboarding_skip_button');
  static const onboardingPageIndicator = Key('onboarding_page_indicator');

  // Home
  static const homeStartSessionButton = Key('home_start_session_button');
  static const homeProtocolList = Key('home_protocol_list');
  static const homeProfileButton = Key('home_profile_button');

  // Navigation
  static const bottomNavHome = Key('bottom_nav_home');
  static const bottomNavSessions = Key('bottom_nav_sessions');
  static const bottomNavSettings = Key('bottom_nav_settings');
}
```

**Usage in App:**

```dart
// In auth_view.dart
TextField(
  key: WidgetKeys.authEmailField,
  decoration: const InputDecoration(labelText: 'Email'),
),
ElevatedButton(
  key: WidgetKeys.authSubmitButton,
  onPressed: _submit,
  child: const Text('Continue'),
),
```

**Usage in Tests:**

```dart
await tester.enterText(find.byKey(WidgetKeys.authEmailField), 'user@test.com');
await tester.tap(find.byKey(WidgetKeys.authSubmitButton));
```

**Don't:** Find by text.

```dart
// WRONG: Breaks if text changes or during i18n
await tester.tap(find.text('Continue'));
```

---

### 6. Structure Tests with the Robot Pattern

**When:** You have more than 3 integration tests or complex user flows.

**Create:** `integration_test/robots/robots.dart` (barrel export):

```dart
export 'auth_robot.dart';
export 'onboarding_robot.dart';
export 'home_robot.dart';
```

**Create:** `integration_test/robots/auth_robot.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import '../utils/pump_helpers.dart';

class AuthRobot {
  final WidgetTester tester;

  AuthRobot(this.tester);

  Future<void> enterEmail(String email) async {
    await tester.enterText(find.byKey(WidgetKeys.authEmailField), email);
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue() async {
    await tester.tap(find.byKey(WidgetKeys.authSubmitButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapGoogleSignIn() async {
    await tester.tap(find.byKey(WidgetKeys.authGoogleButton));
    await tester.pump(); // Don't settle - redirects to native
  }

  Future<void> login(String email) async {
    await enterEmail(email);
    await tapContinue();
  }

  void expectEmailError() {
    expect(find.text('Please enter a valid email'), findsOneWidget);
  }

  void expectOnAuthScreen() {
    expect(find.byKey(WidgetKeys.authEmailField), findsOneWidget);
  }
}
```

**Create:** `integration_test/robots/onboarding_robot.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/features/onboarding/presentation/onboarding_view.dart';
import '../utils/pump_helpers.dart';

class OnboardingRobot {
  final WidgetTester tester;

  OnboardingRobot(this.tester);

  Future<void> tapNext() async {
    await tester.tap(find.byKey(WidgetKeys.onboardingNextButton));
    await tester.pumpAndSettle(const Duration(seconds: 1)); // Page animation
  }

  Future<void> tapSkip() async {
    await tester.tap(find.byKey(WidgetKeys.onboardingSkipButton));
    await tester.pumpAndSettle();
  }

  Future<void> completeAllSteps() async {
    // Navigate through all onboarding pages
    for (var i = 0; i < 3; i++) {
      await tapNext();
    }
  }

  void expectOnOnboardingScreen() {
    expect(find.byType(OnboardingView), findsOneWidget);
  }

  void expectOnPage(int pageIndex) {
    // Verify page indicator shows correct page
    // Implementation depends on your page indicator widget
  }
}
```

**Test Usage:**

```dart
testWidgets('new user completes onboarding flow', (tester) async {
  await tester.pumpWidget(createTestApp());
  await tester.pumpPastSplash();

  final onboarding = OnboardingRobot(tester);
  onboarding.expectOnOnboardingScreen();

  await onboarding.completeAllSteps();

  final home = HomeRobot(tester);
  home.expectOnHomeScreen();
});
```

---

### 7. Reset ModuleLocator Between Tests

**When:** Every integration test to prevent state leakage.

**NeuroStack's ModuleLocator API:**

```dart
// lib/core/utils/locator.dart
final locator = ModuleLocator.instance;
locator.registerMany(modules);  // Register modules
locator<T>();                   // Retrieve module
locator.reset();                // Clear all (CRITICAL for tests)
```

**Do:** Reset in `tearDown`:

```dart
import 'package:neurostack/core/utils/locator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // Critical: Prevents mock from Test A leaking into Test B
    locator.reset();
  });

  testWidgets('test 1', (tester) async { ... });
  testWidgets('test 2', (tester) async { ... });
}
```

**Don't:** Assume clean state between tests. Singletons persist for the lifetime of the test process.

---

### 8. Bootstrap App with Test Modules

**When:** Every integration test needs controlled dependencies.

**Create:** `integration_test/utils/test_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/config/locator_config.dart';
import 'package:neurostack/startup/startup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/mock_data_sources.dart';

/// Test module builder that overrides real services with mocks
List<Module> buildTestModules({
  MockAuthService? authService,
  MockUserRemoteDataSource? userDataSource,
  MockProtocolRemoteDataSource? protocolDataSource,
  MockSessionRemoteDataSource? sessionDataSource,
  MockConnectivityService? connectivityService,
}) {
  // Start with default modules
  final modules = buildModules();

  // Create overrides map
  final overrides = <Type, Module>{};

  if (authService != null) {
    overrides[AuthService] = Module<AuthService>(() => authService, lazy: false);
  }
  if (userDataSource != null) {
    overrides[UserRemoteDataSource] = Module<UserRemoteDataSource>(
      () => userDataSource,
      lazy: true,
    );
  }
  if (protocolDataSource != null) {
    overrides[ProtocolRemoteDataSource] = Module<ProtocolRemoteDataSource>(
      () => protocolDataSource,
      lazy: true,
    );
  }
  if (sessionDataSource != null) {
    overrides[SessionRemoteDataSource] = Module<SessionRemoteDataSource>(
      () => sessionDataSource,
      lazy: true,
    );
  }
  if (connectivityService != null) {
    overrides[ConnectivityService] = Module<ConnectivityService>(
      () => connectivityService,
      lazy: false,
    );
  }

  // Replace modules with overrides
  return modules.map((m) {
    final override = overrides[m.runtimeType];
    return override ?? m;
  }).toList();
}

/// Creates a test app with mocked dependencies
Future<Widget> createTestApp({
  MockAuthService? authService,
  MockUserRemoteDataSource? userDataSource,
  MockProtocolRemoteDataSource? protocolDataSource,
  MockSessionRemoteDataSource? sessionDataSource,
  MockConnectivityService? connectivityService,
}) async {
  // Reset locator before registering test modules
  locator.reset();

  // Initialize SharedPreferences for tests
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // Register test modules
  locator.registerMany(buildTestModules(
    authService: authService,
    userDataSource: userDataSource,
    protocolDataSource: protocolDataSource,
    sessionDataSource: sessionDataSource,
    connectivityService: connectivityService,
  ));

  return StartupView(sharedPreferences: prefs);
}
```

**Alternative: Direct ViewModel Testing** (for faster tests):

```dart
/// Creates a minimal test widget for a specific view
Widget createTestView<T extends Widget>({
  required T view,
  List<NavigatorObserver>? observers,
}) {
  return MaterialApp(
    home: view,
    navigatorObservers: observers ?? [],
  );
}
```

**Usage in Tests:**

```dart
testWidgets('authenticated user sees home screen', (tester) async {
  // Setup mocks
  final mockAuth = MockAuthService();
  final testUser = UserFactory.createActiveTrial();
  when(() => mockAuth.authState).thenReturn(
    ValueNotifier(Authenticated(user: testUser)),
  );
  when(() => mockAuth.init()).thenAnswer((_) async {});

  // Create app with mocks
  final app = await createTestApp(authService: mockAuth);
  await tester.pumpWidget(app);
  await tester.pumpPastSplash();
  await tester.pumpUntilFound(find.byType(HomeView));

  expect(find.byType(HomeView), findsOneWidget);
});
```

---

### 9. Use Patrol for Native UI Interaction

**When:** Testing Supabase OAuth, permissions, or native dialogs.

**Add to `pubspec.yaml`:**

```yaml
dev_dependencies:
  patrol: ^3.0.0
```

**Create:** `integration_test/native/auth_native_test.dart`:

```dart
import 'package:patrol/patrol.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';

void main() {
  patrolTest('user can sign in with Google', ($) async {
    await $.pumpWidgetAndSettle(await createTestApp());
    await $.pump(const Duration(seconds: 2)); // Past splash

    // Tap Google sign-in button
    await $(WidgetKeys.authGoogleButton).tap();

    // Handle native Google sign-in flow
    // Patrol can interact with native OAuth screens
    if (await $.native.isPermissionDialogVisible()) {
      await $.native.grantPermissionOnlyThisTime();
    }

    // Wait for redirect back to app
    await $.pumpUntilVisible($(HomeView));

    expect($(HomeView), findsOneWidget);
  });
}
```

**Don't:** Try to test OAuth flows with standard integration tests - they can't interact with native web views.

---

### 10. Shard Tests in CI

**When:** Test suite exceeds 15 minutes.

**GitHub Actions Example** (`.github/workflows/integration_test.yml`):

```yaml
name: Integration Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  integration_test:
    runs-on: macos-latest
    strategy:
      fail-fast: false
      matrix:
        shard: [0, 1, 2, 3]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run Integration Tests (Shard ${{ matrix.shard }})
        run: |
          flutter test integration_test \
            --total-shards 4 \
            --shard-index ${{ matrix.shard }} \
            --coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          flags: integration-shard-${{ matrix.shard }}
```

---

### 11. iOS Release Build Text Input Workaround

**When:** Running tests on iOS devices in Release or Profile mode.

**Do:** Register test text input in binding setup:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    // Fixes "enterText" failing silently on iOS Release builds
    binding.testTextInput.register();
  }

  testWidgets('user can enter email', (tester) async {
    // enterText will now work on iOS Release builds
    await tester.enterText(find.byKey(WidgetKeys.authEmailField), 'test@example.com');
  });
}
```

---

## Anti-Patterns for NeuroStack

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| **Not resetting locator** | Test B inherits mocks from Test A | `locator.reset()` in tearDown |
| **`pumpAndSettle` on SplashScreen** | Infinite breathing animation timeout | Use `pump(Duration(seconds: 2))` |
| **Mocking Supabase client directly** | Bypasses DataSourceAbstraction | Mock at data source level |
| **Multiple ValueNotifiers in test setup** | Inconsistent with app architecture | Single ValueNotifier per ViewModel |
| **Testing with real SharedPreferences** | State persists between tests | `SharedPreferences.setMockInitialValues({})` |
| **Text-based finders** | Fragile, breaks on i18n | Use WidgetKeys constants |
| **Skipping StartupViewModel init** | Auth/onboarding guards not set | Let StartupView initialize normally |

---

## Project Structure

```
integration_test/
├── utils/
│   ├── pump_helpers.dart           # pumpUntilFound, pumpPastSplash
│   └── test_app.dart               # createTestApp, buildTestModules
├── mocks/
│   ├── mock_data_sources.dart      # All mock classes
│   └── mock_auth_states.dart       # Pre-configured auth states
├── robots/
│   ├── robots.dart                 # Barrel export
│   ├── auth_robot.dart
│   ├── onboarding_robot.dart
│   └── home_robot.dart
├── flows/
│   ├── auth_flow_test.dart         # End-to-end auth tests
│   ├── onboarding_flow_test.dart   # Onboarding completion tests
│   └── session_flow_test.dart      # Session recording tests
└── native/
    └── oauth_test.dart             # Patrol-based native tests
```

---

## Leveraging Existing Test Infrastructure

**Reuse from `test/`:**

| Existing Asset | Location | Use In Integration Tests |
|----------------|----------|--------------------------|
| Either matchers | `test/matchers/either_matchers.dart` | Verify repository results |
| Domain factories | `test/factories/*.dart` | Create test users, protocols |
| Test constants | `test/constants/test_constants.dart` | Consistent test data |
| Data source mocks | `test/mocks/data_source_mocks.dart` | Extend for integration |

**Example using existing factories:**

```dart
import 'package:neurostack/test/factories/factories.dart';

testWidgets('premium user sees all protocols', (tester) async {
  final premiumUser = UserFactory.createPremiumMonthly();
  final protocols = [
    ProtocolFactory.create(name: 'Focus'),
    ProtocolFactory.create(name: 'Relaxation'),
  ];

  // Setup mocks with factory data
  when(() => mockAuth.authState).thenReturn(
    ValueNotifier(Authenticated(user: premiumUser)),
  );
  when(() => mockProtocolDataSource.getAll()).thenAnswer(
    (_) async => protocols.map((p) => ProtocolDto.fromDomain(p)).toList(),
  );

  // ... test continues
});
```

---

## ValueNotifier Testing Patterns

**Testing ViewModels with sealed states:**

```dart
testWidgets('shows loading then content', (tester) async {
  await tester.pumpWidget(createTestApp());

  // Initial state should be loading
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Pump until content loads
  await tester.pumpUntilFound(find.byType(ProtocolList));

  // Verify loaded state
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(ProtocolList), findsOneWidget);
});
```

**Directly controlling ViewModel state in tests:**

```dart
testWidgets('error state shows retry button', (tester) async {
  final viewModel = HomeViewModel(
    userRepository: mockUserRepo,
    protocolRepository: mockProtocolRepo,
  );

  // Force error state
  viewModel.state.value = HomeError(
    failure: const DomainFailure(
      code: 'Network.Unavailable',
      message: 'No internet connection',
    ),
  );

  await tester.pumpWidget(createTestView(
    view: HomeView(viewModel: viewModel),
  ));
  await tester.pumpAndSettle();

  expect(find.text('No internet connection'), findsOneWidget);
  expect(find.byKey(WidgetKeys.retryButton), findsOneWidget);
});
```

---

## Running Integration Tests

```bash
# Run all integration tests
flutter test integration_test

# Run specific test file
flutter test integration_test/flows/auth_flow_test.dart

# Run on specific device
flutter test integration_test -d chrome
flutter test integration_test -d iPhone

# Run with coverage
flutter test integration_test --coverage

# Run sharded (for CI)
flutter test integration_test --total-shards 4 --shard-index 0
```
