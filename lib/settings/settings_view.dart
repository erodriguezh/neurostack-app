import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/settings/settings_view_model.dart';

/// Settings view providing user account actions.
///
/// Placeholder layout until Phase 3 rewrites this as a tab screen
/// with upgrade banner, support tiles, and bottom nav.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel _viewModel = SettingsViewModel(
    routerService: locator<RouterService>(),
    authService: locator<AuthService>(),
    subscriptionStatusResolver: locator<SubscriptionStatusResolver>(),
    revenueCatService: locator<RevenueCatService>(),
    cachedUserStore: locator<CachedUserStore>(),
  );

  @override
  void initState() {
    super.initState();
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final kitColors = context.kitColors;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.sm,
                    spacing.sm,
                    spacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          LucideIcons.chevronLeft,
                          color: kitColors.white90,
                        ),
                        onPressed: () => locator<RouterService>().back(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: context.theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.8,
                          color: kitColors.white90,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: spacing.lg)),

              // Placeholder content (Phase 3 will rewrite as tab screen)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Settings content coming in Phase 3',
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: kitColors.white40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
