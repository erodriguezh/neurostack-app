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
}
