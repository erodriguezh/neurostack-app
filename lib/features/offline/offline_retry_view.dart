import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/core/ui/widgets/dark_theme_scope.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/offline/offline_retry_view_model.dart';

/// Screen shown when the user is offline and has no cached session.
///
/// Provides a retry button to attempt reconnection.
class OfflineRetryView extends StatefulWidget {
  const OfflineRetryView({super.key});

  @override
  State<OfflineRetryView> createState() => _OfflineRetryViewState();
}

class _OfflineRetryViewState extends State<OfflineRetryView> {
  late final OfflineRetryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OfflineRetryViewModel(
      authService: locator<AuthService>(),
      routerService: locator<RouterService>(),
      navigationIntentStore: locator<NavigationIntentStore>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final spacing = context.spacing;

    return DarkThemeScope(
      child: AppGridBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Offline icon
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: kitColors.white30,
                  ),
                  SizedBox(height: spacing.lg),
                  // Title
                  Text(
                    "You're offline",
                    style: context.theme.textTheme.headlineSmall?.copyWith(
                      color: kitColors.white90,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing.sm),
                  // Description
                  Text(
                    "Connect to the internet to continue.",
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: kitColors.white50,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // Retry button
                  ValueListenableBuilder<bool>(
                    valueListenable: _viewModel.isRetrying,
                    builder: (context, isRetrying, _) => AppPrimaryCta(
                      label: "Try again",
                      onPressed: _viewModel.retry,
                      loading: isRetrying,
                    ),
                  ),
                  SizedBox(height: spacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
