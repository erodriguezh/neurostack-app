// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flutter Kit';

  @override
  String get errorGeneric => 'Oops! Something went wrong';

  @override
  String get errorStartingApp =>
      'We encountered an error while starting the app.';

  @override
  String get retry => 'Retry';

  @override
  String get notFoundTitle => '404';

  @override
  String get notFoundMessage => 'Page Not Found';

  @override
  String get notFoundGoHome => 'Go Home';

  @override
  String get counter => 'You have pushed the button this many times:';

  @override
  String get success => 'Success';

  @override
  String get authTitle => 'Sign in';

  @override
  String get authSubtitle => 'We\'ll email you a code to continue.';

  @override
  String get authSendCode => 'Email me a code';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String get checkEmailInstruction => 'Enter the 6-digit code we emailed you.';

  @override
  String get checkEmailSpamHint =>
      'Use the latest code if you request a new one.';

  @override
  String get authCodeFieldLabel => 'Enter the 6-digit code';

  @override
  String get authVerifyCode => 'Verify code';

  @override
  String get authCodeValidationError => 'Enter the 6-digit code.';

  @override
  String get authCompletingSignIn => 'Completing Sign-In...';

  @override
  String get authResendCode => 'Resend code';

  @override
  String get authResendAvailableIn => 'Resend available in';

  @override
  String get authChangeEmail => 'Change email';

  @override
  String get authMissingEmail => 'Email not available';

  @override
  String get authRateLimited => 'Too many requests. Please wait and try again.';

  @override
  String get authUnexpectedError => 'Something went wrong. Please try again.';

  @override
  String get offlineNoUserTitle => 'You\'re offline';

  @override
  String get offlineNoUserBody => 'Connect to the internet to continue.';

  @override
  String get offlineUsingCachedData => 'Offline · Using cached data';

  @override
  String get offlineConnectionLost =>
      'Offline · Connection lost. Retrying in background.';
}
