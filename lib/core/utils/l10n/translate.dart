import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:neurostack/core/utils/l10n/app_localizations.dart'; // Provides lookupAppLocalizations

/// Static access to [AppLocalizations].
///
/// Usage:
/// 1. Initialize in `MaterialApp.builder`: `Translate.init(context);`
/// 2. Access translations from ViewModels/Services: `Translate.current.appName`
/// 3. Get current locale: `Translate.locale`
/// 4. Programmatically load a different locale: `await Translate.load(Locale('sv'));`
///    (Note: `Translate.load` updates `Translate.current` but does not rebuild UI globally.
///     For UI updates, manage `MaterialApp.locale` and let `Translate.init` refresh.)
class Translate {
  static AppLocalizations? _currentLocalizations;
  static Locale? _currentLocale;

  /// Initializes `Translate` with [AppLocalizations] from the given [context].
  /// Must be called once, typically in `MaterialApp.builder`.
  /// Also sets `intl.Intl.defaultLocale`.
  static void init(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      _currentLocalizations = localizations;
      _currentLocale = Locale(localizations.localeName);
      intl.Intl.defaultLocale = localizations.localeName;
    } else {
      // This may occur if Translate.init is called before localizations are available.
      // Ensure AppLocalizations.delegate is in MaterialApp.localizationDelegates.
      debugPrint(
        'Translate.init(context): AppLocalizations.of(context) returned null. '
        'Verify MaterialApp setup and Translate.init call timing.',
      );
    }
  }

  /// The current [AppLocalizations] instance.
  /// Throws if `init` was not called or failed.
  static AppLocalizations get current {
    if (_currentLocalizations == null) {
      throw Exception(
        'Translate.current accessed before Translate.init(context) was successfully called. '
        'Ensure Translate.init(context) is called in your MaterialApp builder.',
      );
    }
    return _currentLocalizations!;
  }

  /// The currently active [Locale].
  /// Null if `init` was not called or failed.
  static Locale? get locale => _currentLocale;

  /// Loads and sets localizations for [newLocale]. Updates `Translate.current` and `Translate.locale`.
  ///
  /// This method does NOT automatically rebuild UI. It's useful for:
  /// - Accessing translations for a locale different from the main UI.
  /// - Scenarios where locale state is managed externally and `Translate.current` needs
  ///   to be updated after Flutter's delegates have loaded new locale data.
  ///
  /// For global UI locale changes that rebuild widgets, manage `MaterialApp.locale`
  /// and allow `Translate.init(context)` (in `MaterialApp.builder`) to update `Translate.current`.
  static Future<void> load(Locale newLocale) async {
    try {
      final loadedLocalizations = lookupAppLocalizations(newLocale);
      _currentLocalizations = loadedLocalizations;
      _currentLocale = Locale(
        loadedLocalizations.localeName,
      ); // Use canonicalized localeName
      intl.Intl.defaultLocale = loadedLocalizations.localeName;
    } catch (e) {
      debugPrint(
        'Translate.load(Locale newLocale) failed for locale "${newLocale.toLanguageTag()}": $e',
      );
      rethrow;
    }
  }
}
