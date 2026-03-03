import 'package:flutter/material.dart';
import 'package:neurostack/core/models/home_bottom_tab.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/ui/widgets/staggered_fade_in.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/home/widgets/home_bottom_nav.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/settings/settings_view_model.dart';
import 'package:neurostack/settings/widgets/settings_support_section.dart';
import 'package:neurostack/settings/widgets/settings_upgrade_banner.dart';

/// Settings tab screen.
///
/// Shows the screen header, an upgrade banner (for non-premium users),
/// a support & resources section with interactive tiles, and bottom
/// navigation.
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable content area
              CustomScrollView(
                key: const PageStorageKey('settings-scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header (no back button -- this is a tab screen)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacing.lg,
                        spacing.lg,
                        spacing.lg,
                        0,
                      ),
                      child: Text(
                        'Settings',
                        style: context.theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.8,
                          color: kitColors.white90,
                        ),
                      ),
                    ),
                  ),
                  // Upgrade banner (hidden for premium users)
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _viewModel.isPremium,
                      builder: (context, isPremium, _) {
                        if (isPremium) return const SizedBox.shrink();
                        return StaggeredFadeIn(
                          index: 0,
                          child: SettingsUpgradeBanner(
                            onTap: _viewModel.goToPaywall,
                          ),
                        );
                      },
                    ),
                  ),

                  // Support & Resources section
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _viewModel.isPremium,
                      builder: (context, isPremium, _) {
                        return StaggeredFadeIn(
                          index: 1,
                          child: SettingsSupportSection(
                            isPremium: isPremium,
                            onContactTap: _viewModel.goToContact,
                            onFeedbackTap: () {}, // TODO: Wiredash
                            onRateAppTap: () {}, // TODO: App Store
                            onFeatureRequestTap: () {}, // TODO: Wiredash
                            onCancelSubscriptionTap:
                                _viewModel.openSubscriptionManagement,
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom spacer to prevent content under nav bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: 120 + bottomInset),
                  ),
                ],
              ),

              // Bottom navigation
              Positioned(
                left: spacing.sm,
                right: spacing.sm,
                bottom: spacing.sm + bottomInset,
                child: HomeBottomNav(
                  activeTab: HomeBottomTab.settings,
                  onSelect: _viewModel.onSelectBottomTab,
                ),
              ),

              // Fake home indicator pill
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset > 0 ? bottomInset / 2 : 4,
                child: Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kitColors.white90.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
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
