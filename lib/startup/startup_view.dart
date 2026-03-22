import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/internal_notification/internal_notification_listener.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/app_localizations.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/best_router.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart' as auth_state;
import 'package:neurostack/startup/splash_screen.dart';
import 'package:neurostack/startup/startup_view_model.dart';

class StartupView extends StatefulWidget {
  const StartupView({
    super.key,
    @visibleForTesting this.viewModel,
  });

  /// Injected for widget tests. Production code passes null (default).
  final StartupViewModel? viewModel;

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  late final StartupViewModel _viewModel =
      widget.viewModel ?? StartupViewModel();

  /// Cached router config, created lazily on first [AppInitialized] state.
  /// Cleared to `null` on [InitializingApp] (router invalidation on retry)
  /// because `locator.reset()` destroys the old [RouterService] and the
  /// cached [BestRouterConfig] would hold a stale reference.
  BestRouterConfig? _routerConfig;

  /// Prevents multiple post-frame callbacks from being scheduled concurrently.
  /// Stays `true` until `initializeApp()` completes to avoid an infinite
  /// scheduling loop: if reset before the call, `initializeApp()` sets
  /// `InitializingApp` -> builder sees it -> schedules again -> loop.
  bool _bootstrapScheduled = false;

  @override
  void initState() {
    super.initState();
    // Bootstrap scheduling is handled in the builder callback below.
    // The initial InitializingApp state triggers the first post-frame callback.
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Non-router [MaterialApp] for splash, error, and offline states.
  /// Shares localization, theme, and [Translate.init()] with the router variant.
  Widget _buildAppShell({required Widget child}) {
    return MaterialApp(
      onGenerateTitle: (context) => context.translate.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light),
      darkTheme: AppTheme.buildTheme(Brightness.dark),
      builder: (context, _) {
        Translate.init(context);
        return child;
      },
    );
  }

  /// Router-based [MaterialApp] for the initialized app.
  Widget _buildRouterApp() {
    _routerConfig ??= BestRouterConfig(
      routerService: locator<RouterService>(),
    );
    return MaterialApp.router(
      routerConfig: _routerConfig,
      onGenerateTitle: (context) => context.translate.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light),
      darkTheme: AppTheme.buildTheme(Brightness.dark),
      builder: (context, child) {
        Translate.init(context);
        return InternalNotificationListener(
          child: _AuthStatusShell(child: child!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppState>(
      valueListenable: _viewModel.appStateNotifier,
      builder: (context, state, _) {
        if (state is InitializingApp) {
          // Clear cached router on retry so we get a fresh RouterService
          // instance after locator.reset().
          _routerConfig = null;

          // Schedule bootstrap after this frame paints — ensures the splash
          // is visible before initialization work begins. Works for both
          // initial cold start and retry (retryInitialization sets
          // InitializingApp then this callback fires on the next build).
          if (!_bootstrapScheduled) {
            _bootstrapScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _viewModel.initializeApp().whenComplete(() {
                _bootstrapScheduled = false;
              });
            });
          }
        }

        return switch (state) {
          InitializingApp() => _buildAppShell(child: const SplashScreen()),
          AppInitialized() => _buildRouterApp(),
          OfflineNoUserState() => _buildAppShell(
            child: _OfflineNoUserView(
              onRetry: _viewModel.retryInitialization,
            ),
          ),
          AppInitializationError() => _buildAppShell(
            child: _StartupErrorView(
              onRetry: _viewModel.retryInitialization,
            ),
          ),
        };
      },
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: context.theme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                context.translate.errorGeneric,
                style: context.textStyles.xxl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                context.translate.errorStartingApp,
                style: context.textStyles.standard,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.translate.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNoUserView extends StatelessWidget {
  const _OfflineNoUserView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                color: context.theme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                context.translate.offlineNoUserTitle,
                style: context.textStyles.xxl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                context.translate.offlineNoUserBody,
                style: context.textStyles.standard,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.translate.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthStatusShell extends StatefulWidget {
  const _AuthStatusShell({required this.child});

  final Widget child;

  @override
  State<_AuthStatusShell> createState() => _AuthStatusShellState();
}

class _AuthStatusShellState extends State<_AuthStatusShell> {
  late final ConnectivityService _connectivityService =
      locator<ConnectivityService>();
  late final AuthService _authService = locator<AuthService>();
  late final NotifyService _notifyService = locator<NotifyService>();

  NetworkStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _lastStatus = _connectivityService.status.value;
    _connectivityService.status.addListener(_handleConnectivityChange);
  }

  @override
  void dispose() {
    _connectivityService.status.removeListener(_handleConnectivityChange);
    super.dispose();
  }

  void _handleConnectivityChange() {
    if (!mounted) {
      return;
    }

    final currentStatus = _connectivityService.status.value;
    if (_lastStatus == currentStatus) {
      return;
    }
    _lastStatus = currentStatus;

    if (currentStatus == NetworkStatus.offline &&
        _authService.isAuthenticated) {
      _notifyService.setToastEvent(
        ToastEventWarning(message: context.translate.offlineConnectionLost),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<auth_state.AuthState>(
      valueListenable: _authService.authState,
      builder: (context, state, child) {
        if (state is auth_state.AuthenticatedOffline) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.sm,
                ),
                color: context.theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  context.translate.offlineUsingCachedData,
                  style: context.textStyles.standard,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: child!),
            ],
          );
        }
        return child!;
      },
      child: widget.child,
    );
  }
}
