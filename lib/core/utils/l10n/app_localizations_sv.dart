// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'Flutter Kit';

  @override
  String get errorGeneric => 'Hoppsan! Något gick fel';

  @override
  String get errorStartingApp => 'Vi stötte på ett fel när appen startades.';

  @override
  String get retry => 'Försök igen';

  @override
  String get notFoundTitle => '404';

  @override
  String get notFoundMessage => 'Sidan hittades inte';

  @override
  String get notFoundGoHome => 'Gå till startsidan';

  @override
  String get counter => 'Du har tryckt på knappen så här många gånger:';

  @override
  String get success => 'Lyckades';

  @override
  String get authTitle => 'Logga in';

  @override
  String get authSubtitle => 'Vi skickar en magisk länk för att fortsätta.';

  @override
  String get checkEmailTitle => 'Kolla din e-post';

  @override
  String get checkEmailInstruction =>
      'Öppna din inkorg och tryck på länken för att fortsätta.';

  @override
  String get checkEmailSpamHint =>
      'Tips: Kolla skräpposten om du inte ser den.';

  @override
  String get authResendLink => 'Skicka länk igen';

  @override
  String get authResendAvailableIn => 'Skicka igen om';

  @override
  String get authChangeEmail => 'Byt e-post';

  @override
  String get authMissingEmail => 'E-post saknas';

  @override
  String get authRateLimited => 'För många försök. Vänta och försök igen.';

  @override
  String get authUnexpectedError => 'Något gick fel. Försök igen.';

  @override
  String get offlineNoUserTitle => 'Du är offline';

  @override
  String get offlineNoUserBody => 'Anslut till internet för att fortsätta.';

  @override
  String get offlineUsingCachedData => 'Offline · Använder cachelagrad data';

  @override
  String get offlineConnectionLost =>
      'Offline · Anslutningen bröts. Försöker igen i bakgrunden.';
}
