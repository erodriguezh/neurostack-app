// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/l10n/app_localizations.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/auth_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_auth_ui/src/localizations/supa_magic_auth_localization.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    locator.reset();
    locator.registerMany([
      Module<NavigationIntentStore>(
        builder: () => NavigationIntentStore(prefs),
        lazy: false,
      ),
      Module<RouterService>(
        builder: () => RouterService(
          supportedRoutes: [
            RouteEntry(
              path: '/',
              builder: (key, routeData) => const SizedBox(),
            ),
            RouteEntry(
              path: '/auth',
              builder: (key, routeData) => const SizedBox(),
            ),
            RouteEntry(
              path: '/auth/check-email',
              builder: (key, routeData) => const SizedBox(),
            ),
          ],
        ),
        lazy: false,
      ),
      Module<NotifyService>(builder: () => NotifyService(), lazy: false),
    ]);
  });

  tearDown(() {
    locator.reset();
  });

  testWidgets(
    'magicLinkButton_withValidEmail_enablesButton',
    (tester) async {
      // Arrange
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      final initialCta = tester.widget<AppPrimaryCta>(
        find.byKey(WidgetKeys.authSubmitButton),
      );
      expect(initialCta.enabled, isFalse);

      // Act
      await tester.enterText(
        find.byKey(WidgetKeys.authEmailField),
        'test@example.com',
      );
      await tester.pump();

      // Assert
      final updatedCta = tester.widget<AppPrimaryCta>(
        find.byKey(WidgetKeys.authSubmitButton),
      );
      expect(updatedCta.enabled, isTrue);
    },
  );

  testWidgets(
    'sendMagicLink_withInvalidEmail_showsValidationError',
    (tester) async {
      // Arrange
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(WidgetKeys.authEmailField));
      await tester.enterText(
        find.byKey(WidgetKeys.authEmailField),
        'not-an-email',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Assert
      expect(
        find.text(const SupaMagicAuthLocalization().validEmailError),
        findsOneWidget,
      );
    },
  );
}

Widget _buildTestWidget() {
  return DefaultAssetBundle(
    bundle: _TestAssetBundle(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.buildTheme(Brightness.light),
      builder: (context, child) {
        Translate.init(context);
        return child ?? const SizedBox();
      },
      home: const AuthView(),
    ),
  );
}

class _TestAssetBundle extends CachingAssetBundle {
  static const _logoSvg = '''
<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">
  <circle cx="5" cy="5" r="5" />
</svg>
''';

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/logo.svg') {
      final bytes = Uint8List.fromList(_logoSvg.codeUnits);
      return ByteData.view(bytes.buffer);
    }
    throw FlutterError('Asset not found: $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/logo.svg') {
      return _logoSvg;
    }
    return '';
  }
}
