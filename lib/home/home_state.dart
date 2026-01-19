import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';

const _unset = Object();

enum HomeStatus { loading, empty, populated, error }

enum HomeBannerType { trial, free, expired, grace, offline }

enum HomeBottomTab { stack, library, progress }

class HomeBannerModel {
  const HomeBannerModel({
    required this.type,
    required this.message,
    this.isTappable = false,
    this.isDismissible = true,
  });

  final HomeBannerType type;
  final String message;
  final bool isTappable;
  final bool isDismissible;
}

class HomeProtocolCardModel {
  const HomeProtocolCardModel({
    required this.protocolId,
    required this.title,
    required this.categoryLabel,
    required this.quickReference,
    required this.loggedToday,
    required this.isUnavailable,
  });

  final String protocolId;
  final String title;
  final String categoryLabel;
  final String quickReference;
  final bool loggedToday;
  final bool isUnavailable;
}

/// Request to open the log session modal with pre-populated values.
///
/// Set in [HomeViewState.logSessionRequest] to trigger the modal from
/// [HomeView]. Clear after the modal is shown or dismissed.
///
/// Holds the full [Protocol] object to avoid lookup in HomeView.
class LogSessionRequest {
  const LogSessionRequest({
    required this.protocol,
    required this.initialDate,
  });

  final Protocol protocol;
  final DateTime initialDate;
}

class HomeViewState {
  const HomeViewState({
    this.status = HomeStatus.loading,
    this.isOffline = false,
    this.user,
    this.cards = const [],
    this.banner,
    this.bannerDismissed = false,
    this.showTrialExpiredModal = false,
    this.showGraceModal = false,
    this.showDeactivationModal = false,
    this.errorMessage,
    this.isRefreshing = false,
    this.activeTab = HomeBottomTab.stack,
    this.logSessionRequest,
  });

  final HomeStatus status;
  final bool isOffline;
  final User? user;
  final List<HomeProtocolCardModel> cards;
  final HomeBannerModel? banner;
  final bool bannerDismissed;
  final bool showTrialExpiredModal;
  final bool showGraceModal;
  final bool showDeactivationModal;
  final String? errorMessage;
  final bool isRefreshing;
  final HomeBottomTab activeTab;
  final LogSessionRequest? logSessionRequest;

  HomeViewState copyWith({
    HomeStatus? status,
    bool? isOffline,
    Object? user = _unset,
    List<HomeProtocolCardModel>? cards,
    Object? banner = _unset,
    bool? bannerDismissed,
    bool? showTrialExpiredModal,
    bool? showGraceModal,
    bool? showDeactivationModal,
    Object? errorMessage = _unset,
    bool? isRefreshing,
    HomeBottomTab? activeTab,
    Object? logSessionRequest = _unset,
  }) {
    return HomeViewState(
      status: status ?? this.status,
      isOffline: isOffline ?? this.isOffline,
      user: user == _unset ? this.user : user as User?,
      cards: cards ?? this.cards,
      banner: banner == _unset ? this.banner : banner as HomeBannerModel?,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
      showTrialExpiredModal:
          showTrialExpiredModal ?? this.showTrialExpiredModal,
      showGraceModal: showGraceModal ?? this.showGraceModal,
      showDeactivationModal:
          showDeactivationModal ?? this.showDeactivationModal,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      activeTab: activeTab ?? this.activeTab,
      logSessionRequest: logSessionRequest == _unset
          ? this.logSessionRequest
          : logSessionRequest as LogSessionRequest?,
    );
  }
}
