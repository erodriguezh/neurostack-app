import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

Completer<void>? _initCompleter;

/// Override for the underlying initializer, used in tests to avoid
/// platform-channel calls to Supabase.initialize().
@visibleForTesting
Future<void> Function()? testDataSourceInitOverride;

/// Initializes Supabase. Safe to call multiple times:
/// - First call: runs initialization, returns when done.
/// - Concurrent calls: return the same future.
/// - After failure: resets so the next call retries.
/// - After success on retry: returns immediately (Supabase client is a
///   singleton that survives `locator.reset()`).
Future<void> initDataSource() async {
  if (_initCompleter != null) {
    return _initCompleter!.future;
  }
  _initCompleter = Completer<void>();
  try {
    if (testDataSourceInitOverride != null) {
      await testDataSourceInitOverride!();
    } else {
      await Supabase.initialize(
        url: const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: '',
        ),
        anonKey: const String.fromEnvironment(
          'SUPABASE_PUBLISHABLE_KEY',
          defaultValue: '',
        ),
      );
    }
    _initCompleter!.complete();
  } catch (e, st) {
    _initCompleter!.completeError(e, st);
    _initCompleter = null; // Reset so retry can genuinely retry
    rethrow;
  }
}

/// Test seam: resets the init guard so tests can exercise idempotency
/// and retry-after-failure scenarios deterministically.
@visibleForTesting
void resetDataSourceInitGuard() => _initCompleter = null;
