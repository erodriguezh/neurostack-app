import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/spacing.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/connectivity/connectivity_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/repositories/protocol_repository.dart';
import 'package:neurostack/features/session/domain/repositories/session_repository.dart';
import 'package:neurostack/features/user/domain/repositories/user_repository.dart';
import 'package:neurostack/home/home_state.dart';
import 'package:neurostack/home/widgets/home_bottom_nav.dart';
import 'package:neurostack/home/widgets/home_status_banner.dart';
import 'package:neurostack/library/library_state.dart';
import 'package:neurostack/library/library_view_model.dart';
import 'package:neurostack/library/widgets/library_category_header.dart';
import 'package:neurostack/library/widgets/library_protocol_card.dart';
import 'package:neurostack/library/widgets/protocol_detail_sheet.dart';

const _libraryOfflineBanner = HomeBannerModel(
  type: HomeBannerType.offline,
  message: 'Offline mode',
  isTappable: false,
  isDismissible: false,
);

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel = LibraryViewModel(
    notifyService: locator<NotifyService>(),
    routerService: locator<RouterService>(),
    authService: locator<AuthService>(),
    userRepository: locator<UserRepository>(),
    protocolRepository: locator<ProtocolRepository>(),
    sessionRepository: locator<SessionRepository>(),
    connectivityService: locator<ConnectivityService>(),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<LibraryViewState>(
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
                            key: const PageStorageKey('library-scroll'),
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
    LibraryViewState state,
    CustomSpacing spacing,
    double bottomInset,
  ) {
    final slivers = <Widget>[];

    if (state.isOffline) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: const _StaggeredFadeIn(
              index: 0,
              child: HomeStatusBanner(
                banner: _libraryOfflineBanner,
                onDismiss: null,
                onTap: null,
              ),
            ),
          ),
        ),
      );
      slivers.add(SliverToBoxAdapter(child: SizedBox(height: spacing.md)));
    }

    switch (state.status) {
      case LibraryStatus.loading:
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
      case LibraryStatus.error:
        slivers.add(
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorState(message: state.errorMessage),
          ),
        );
        break;
      case LibraryStatus.empty:
      case LibraryStatus.loaded:
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, 0),
              child: _StaggeredFadeIn(
                index: 1,
                child: Text(
                  'Protocol Library',
                  style: context.theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.8,
                    color: context.kitColors.white90,
                  ),
                ),
              ),
            ),
          ),
        );
        slivers.add(SliverToBoxAdapter(child: SizedBox(height: spacing.md)));

        if (state.status == LibraryStatus.empty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: const _EmptyState(),
              ),
            ),
          );
        } else {
          final children = <Widget>[];
          var staggerIndex = 2;

          for (int sectionIndex = 0;
              sectionIndex < state.sections.length;
              sectionIndex++) {
            final section = state.sections[sectionIndex];
            children.add(
              Padding(
                padding: EdgeInsets.only(
                  top: sectionIndex == 0 ? 0 : spacing.lg,
                  bottom: spacing.sm,
                ),
                child: _StaggeredFadeIn(
                  index: staggerIndex++,
                  child: LibraryCategoryHeader(
                    label: section.category.displayName.toUpperCase(),
                  ),
                ),
              ),
            );

            for (final card in section.cards) {
              children.add(
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.md),
                  child: _StaggeredFadeIn(
                    index: staggerIndex++,
                    child: LibraryProtocolCard(
                      model: card,
                      onTapCard: () => _showDetails(context, state, card),
                      onTapBadge: () =>
                          _handleBadgeTap(context, state, card),
                    ),
                  ),
                ),
              );
            }
          }

          slivers.add(
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate(children),
              ),
            ),
          );
        }
    }

    if (state.status == LibraryStatus.empty ||
        state.status == LibraryStatus.loaded) {
      slivers.add(
        SliverToBoxAdapter(
          child: SizedBox(height: 120 + bottomInset),
        ),
      );
    }

    return slivers;
  }

  void _handleBadgeTap(
    BuildContext context,
    LibraryViewState state,
    LibraryProtocolCardModel card,
  ) {
    switch (card.status) {
      case LibraryCardStatus.available:
        _viewModel.addProtocol(card.protocolId);
        break;
      case LibraryCardStatus.inStack:
      case LibraryCardStatus.locked:
        _showDetails(context, state, card);
        break;
    }
  }

  void _showDetails(
    BuildContext context,
    LibraryViewState state,
    LibraryProtocolCardModel card,
  ) {
    final protocol = state.protocolsById[card.protocolId];
    if (protocol == null) {
      _viewModel.refresh();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return ProtocolDetailSheet(
          protocol: protocol,
          status: card.status,
          isOffline: state.isOffline,
          loadStats: () => _viewModel.loadStats(protocol.id),
          onAdd: () {
            Navigator.of(context).pop();
            _viewModel.addProtocol(protocol.id);
          },
          onRemove: () => _confirmRemove(protocol),
          onUpgrade: () {
            Navigator.of(context).pop();
            _viewModel.goToPaywall();
          },
          onLogSession: () {
            Navigator.of(context).pop();
            _viewModel.onLogSession(protocol.id);
          },
        );
      },
    );
  }

  Future<void> _confirmRemove(Protocol protocol) async {
    if (!mounted) {
      return;
    }

    final kitColors = context.kitColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kitColors.panel,
          title: Text('Remove ${protocol.name.value}?'),
          content: const Text("This won't delete your session history."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    await _viewModel.removeProtocol(protocol.id);
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return Padding(
      padding: EdgeInsets.only(top: context.spacing.xxl),
      child: Column(
        children: [
          Text(
            'No protocols available right now.',
            textAlign: TextAlign.center,
            style: context.theme.textTheme.bodyMedium?.copyWith(
              color: kitColors.white60,
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
