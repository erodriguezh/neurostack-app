import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

extension PumpHelpers on WidgetTester {
  /// Pumps until finder matches or timeout expires.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(interval);
      if (any(finder)) return;
    }
    throw TimeoutException('Timed out waiting for $finder');
  }

  /// Pumps until finder is gone or timeout expires.
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(interval);
      if (!any(finder)) return;
    }
    throw TimeoutException('Timed out waiting for $finder to disappear');
  }

  /// Pumps past splash screen animations safely.
  Future<void> pumpPastSplash({Duration wait = const Duration(seconds: 2)}) async {
    await pump(wait);
  }
}
