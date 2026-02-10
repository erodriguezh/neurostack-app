import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/spacing.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/session/presentation/log_session_modal.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';
import 'package:neurostack/paywall/data/trial_reminder_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/paywall/widgets/trial_expired_modal.dart';
import 'package:neurostack/paywall/widgets/trial_reminder_alert.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/home/home_view_model.dart';
import 'package:neurostack/home/widgets/home_bottom_nav.dart';
import 'package:neurostack/home/widgets/home_empty_state.dart';
import 'package:neurostack/home/widgets/home_header.dart';
import 'package:neurostack/home/widgets/home_protocol_card.dart';
import 'package:neurostack/home/widgets/home_status_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel = HomeViewModel(
    notifyService: locator<NotifyService>(),
    routerService: locator<RouterService>(),
    authService: locator<AuthService>(),
    userRepository: locator<UserRepository>(),
    protocolRepository: locator<ProtocolRepository>(),
    sessionRepository: locator<SessionRepository>(),
    sessionLocalDataSource: locator<SessionLocalDataSource>(),
    connectivityService: locator<ConnectivityService>(),
    subscriptionStatusResolver: locator<SubscriptionStatusResolver>(),
    revenueCatService: locator<RevenueCatService>(),
    trialExpirationDecisionStore: locator<TrialExpirationDecisionStore>(),
    trialReminderService: locator<TrialReminderService>(),
  );

  bool _showingTrialExpired = false;
  bool _showingGraceModal = false;
  bool _showingDeactivationModal = false;
  bool _showingLogSessionModal = false;

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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<HomeViewState>(
            valueListenable: _viewModel.state,
            builder: (context, state, child) {
              _maybeShowDialogs(state);
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          color: context.kitColors.brandSky,
                          onRefresh: _viewModel.refresh,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: _buildSlivers(
                              context,
                              state,
                              spacing,
                              bottomInset,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: spacing.sm,
                    right: spacing.sm,
                    bottom: spacing.sm + bottomInset,
                    child: HomeBottomNav(
                      activeTab: state.activeTab,
                      onSelect: _viewModel.onSelectBottomTab,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomInset > 0 ? bottomInset / 2 : 4,
                    child: Center(
                      child: Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.kitColors.white90.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    HomeViewState state,
    CustomSpacing spacing,
    double bottomInset,
  ) {
    final slivers = <Widget>[];

    if (state.banner != null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: _StaggeredFadeIn(
              index: 0,
              child: HomeStatusBanner(
                banner: state.banner!,
                onDismiss: _viewModel.dismissBanner,
                onTap: _viewModel.onTapBanner,
              ),
            ),
          ),
        ),
      );
      slivers.add(SliverToBoxAdapter(child: SizedBox(height: spacing.md)));
    }

    if (state.showTrialReminder) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: state.banner == null ? spacing.sm : 0,
              bottom: spacing.md,
            ),
            child: TrialReminderAlert(
              onUpgrade: () => _viewModel.goToPaywall(),
              onDismiss: _viewModel.dismissTrialReminder,
            ),
          ),
        ),
      );
    }

    switch (state.status) {
      case HomeStatus.loading:
        slivers.add(
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  context.kitColors.brandSky,
                ),
              ),
            ),
          ),
        );
        break;
      case HomeStatus.error:
        slivers.add(
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(message: state.errorMessage),
          ),
        );
        break;
      case HomeStatus.empty:
      case HomeStatus.populated:
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.lg,
                spacing.lg,
                0,
              ),
              child: _StaggeredFadeIn(
                index: 1,
                child: HomeHeader(onAdd: _viewModel.onAddProtocol),
              ),
            ),
          ),
        );
        slivers.add(SliverToBoxAdapter(child: SizedBox(height: spacing.md)));

        if (state.status == HomeStatus.empty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: _StaggeredFadeIn(
                  index: 2,
                  child: Padding(
                    padding: EdgeInsets.only(top: spacing.xxl),
                    child: HomeEmptyState(onBrowse: _viewModel.onBrowseLibrary),
                  ),
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = state.cards[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.md),
                      child: _StaggeredFadeIn(
                        index: index + 2,
                        child: HomeProtocolCard(
                          model: card,
                          onLogSession: () => _viewModel.onLogSession(
                            card.protocolId,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: state.cards.length,
                ),
              ),
            ),
          );
        }
    }

    if (state.status == HomeStatus.empty ||
        state.status == HomeStatus.populated) {
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(height: 120 + bottomInset),
        ),
      );
    }

    return slivers;
  }

  void _maybeShowDialogs(HomeViewState state) {
    if (!mounted) {
      return;
    }

    if (state.showTrialExpiredModal && !_showingTrialExpired) {
      _showingTrialExpired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showTrialExpiredDialog(state);
        if (!mounted) return;
        _showingTrialExpired = false;
        _viewModel.acknowledgeTrialExpiredModal();
      });
    }

    if (state.showGraceModal && !_showingGraceModal) {
      _showingGraceModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showGraceDialog();
        _showingGraceModal = false;
        _viewModel.acknowledgeGraceModal();
      });
    }

    if (state.showDeactivationModal && !_showingDeactivationModal) {
      _showingDeactivationModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showDeactivationDialog();
        _showingDeactivationModal = false;
        _viewModel.acknowledgeDeactivationModal();
      });
    }

    if (state.logSessionRequest != null && !_showingLogSessionModal) {
      _showingLogSessionModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showLogSessionModal(state, state.logSessionRequest!);
        _showingLogSessionModal = false;
        _viewModel.acknowledgeLogSessionRequest();
      });
    }
  }

  Future<void> _showLogSessionModal(
    HomeViewState state,
    LogSessionRequest request,
  ) async {
    // Use userId from already-loaded state.user (same source of truth)
    final userId = state.user?.id;
    if (userId == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Unable to identify user'),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showLogSessionModal(
      context,
      protocol: request.protocol,
      userId: userId,
      initialDate: request.initialDate,
      onSessionLogged: (session) {
        _viewModel.refresh();
      },
    );
  }

  Future<void> _showTrialExpiredDialog(HomeViewState state) async {
    while (true) {
      if (!mounted) return;

      // Use latest protocol count each iteration
      final currentProtocolCount =
          _viewModel.state.value.user?.activeProtocolCount ?? 0;

      final choice = await showTrialExpiredModal(
        context,
        activeProtocolCount: currentProtocolCount,
        isTrialExpiration: state.isTrialExpiration,
      );

      switch (choice) {
        case TrialExpiredChoice.keepEverything:
          await _viewModel.goToPaywall();
          if (!mounted) return;

          // Refresh state to get updated subscription status after paywall
          await _viewModel.refresh();
          if (!mounted) return;

          final user = _viewModel.state.value.user;
          if (user != null && _viewModel.isTrialOrPremiumExpired(user)) {
            continue; // Re-show modal
          }
          // User subscribed: mark decision resolved and exit loop
          await _viewModel.markTrialExpiredDecisionResolved();
          return;
        case TrialExpiredChoice.continueWithFree:
          final success = await _viewModel.handleUseFreeTier();
          if (success) {
            await _viewModel.markTrialExpiredDecisionResolved();
          }
          // If success=false, deactivation modal shown or save failed.
          // Either way, we exit the loop; user can retry via banner/settings.
          return;
        case null:
          // Modal dismissed without choice (shouldn't happen with barrierDismissible: false)
          return;
      }
    }
  }

  Future<void> _showGraceDialog() async {
    final kitColors = context.kitColors;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kitColors.panel,
          title: const Text('Payment Issue'),
          content: const Text(
            'We are having trouble with your payment method. Please update it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeactivationDialog() async {
    final kitColors = context.kitColors;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kitColors.panel,
          title: const Text('Choose 2 Protocols to Keep'),
          content: const Text(
            'Deactivation flow coming soon. You will be able to pick two '
            'protocols to keep active.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: context.theme.textTheme.bodyMedium?.copyWith(
                color: kitColors.white60,
                height: 1.5,
              ),
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              'Pull to refresh to retry.',
              textAlign: TextAlign.center,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: kitColors.white40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredFadeIn extends StatefulWidget {
  const _StaggeredFadeIn({
    required this.child,
    required this.index,
  });

  final Widget child;
  final int index;

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _visible ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
