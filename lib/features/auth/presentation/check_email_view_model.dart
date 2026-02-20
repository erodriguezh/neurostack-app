import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_environment.dart';
import '../../../core/utils/data_source/data_source_abstraction.dart';
import '../../../core/utils/internal_notification/notify_service.dart';
import '../../../core/utils/internal_notification/toast/toast_event.dart';
import '../../../core/utils/l10n/translate.dart';
import '../../../core/utils/navigation/navigation_intent_store.dart';
import '../../../core/utils/navigation/route_data.dart';
import '../../../core/utils/navigation/router_service.dart';

class CheckEmailViewModel {
  CheckEmailViewModel({
    required NavigationIntentStore navigationIntentStore,
    required RouterService routerService,
    required DataSourceAbstraction dataSource,
    required NotifyService notifyService,
  }) : _navigationIntentStore = navigationIntentStore,
       _routerService = routerService,
       _dataSource = dataSource,
       _notifyService = notifyService;

  final NavigationIntentStore _navigationIntentStore;
  final RouterService _routerService;
  final DataSourceAbstraction _dataSource;
  final NotifyService _notifyService;
  final Logger _logger = Logger('Auth');

  final ValueNotifier<String?> email = ValueNotifier<String?>(null);
  final ValueNotifier<int> cooldownSeconds = ValueNotifier<int>(0);

  Timer? _cooldownTimer;
  bool _isSending = false;

  void init() {
    email.value = _navigationIntentStore.getAuthEmail();
    _startCooldown(60);
  }

  bool get canResend => cooldownSeconds.value == 0 && !_isSending;

  Future<void> resendMagicLink() async {
    if (!canResend) {
      return;
    }

    final targetEmail = email.value?.trim();
    if (targetEmail == null || targetEmail.isEmpty) {
      _notifyService.setToastEvent(
        ToastEventError(message: Translate.current.authMissingEmail),
      );
      return;
    }

    _isSending = true;
    _startCooldown(60);

    try {
      await _dataSource.auth.signInWithOtp(
        email: targetEmail,
        emailRedirectTo: _redirectUrl(),
      );
      _logger.info('Magic link sent (env=${AppEnvironment.tag})');
    } on AuthException catch (error) {
      if (_isRateLimited(error)) {
        _notifyService.setToastEvent(
          ToastEventWarning(message: Translate.current.authRateLimited),
        );
      } else {
        _notifyService.setToastEvent(
          ToastEventError(message: error.message),
        );
      }
      _logger.warning('Auth resend error (env=${AppEnvironment.tag}): $error');
    } catch (error) {
      _notifyService.setToastEvent(
        ToastEventError(message: Translate.current.authUnexpectedError),
      );
      _logger.warning('Auth resend error (env=${AppEnvironment.tag}): $error');
    } finally {
      _isSending = false;
    }
  }

  Future<void> changeEmail() async {
    await _navigationIntentStore.clearAuthEmail();
    _routerService.replaceAll([Path(name: '/auth')]);
  }

  void dispose() {
    _cooldownTimer?.cancel();
    email.dispose();
    cooldownSeconds.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    cooldownSeconds.value = seconds;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds.value <= 1) {
        timer.cancel();
        cooldownSeconds.value = 0;
      } else {
        cooldownSeconds.value -= 1;
      }
    });
  }

  bool _isRateLimited(AuthException error) {
    return error.statusCode == '429' ||
        (error.message.toLowerCase().contains('rate') &&
            error.message.toLowerCase().contains('limit'));
  }

  String _redirectUrl() {
    if (AppEnvironment.isDev) {
      return 'https://getneurostack.app/auth/callback?env=dev';
    }
    return 'https://getneurostack.app/auth/callback';
  }
}
