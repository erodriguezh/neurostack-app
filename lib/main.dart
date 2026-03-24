import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/app_lifecycle_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:neurostack/startup/startup_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  runApp(const _AppLifecycleObserver());
}

/// Observes app lifecycle changes and forwards them to [AppLifecycleService].
///
/// This widget wraps the entire app to ensure lifecycle events are captured
/// at the top level. Services like [SessionSyncService] can then listen to
/// [AppLifecycleService.lifecycle] to trigger sync on resume.
class _AppLifecycleObserver extends StatefulWidget {
  const _AppLifecycleObserver();

  @override
  State<_AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Guard against DI not being ready yet (during startup) or being reset
    // (during retry). Lifecycle events can fire at any time, but the service
    // may not exist until StartupViewModel.initializeApp() completes.
    try {
      locator<AppLifecycleService>().setLifecycleState(state);
    } on ModuleNotFoundException {
      // Service not yet registered; ignore until DI is ready.
      // No buffering needed - nothing can listen until the service exists.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const StartupView();
  }
}
