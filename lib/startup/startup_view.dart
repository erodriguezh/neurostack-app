import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/internal_notification/internal_notification_listener.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/app_localizations.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/best_router.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';
import 'package:neurostack/startup/splash_screen.dart';
import 'package:neurostack/startup/startup_view_model.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  late final StartupViewModel _viewModel = StartupViewModel();
  late final BestRouterConfig _routerConfig;

  @override
  void initState() {
    super.initState();
    _viewModel.initializeApp();
    _routerConfig = BestRouterConfig(routerService: locator<RouterService>());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppState>(
      valueListenable: _viewModel.appStateNotifier,
      builder: (context, state, _) {
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
            return switch (state) {
              InitializingApp() => _SplashView(),
              AppInitialized() => InternalNotificationListener(child: child!),
              AppInitializationError() => _StartupErrorView(
                onRetry: _viewModel.retryInitialization,
              ),
            };
          },
        );
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

class _SplashView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
