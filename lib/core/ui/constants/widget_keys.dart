import 'package:flutter/foundation.dart';

/// Centralized widget keys for testing.
abstract final class WidgetKeys {
  static const authEmailField = Key('auth_email_field');
  static const authSubmitButton = Key('auth_submit_button');

  // Rate App screen
  static const rateAppScreen = Key('rate_app_screen');
  static const rateAppCloseButton = Key('rate_app_close_button');
  static const rateAppLogo = Key('rate_app_logo');
  static const rateAppPrimaryCta = Key('rate_app_primary_cta');
  static const rateAppSecondaryCta = Key('rate_app_secondary_cta');
}
