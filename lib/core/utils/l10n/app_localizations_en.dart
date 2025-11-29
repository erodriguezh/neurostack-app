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
}
