extension DateTimeWeekExtension on DateTime {
  /// Returns Monday 00:00:00 of the week containing this date.
  DateTime get weekStart {
    final daysFromMonday = weekday - 1; // Monday = 1
    return DateTime(year, month, day - daysFromMonday);
  }

  /// Returns Sunday 23:59:59 of the week containing this date.
  DateTime get weekEnd {
    final daysToSunday = 7 - weekday;
    return DateTime(year, month, day + daysToSunday, 23, 59, 59);
  }

  /// Check if this date and [other] fall on the same calendar day.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
