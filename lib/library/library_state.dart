import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:neurostack/features/user/domain/entities/user.dart';
import 'package:neurostack/home/home_state.dart';

const _unset = Object();

enum LibraryStatus { loading, loaded, empty, error }

enum LibraryCardStatus { inStack, available, locked }

class LibraryProtocolCardModel {
  const LibraryProtocolCardModel({
    required this.protocolId,
    required this.name,
    required this.category,
    required this.evidenceLevel,
    required this.status,
    this.isOfflineDisabled = false,
    this.animateBadge = false,
  });

  final String protocolId;
  final String name;
  final Category category;
  final EvidenceLevel evidenceLevel;
  final LibraryCardStatus status;
  final bool isOfflineDisabled;
  final bool animateBadge;
}

class LibrarySectionModel {
  const LibrarySectionModel({
    required this.category,
    required this.cards,
  });

  final Category category;
  final List<LibraryProtocolCardModel> cards;
}

class LibraryProtocolStats {
  const LibraryProtocolStats({
    required this.totalSessions,
    required this.currentStreakDays,
    this.lastSessionAt,
  });

  final int totalSessions;
  final int currentStreakDays;
  final DateTime? lastSessionAt;
}

class LibraryViewState {
  const LibraryViewState({
    this.status = LibraryStatus.loading,
    this.cards = const [],
    this.sections = const [],
    this.user,
    this.protocolsById = const {},
    this.isOffline = false,
    this.errorMessage,
    this.isRefreshing = false,
    this.activeTab = HomeBottomTab.library,
  });

  final LibraryStatus status;
  final List<LibraryProtocolCardModel> cards;
  final List<LibrarySectionModel> sections;
  final User? user;
  final Map<String, Protocol> protocolsById;
  final bool isOffline;
  final String? errorMessage;
  final bool isRefreshing;
  final HomeBottomTab activeTab;

  LibraryViewState copyWith({
    LibraryStatus? status,
    List<LibraryProtocolCardModel>? cards,
    List<LibrarySectionModel>? sections,
    Object? user = _unset,
    Object? protocolsById = _unset,
    bool? isOffline,
    Object? errorMessage = _unset,
    bool? isRefreshing,
    HomeBottomTab? activeTab,
  }) {
    return LibraryViewState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      sections: sections ?? this.sections,
      user: user == _unset ? this.user : user as User?,
      protocolsById: protocolsById == _unset
          ? this.protocolsById
          : protocolsById as Map<String, Protocol>,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}
