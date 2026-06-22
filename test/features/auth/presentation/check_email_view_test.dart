import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/l10n/app_localizations.dart';
import 'package:neurostack/core/utils/l10n/translate.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/check_email_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockDataSourceAbstraction extends Mock implements DataSourceAbstraction {}

class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  late MockDataSourceAbstraction dataSource;
  late MockGoTrueClient auth;
  late NavigationIntentStore navigationIntentStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    locator.reset();

    dataSource = MockDataSourceAbstraction();
    auth = MockGoTrueClient();
    navigationIntentStore = NavigationIntentStore(prefs);
    await navigationIntentStore.saveAuthEmail('user@example.com');

    when(() => dataSource.auth).thenReturn(auth);

    locator.registerMany([
      Module<NavigationIntentStore>(
        builder: () => navigationIntentStore,
        lazy: false,
      ),
      Module<RouterService>(
        builder: () => RouterService(
          supportedRoutes: [
            RouteEntry(
              path: '/auth',
              builder: (key, routeData) => const SizedBox(),
            ),
            RouteEntry(
              path: '/auth/check-email',
              builder: (key, routeData) => const SizedBox(),
            ),
            RouteEntry(
              path: '/404',
              builder: (key, routeData) => const SizedBox(),
            ),
          ],
        ),
        lazy: false,
      ),
      Module<DataSourceAbstraction>(builder: () => dataSource, lazy: false),
      Module<NotifyService>(builder: () => NotifyService(), lazy: false),
    ]);
  });

  tearDown(() {
    locator.reset();
  });

  testWidgets('valid code leaves the awaiting-code state', (tester) async {
    when(
      () => auth.verifyOTP(
        email: 'user@example.com',
        token: '123456',
        type: supabase.OtpType.email,
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    await tester.pumpWidget(_buildTestWidget());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(WidgetKeys.authCodeField), '123456');
    await tester.tap(find.byKey(WidgetKeys.authVerifyButton));
    await tester.pump();

    expect(find.byKey(WidgetKeys.authCodeField), findsNothing);
    expect(find.text('Completing Sign-In...'), findsOneWidget);
  });

  testWidgets('invalid code shows an inline error', (tester) async {
    when(
      () => auth.verifyOTP(
        email: 'user@example.com',
        token: '123456',
        type: supabase.OtpType.email,
      ),
    ).thenThrow(const supabase.AuthException('Invalid or expired code'));

    await tester.pumpWidget(_buildTestWidget());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(WidgetKeys.authCodeField), '123456');
    await tester.tap(find.byKey(WidgetKeys.authVerifyButton));
    await tester.pump();

    expect(find.text('Invalid or expired code'), findsOneWidget);
    expect(find.byKey(WidgetKeys.authCodeField), findsOneWidget);
  });

  testWidgets('rate-limited verify shows the rate-limit message', (
    tester,
  ) async {
    when(
      () => auth.verifyOTP(
        email: 'user@example.com',
        token: '123456',
        type: supabase.OtpType.email,
      ),
    ).thenThrow(
      const supabase.AuthException('Too many requests', statusCode: '429'),
    );

    await tester.pumpWidget(_buildTestWidget());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(WidgetKeys.authCodeField), '123456');
    await tester.tap(find.byKey(WidgetKeys.authVerifyButton));
    await tester.pump();

    expect(
      find.text('Too many requests. Please wait and try again.'),
      findsOneWidget,
    );
    expect(find.byKey(WidgetKeys.authCodeField), findsOneWidget);
  });

  testWidgets('short code shows validation feedback', (tester) async {
    await tester.pumpWidget(_buildTestWidget());
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byKey(WidgetKeys.authCodeField), '12345');
    await tester.tap(find.byKey(WidgetKeys.authVerifyButton));
    await tester.pump();

    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
    expect(find.byKey(WidgetKeys.authCodeField), findsOneWidget);
  });

  testWidgets('resend action uses code wording', (tester) async {
    await tester.pumpWidget(_buildTestWidget());
    await tester.pump(const Duration(milliseconds: 500));

    final cta = tester.widget<AppPrimaryCta>(
      find.byKey(WidgetKeys.authVerifyButton),
    );

    expect(cta.label, 'Verify code');
    expect(find.textContaining('Resend available in'), findsOneWidget);
  });
}

Widget _buildTestWidget() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.buildTheme(Brightness.light),
    builder: (context, child) {
      Translate.init(context);
      return child ?? const SizedBox();
    },
    home: const CheckEmailView(),
  );
}
