import 'package:neurostack/features/session/domain/entities/session.dart';
import 'package:neurostack/library/library_state.dart';

LibraryProtocolStats buildLibraryProtocolStats(List<Session> sessions) {
  if (sessions.isEmpty) {
    return const LibraryProtocolStats(
      totalSessions: 0,
      currentStreakDays: 0,
    );
  }

  final sorted = List<Session>.from(sessions)
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  final lastSession = sorted.first.completedAt;
  final streak = _calculateStreak(sorted);

  return LibraryProtocolStats(
    totalSessions: sessions.length,
    currentStreakDays: streak,
    lastSessionAt: lastSession,
  );
}

int _calculateStreak(List<Session> sessions) {
  if (sessions.isEmpty) {
    return 0;
  }

  final days = <DateTime>[];
  for (final session in sessions) {
    final day = DateTime(
      session.completedAt.year,
      session.completedAt.month,
      session.completedAt.day,
    );
    if (!days.contains(day)) {
      days.add(day);
    }
  }

  int streak = 1;
  DateTime current = days.first;

  for (int i = 1; i < days.length; i++) {
    final next = days[i];
    if (current.difference(next).inDays == 1) {
      streak += 1;
      current = next;
    } else {
      break;
    }
  }

  return streak;
}
