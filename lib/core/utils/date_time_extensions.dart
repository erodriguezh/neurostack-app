extension DateTimeWeekExtension on DateTime {
  /// Returns Monday 00:00:00 of the week containing this date.
  /// Preserves UTC if the receiver is UTC.
  DateTime get weekStart {
    final daysFromMonday = weekday - 1; // Monday = 1
    return (isUtc
            ? DateTime.utc(year, month, day - daysFromMonday)
            : DateTime(year, month, day - daysFromMonday))
        .startOfDay;
  }

  /// Returns Sunday at one microsecond before midnight of the week containing this date.
  /// Preserves UTC if the receiver is UTC.
  DateTime get weekEnd {
    final daysToSunday = 7 - weekday;
    return (isUtc
            ? DateTime.utc(year, month, day + daysToSunday)
            : DateTime(year, month, day + daysToSunday))
        .endOfDay;
  }

  /// Check if this date and [other] fall on the same calendar day.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns this date at 00:00:00.000 (start of day).
  /// Preserves UTC if the receiver is UTC.
  DateTime get startOfDay =>
      isUtc ? DateTime.utc(year, month, day) : DateTime(year, month, day);

  /// Returns this date at one microsecond before midnight of the next day.
  /// Uses calendar-based next day (not 24h addition) for DST safety.
  /// Preserves UTC if the receiver is UTC.
  DateTime get endOfDay {
    final nextDayStart = isUtc
        ? DateTime.utc(year, month, day + 1)
        : DateTime(year, month, day + 1);
    return nextDayStart.subtract(const Duration(microseconds: 1));
  }
}
