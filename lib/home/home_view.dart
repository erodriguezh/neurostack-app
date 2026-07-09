import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/spacing.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/ui/widgets/error_state_view.dart';
import 'package:neurostack/core/ui/widgets/home_indicator_pill.dart';
import 'package:neurostack/core/ui/widgets/staggered_fade_in.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/in_app_review/review_trigger_helper.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/session/presentation/log_session_modal.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/features/user/domain/enums/subscription_status.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/data/trial_expiration_decision_store.dart';
import 'package:neurostack/paywall/data/trial_reminder_service.dart';
import 'package:neurostack/paywall/domain/subscription_status_resolver.dart';
import 'package:neurostack/paywall/domain/trial_expiry_policy.dart';
import 'package:neurostack/paywall/widgets/protocol_selection_modal.dart';
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
    trialExpiryPolicy: locator<TrialExpiryPolicy>(),
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
      mode: AppGridBackgroundMode.adaptive,
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
                  HomeIndicatorPill(bottomInset: bottomInset),
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
            child: StaggeredFadeIn(
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
            child: ErrorStateView(message: state.errorMessage),
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
              child: StaggeredFadeIn(
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
                child: StaggeredFadeIn(
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
                      child: StaggeredFadeIn(
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
        if (!mounted) return;
        _viewModel.acknowledgeGraceModal();
      });
    }

    if (state.showDeactivationModal && !_showingDeactivationModal) {
      _showingDeactivationModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showProtocolSelectionFromState();
        _showingDeactivationModal = false;
        if (!mounted) return;
        _viewModel.acknowledgeDeactivationModal();
      });
    }

    if (state.logSessionRequest != null && !_showingLogSessionModal) {
      _showingLogSessionModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showLogSessionModal(state, state.logSessionRequest!);
        _showingLogSessionModal = false;
        if (!mounted) return;
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

    Future<int>? sessionCountFuture;

    await showLogSessionModal(
      context,
      protocol: request.protocol,
      userId: userId,
      initialDate: request.initialDate,
      onSessionLogged: (session) {
        sessionCountFuture = locator<ReviewTriggerHelper>().captureSessionCount(
          userId,
        );
        if (!mounted) return;
        _viewModel.refresh();
      },
    );

    // Fire-and-forget: decouple the 2-second delayed review prompt from
    // the modal lifecycle so _showingLogSessionModal resets immediately.
    if (sessionCountFuture != null) {
      unawaited(
        () async {
          try {
            final count = await sessionCountFuture!;
            await locator<ReviewTriggerHelper>().triggerReviewIfNeeded(
              count,
              userId,
            );
          } catch (_) {
            // Non-critical — review prompt is best-effort
          }
        }(),
      );
    }
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
          final user = _viewModel.state.value.user;
          final freeLimit = SubscriptionStatus.free.protocolLimit ?? 2;
          final success = user != null && user.activeProtocolCount > freeLimit
              ? await _runStackTrimFlow(user)
              : await _viewModel.handleUseFreeTier();
          if (success) {
            await _viewModel.markTrialExpiredDecisionResolved();
          }
          // If success=false, the decision remains unresolved so the modal can
          // retrigger on next launch.
          return;
        case null:
          // Modal dismissed without choice (shouldn't happen with barrierDismissible: false)
          return;
      }
    }
  }

  Future<void> _showGraceDialog() async {
    final semanticColors = context.semanticColors;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: semanticColors.surfaceElevated,
          surfaceTintColor: Colors.transparent,
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

  Future<bool> _runStackTrimFlow(User user) async {
    var attempts = 0;
    User? currentUser = user;
    List<String>? initialSelection;

    while (attempts < 2 && currentUser != null) {
      final keepIds = await _selectProtocolsToKeep(
        user: currentUser,
        initialSelection: initialSelection,
      );
      if (keepIds == null) {
        return false;
      }

      final success = await _viewModel.confirmProtocolDeactivation(keepIds);
      if (success) {
        return true;
      }

      attempts += 1;
      initialSelection = keepIds;
      currentUser = _viewModel.state.value.user;
    }

    return false;
  }

  Future<void> _showProtocolSelectionFromState() async {
    final keepIds = await _selectProtocolsToKeep();
    if (keepIds == null) {
      return;
    }

    await _viewModel.confirmProtocolDeactivation(keepIds);
  }

  Future<List<String>?> _selectProtocolsToKeep({
    User? user,
    List<String>? initialSelection,
  }) async {
    final currentUser = user ?? _viewModel.state.value.user;
    if (currentUser == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Unable to identify user'),
      );
      return null;
    }

    final items = await _viewModel.activeProtocolSelectionItems(currentUser);
    if (!mounted) return null;

    final keepIds = await showProtocolSelectionModal(
      context,
      items: items,
      initialSelection: initialSelection,
    );
    return keepIds;
  }
}
