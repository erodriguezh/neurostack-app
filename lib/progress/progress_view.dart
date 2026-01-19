import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/spacing.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/data/cached_user_store.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/protocol/data/cached_protocol_store.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/data/data_sources/session_local_data_source.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/session/presentation/log_session_modal.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/home/widgets/home_bottom_nav.dart';
import 'package:neurostack/home/widgets/home_status_banner.dart';
import 'package:neurostack/progress/data/cached_week_progress_store.dart';
import 'package:neurostack/progress/progress_state.dart';
import 'package:neurostack/progress/progress_view_model.dart';
import 'package:neurostack/progress/widgets/progress_grid.dart';

const _progressOfflineBanner = HomeBannerModel(
  type: HomeBannerType.offline,
  message: 'Offline mode',
  isTappable: false,
  isDismissible: false,
);

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView>
    with WidgetsBindingObserver {
  late final ProgressViewModel _viewModel = ProgressViewModel(
    notifyService: locator<NotifyService>(),
    routerService: locator<RouterService>(),
    authService: locator<AuthService>(),
    userRepository: locator<UserRepository>(),
    protocolRepository: locator<ProtocolRepository>(),
    sessionRepository: locator<SessionRepository>(),
    sessionLocalDataSource: locator<SessionLocalDataSource>(),
    connectivityService: locator<ConnectivityService>(),
    cachedUserStore: locator<CachedUserStore>(),
    cachedWeekProgressStore: locator<CachedWeekProgressStore>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _viewModel.onAppResumed();
    }
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
          child: ValueListenableBuilder<ProgressState>(
            valueListenable: _viewModel.state,
            builder: (context, state, child) {
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
                      activeTab: HomeBottomTab.progress,
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
                          color: context.kitColors.white90.withValues(alpha: 0.3),
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
    ProgressState state,
    CustomSpacing spacing,
    double bottomInset,
  ) {
    final slivers = <Widget>[];

    if (state is ProgressLoading || state is ProgressInitial) {
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
      return slivers;
    }

    if (state is ProgressError) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(message: state.failure.message),
        ),
      );
      return slivers;
    }

    if (state is ProgressLoaded) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: context.theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.8,
                    color: context.kitColors.white90,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  _formatWeekRange(context, state.weekRange),
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: context.kitColors.white40,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (state.isOffline) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: spacing.md,
                left: spacing.lg,
                right: spacing.lg,
              ),
              child: const HomeStatusBanner(
                banner: _progressOfflineBanner,
                onDismiss: null,
                onTap: null,
              ),
            ),
          ),
        );
      }

      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: ProgressGrid(
              rows: state.rows,
              weekRange: state.weekRange,
              todayIndex: state.todayIndex,
              isOffline: state.isOffline,
              onTapMissedCell: (protocolId, protocolName, day) {
                _showLogSessionModal(
                  protocolId: protocolId,
                  day: day,
                );
              },
            ),
          ),
        ),
      );

      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(height: 120 + bottomInset),
        ),
      );
    }

    return slivers;
  }

  String _formatWeekRange(BuildContext context, DateTimeRange range) {
    final locale = Localizations.localeOf(context).toString();
    final start = DateFormat.MMMd(locale).format(range.start);
    final end = DateFormat.MMMd(locale).format(range.end);
    final year = DateFormat.y(locale).format(range.end);
    return '$start - $end, $year';
  }

  Future<void> _showLogSessionModal({
    required String protocolId,
    required DateTime day,
  }) async {
    // Resolve userId from auth state
    final authState = locator<AuthService>().authState.value;
    String? userId;
    if (authState is AuthenticatedOnline) {
      userId = authState.user.id;
    } else if (authState is AuthenticatedOffline) {
      userId = authState.user.id;
    }

    if (userId == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Unable to identify user'),
      );
      return;
    }

    // Resolve Protocol: try cache first, then repository fallback
    final cachedProtocols =
        await locator<CachedProtocolStore>().loadProtocols(userId);
    var protocol = cachedProtocols.firstWhereOrNull((p) => p.id == protocolId);

    // Fallback to repository if not in cache (e.g., cache cleared, first run)
    if (protocol == null) {
      final repoResult =
          await locator<ProtocolRepository>().getById(protocolId);
      protocol = repoResult.fold((_) => null, (p) => p);
    }

    if (protocol == null) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(message: 'Protocol not found'),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await showLogSessionModal(
      context,
      protocol: protocol,
      userId: userId,
      initialDate: day,
      onSessionLogged: _viewModel.onSessionLogged,
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
