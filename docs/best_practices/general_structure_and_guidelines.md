# Project Structure and Guidelines

## Architecture Overview

- Follow the MVVM (Model-View-ViewModel)
- Use ValueNotifier for state management, these are always created within a viewmodel
- Services handle app-wide state, only needed if you need to share state between viewmodels, they should be instantiated in the locator.
- ViewModels should handle page-specific state and logic
- Views should only contain UI code and other functionality related to BuildContext

## State Management

- For single values, use `ValueNotifier<T>` directly
- For multiple related values, create a state class and use `ValueNotifier<StateClass>`
- This avoids having multiple ValueNotifiers and ensures atomic updates

Example with state class:

```dart
class DogState {
  final String name;
  final int age;
  final bool isHungry;

  const DogState({
    required this.name,
    required this.age,
    required this.isHungry,
  });

  DogState copyWith({
    String? name,
    int? age,
    bool? isHungry,
  }) {
    return DogState(
      name: name ?? this.name,
      age: age ?? this.age,
      isHungry: isHungry ?? this.isHungry,
    );
  }
}

class HomeViewModel {
  const HomeViewModel({required NotifyService notifyService}) : _notifyService = notifyService;

  final NotifyService _notifyService;

  final ValueNotifier<DogState> _dogState = ValueNotifier(
    const DogState(name: 'Rex', age: 3, isHungry: false),
  );

  ValueListenable<DogState> get dogState => _dogState;

  void feedDog() {
    _dogState.value = _dogState.value.copyWith(isHungry: false);
    _notifyService.setToastEvent(ToastEventSuccess(message: 'Dog is fed'));
  }

  void dispose() {
    _dogState.dispose();
  }
}
```

Example of a view using a viewmodel:

```dart
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel = HomeViewModel(
    notifyService: locator<NotifyService>(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // build method
}
```

## Directory Structure

- `lib/`
  - `config/`: Configure routes and services
  - `core/`: Core application infrastructure
    - `abstractions/`: Wrapping external dependencies
    - `ui/`: Plain widgets and design system components
      - `constants/`: Design tokens (colors, spacing, text styles, etc.)
    - `utils/`: Shared utilities and core services
      - `http/`: HTTP client abstractions and implementations
      - `internal_notification/`: App-wide notification system
      - `l10n/`: Internationalization and localization
      - `navigation/`: Routing and navigation utilities
      - `locator.dart`: Service locator setup
  - `feature_name/`: Feature-specific code
    - For simple features (≤5 files):
      Place files directly in feature folder (e.g., `home/`, `startup/`, `not_found/`)
    - For complex features:
      - `models/`: Feature-specific models
      - `services/`: Feature-specific services
      - `viewmodels/`: Feature-specific viewmodels
      - `views/`: Feature UI components
      - `repositories/`: (Optional) Feature-specific data layer

## Service Locator and Dependency Injection

The app uses a custom service locator for dependency injection, defined in `core/utils/locator.dart`.

### Registering Services

Services are registered in `config/locator_config.dart`:

```dart
final modules = [
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,  // Created immediately at app startup
  ),
  Module<NotifyService>(
    builder: () => NotifyService(),
    lazy: false,  // Created immediately at app startup
  ),
  Module<HttpAbstraction>(
    builder: () => HttpAbstraction(interceptors: [...]),
    lazy: true,   // Created when first requested
  ),
];
```

### Using Services in ViewModels

ViewModels should inject services through constructor parameters:

```dart
class HomeViewModel {
  const HomeViewModel({
    required NotifyService notifyService,
    required RouterService routerService,
  }) : _notifyService = notifyService,
       _routerService = routerService;

  final NotifyService _notifyService;
  final RouterService _routerService;

  // ... rest of implementation
}
```

### Accessing Services in Views

Views should inject services when creating ViewModels, you then would use the services features through the ViewModel:

```dart
class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel = HomeViewModel(
    notifyService: locator<NotifyService>(),
    routerService: locator<RouterService>(),
  );

  // ... rest of implementation
}
```

### Lazy vs Non-Lazy Services

- **`lazy: false`** - Service is created immediately at app startup (e.g., RouterService, NotifyService)
- **`lazy: true`** - Service is created when first requested (e.g., HttpAbstraction)

## Routing and Navigation

The app uses a custom routing system built around `RouterService` for navigation management.

### Creating New Routes

1. **Define routes in `config/route_config.dart`:**

```dart
final routes = [
  RouteEntry(path: '/', builder: (key, routeData) => const HomeView()),
  RouteEntry(path: '/profile/:userId', builder: (key, routeData) => const ProfileView(userId: routeData.pathParameters['userId'])),
  RouteEntry(path: '/404', builder: (key, routeData) => const NotFoundView()),
];
```

### Navigation in ViewModels

ViewModels should inject `RouterService` and use it for navigation:

```dart
class NotFoundViewModel {
  final RouterService _routerService;

  NotFoundViewModel({required RouterService routerService})
    : _routerService = routerService;

  void navigateToHome() {
    _routerService.goTo(Path(name: '/'));
  }

  void navigateToProfile(String userId) {
    _routerService.goTo(Path(name: '/profile/$userId'));
  }

  void replaceWithHome() {
    _routerService.replace(Path(name: '/'));
  }
}
```

### Route Data Access

Routes can access path parameters, query parameters, and extra data:

```dart
// In your view builder
RouteEntry(
  path: '/profile/:userId',
  builder: (key, routeData) {
    final userId = routeData.pathParameters['userId'];
    final tab = routeData.queryParameters['tab'];
    return ProfileView(userId: userId, initialTab: tab);
  },
),
```

## Architecture Rules - IMPORTANT

1. Views should never use services directly, just view models.
2. In theory, the view should contain no logic (this is not always possible) but defer logic to the view model as much as possible (that is its role)
3. View models should never use other view models. Move that shared functionality into a service and consume it from there.
4. View models should not have access to BuildContext. Defer to the view.
5. Dependencies should always be injected through the constructor.
6. ViewModels are responsible for cleaning up their own resources. Views should call the ViewModel's dispose method.
7. ValueNotifiers and other resources should be disposed in the ViewModel's dispose method, not directly in the View.