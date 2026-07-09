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
  final ValueNotifier<bool> isVerifying = ValueNotifier<bool>(false);
  final ValueNotifier<bool> verificationCompleted = ValueNotifier<bool>(false);
  final ValueNotifier<String?> codeError = ValueNotifier<String?>(null);

  Timer? _cooldownTimer;
  bool _isSending = false;

  void init() {
    email.value = _navigationIntentStore.getAuthEmail();
    _startCooldown(60);
  }

  bool get canResend => cooldownSeconds.value == 0 && !_isSending;

  Future<void> verifyCode(String code) async {
    if (isVerifying.value || verificationCompleted.value) {
      return;
    }

    final targetEmail = email.value?.trim();
    if (targetEmail == null || targetEmail.isEmpty) {
      codeError.value = Translate.current.authMissingEmail;
      return;
    }

    final trimmedCode = code.trim();
    if (trimmedCode.length < 6) {
      codeError.value = Translate.current.authCodeValidationError;
      return;
    }

    isVerifying.value = true;
    codeError.value = null;

    try {
      await _dataSource.auth.verifyOTP(
        email: targetEmail,
        token: trimmedCode,
        type: OtpType.email,
      );
      verificationCompleted.value = true;
      _logger.info('One-Time Code verified (env=${AppEnvironment.tag})');
    } on AuthException catch (error) {
      codeError.value = _authErrorMessage(error);
      _logAuthWarning(action: 'verify', error: error);
    } catch (error) {
      codeError.value = Translate.current.authUnexpectedError;
      _logAuthWarning(action: 'verify', error: error);
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resendCode() async {
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
      await _dataSource.auth.signInWithOtp(email: targetEmail);
      codeError.value = null;
      _logger.info('One-Time Code sent (env=${AppEnvironment.tag})');
    } on AuthException catch (error) {
      _notifyService.setToastEvent(_authToastEvent(error));
      _logAuthWarning(action: 'resend', error: error);
    } catch (error) {
      _notifyService.setToastEvent(
        ToastEventError(message: Translate.current.authUnexpectedError),
      );
      _logAuthWarning(action: 'resend', error: error);
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
    isVerifying.dispose();
    verificationCompleted.dispose();
    codeError.dispose();
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
    final message = error.message.toLowerCase();
    return error.statusCode == '429' ||
        (message.contains('rate') && message.contains('limit'));
  }

  String _authErrorMessage(AuthException error) {
    if (_isRateLimited(error)) {
      return Translate.current.authRateLimited;
    }

    return error.message;
  }

  ToastEvent _authToastEvent(AuthException error) {
    if (_isRateLimited(error)) {
      return ToastEventWarning(message: Translate.current.authRateLimited);
    }

    return ToastEventError(message: error.message);
  }

  void _logAuthWarning({
    required String action,
    required Object error,
  }) {
    _logger.warning('Auth $action error (env=${AppEnvironment.tag}): $error');
  }
}
