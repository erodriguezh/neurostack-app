import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_environment.dart';
import '../../../core/utils/internal_notification/notify_service.dart';
import '../../../core/utils/internal_notification/toast/toast_event.dart';
import '../../../core/utils/l10n/translate.dart';
import '../../../core/utils/navigation/navigation_intent_store.dart';
import '../../../core/utils/navigation/route_data.dart';
import '../../../core/utils/navigation/router_service.dart';

class AuthViewModel {
  AuthViewModel({
    required NavigationIntentStore navigationIntentStore,
    required RouterService routerService,
    required NotifyService notifyService,
  }) : _navigationIntentStore = navigationIntentStore,
       _routerService = routerService,
       _notifyService = notifyService;

  final NavigationIntentStore _navigationIntentStore;
  final RouterService _routerService;
  final NotifyService _notifyService;
  final Logger _logger = Logger('Auth');

  Future<void> handleMagicLinkSent(String email) async {
    await _navigationIntentStore.saveAuthEmail(email);
    _logger.info('Magic link sent (env=${AppEnvironment.tag})');
    _routerService.replace(Path(name: '/auth/check-email'));
  }

  void handleAuthError(Object error) {
    final message = _errorMessage(error);
    _notifyService.setToastEvent(ToastEventError(message: message));
    _logger.warning('Auth error (env=${AppEnvironment.tag}): $error');
  }

  String _errorMessage(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    return Translate.current.authUnexpectedError;
  }
}
