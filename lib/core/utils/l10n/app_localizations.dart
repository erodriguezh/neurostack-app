import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// The name of the app
  ///
  /// In en, this message translates to:
  /// **'Flutter Kit'**
  String get appName;

  /// The generic error message
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get errorGeneric;

  /// The error message when the app fails to start
  ///
  /// In en, this message translates to:
  /// **'We encountered an error while starting the app.'**
  String get errorStartingApp;

  /// The text for the retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title shown on the 404 page
  ///
  /// In en, this message translates to:
  /// **'404'**
  String get notFoundTitle;

  /// Message shown on the 404 page
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get notFoundMessage;

  /// Text for the button that takes users back to home page
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get notFoundGoHome;

  /// Text for the counter
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times:'**
  String get counter;

  /// Text for the success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Title for the auth screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authTitle;

  /// Subtitle for the auth screen
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a code to continue.'**
  String get authSubtitle;

  /// Button label to request a one-time code
  ///
  /// In en, this message translates to:
  /// **'Email me a code'**
  String get authSendCode;

  /// Title for the check email screen
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmailTitle;

  /// Instruction text for the code verification screen
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we emailed you.'**
  String get checkEmailInstruction;

  /// Spam folder hint on check email screen
  ///
  /// In en, this message translates to:
  /// **'Use the latest code if you request a new one.'**
  String get checkEmailSpamHint;

  /// Label for the one-time code input
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authCodeFieldLabel;

  /// Button label to verify the one-time code
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get authVerifyCode;

  /// Validation message when the one-time code is too short
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get authCodeValidationError;

  /// Message shown after the one-time code verifies while auth navigation completes
  ///
  /// In en, this message translates to:
  /// **'Completing Sign-In...'**
  String get authCompletingSignIn;

  /// Button label to resend one-time code
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// Prefix label for resend cooldown
  ///
  /// In en, this message translates to:
  /// **'Resend available in'**
  String get authResendAvailableIn;

  /// Link text for changing the email on check email screen
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get authChangeEmail;

  /// Fallback text when no email is stored
  ///
  /// In en, this message translates to:
  /// **'Email not available'**
  String get authMissingEmail;

  /// Toast message when resend is rate limited
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait and try again.'**
  String get authRateLimited;

  /// Generic auth error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authUnexpectedError;

  /// Title for offline blocking screen
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineNoUserTitle;

  /// Body text for offline blocking screen
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to continue.'**
  String get offlineNoUserBody;

  /// Banner text shown when offline with cached data
  ///
  /// In en, this message translates to:
  /// **'Offline · Using cached data'**
  String get offlineUsingCachedData;

  /// Toast text when connection drops mid-session
  ///
  /// In en, this message translates to:
  /// **'Offline · Connection lost. Retrying in background.'**
  String get offlineConnectionLost;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
