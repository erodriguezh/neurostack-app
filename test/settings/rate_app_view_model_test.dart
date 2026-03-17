import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/settings/rate_app_view_model.dart';

import '../mocks/mock_services.dart';

void main() {
  late MockInAppReviewService service;
  late MockNotifyService notifyService;

  setUp(() {
    service = MockInAppReviewService();
    notifyService = MockNotifyService();
  });

  RateAppViewModel createViewModel({
    String appStoreId = '123456789',
    String playStorePackageName = 'com.example.app',
    bool serviceInitialized = false,
    Future<bool> Function(Uri, {LaunchMode mode})? launch,
  }) {
    when(() => service.isInitialized).thenReturn(serviceInitialized);
    return RateAppViewModel(
      inAppReviewService: service,
      notifyService: notifyService,
      appStoreId: appStoreId,
      playStorePackageName: playStorePackageName,
      launch: launch,
    );
  }

  // ---------------------------------------------------------------------------
  // CTA state model
  // ---------------------------------------------------------------------------

  group('CTA state model', () {
    group('isServiceInitialized', () {
      test('returns true when service is initialized', () {
        final vm = createViewModel(serviceInitialized: true);
        expect(vm.isServiceInitialized, isTrue);
      });

      test('returns false when service is not initialized', () {
        final vm = createViewModel(serviceInitialized: false);
        expect(vm.isServiceInitialized, isFalse);
      });
    });

    group('hasFallbackStoreConfig', () {
      test('true on iOS with APP_STORE_ID', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(appStoreId: '123');
        expect(vm.hasFallbackStoreConfig, isTrue);
      });

      test('false on iOS without APP_STORE_ID', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(appStoreId: '');
        expect(vm.hasFallbackStoreConfig, isFalse);
      });

      test('true on macOS with APP_STORE_ID', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(appStoreId: '999');
        expect(vm.hasFallbackStoreConfig, isTrue);
      });

      test('false on macOS without APP_STORE_ID', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(appStoreId: '');
        expect(vm.hasFallbackStoreConfig, isFalse);
      });

      test('true on Android with PLAY_STORE_PACKAGE_NAME', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(playStorePackageName: 'com.example');
        expect(vm.hasFallbackStoreConfig, isTrue);
      });

      test('false on Android without PLAY_STORE_PACKAGE_NAME', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(playStorePackageName: '');
        expect(vm.hasFallbackStoreConfig, isFalse);
      });

      test('true on Linux with PLAY_STORE_PACKAGE_NAME', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(playStorePackageName: 'com.example');
        expect(vm.hasFallbackStoreConfig, isTrue);
      });

      test('false on Linux without PLAY_STORE_PACKAGE_NAME', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(playStorePackageName: '');
        expect(vm.hasFallbackStoreConfig, isFalse);
      });
    });

    group('canOpenStoreListing', () {
      test('true when service is initialized (regardless of fallback)', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(
          serviceInitialized: true,
          playStorePackageName: '',
        );
        expect(vm.canOpenStoreListing, isTrue);
      });

      test('true when fallback config available (service not initialized)', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(
          serviceInitialized: false,
          playStorePackageName: 'com.example',
        );
        expect(vm.canOpenStoreListing, isTrue);
      });

      test('false when neither service nor fallback available', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(
          serviceInitialized: false,
          playStorePackageName: '',
        );
        expect(vm.canOpenStoreListing, isFalse);
      });

      test('Android + initialized + no PLAY_STORE_PACKAGE_NAME = enabled', () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final vm = createViewModel(
          serviceInitialized: true,
          playStorePackageName: '',
        );
        expect(vm.canOpenStoreListing, isTrue);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Fallback URL mapping
  // ---------------------------------------------------------------------------

  group('fallback URL mapping', () {
    test('iOS builds App Store URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? launchedUri;
      final vm = createViewModel(
        appStoreId: '12345',
        serviceInitialized: false,
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(
        launchedUri.toString(),
        'https://apps.apple.com/app/id12345',
      );
    });

    test('macOS builds App Store URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? launchedUri;
      final vm = createViewModel(
        appStoreId: '99999',
        serviceInitialized: false,
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(
        launchedUri.toString(),
        'https://apps.apple.com/app/id99999',
      );
    });

    test('Android builds Play Store URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? launchedUri;
      final vm = createViewModel(
        playStorePackageName: 'com.example.app',
        serviceInitialized: false,
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(
        launchedUri.toString(),
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
    });

    test('Linux (desktop) builds Play Store URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? launchedUri;
      final vm = createViewModel(
        playStorePackageName: 'com.example.app',
        serviceInitialized: false,
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(
        launchedUri.toString(),
        'https://play.google.com/store/apps/details?id=com.example.app',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // openStoreListing dispatch
  // ---------------------------------------------------------------------------

  group('openStoreListing', () {
    test('delegates to native service when initialized', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      when(() => service.openStoreListing()).thenAnswer((_) async {});

      final vm = createViewModel(
        serviceInitialized: true,
        appStoreId: '123',
      );

      await vm.openStoreListing();

      verify(() => service.openStoreListing()).called(1);
    });

    test('uses fallback URL when service not initialized', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      var launched = false;
      final vm = createViewModel(
        serviceInitialized: false,
        appStoreId: '123',
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launched = true;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(launched, isTrue);
      verifyNever(() => service.openStoreListing());
    });

    test('shows toast on fallback launch exception', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final vm = createViewModel(
        serviceInitialized: false,
        appStoreId: '123',
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          throw Exception('launch failed');
        },
      );

      await vm.openStoreListing();

      verify(
        () => notifyService.setToastEvent(
          any(that: isA<ToastEventError>()),
        ),
      ).called(1);
    });

    test('shows toast when fallback launch returns false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final vm = createViewModel(
        serviceInitialized: false,
        appStoreId: '123',
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          return false;
        },
      );

      await vm.openStoreListing();

      verify(
        () => notifyService.setToastEvent(
          any(that: isA<ToastEventError>()),
        ),
      ).called(1);
    });

    test('no-ops when neither service nor fallback available', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      var launched = false;
      final vm = createViewModel(
        serviceInitialized: false,
        playStorePackageName: '',
        appStoreId: '',
        launch: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launched = true;
          return true;
        },
      );

      await vm.openStoreListing();

      expect(launched, isFalse);
      verifyNever(() => service.openStoreListing());
    });
  });

  // ---------------------------------------------------------------------------
  // requestReviewForScreen
  // ---------------------------------------------------------------------------

  group('requestReviewForScreen', () {
    test('delegates to service when initialized', () async {
      when(() => service.requestReviewForScreen()).thenAnswer((_) async {});

      final vm = createViewModel(serviceInitialized: true);

      await vm.requestReviewForScreen();

      verify(() => service.requestReviewForScreen()).called(1);
    });

    test('no-ops when service is not initialized', () async {
      final vm = createViewModel(serviceInitialized: false);

      await vm.requestReviewForScreen();

      verifyNever(() => service.requestReviewForScreen());
    });
  });

  // ---------------------------------------------------------------------------
  // Missing fallback config — no crash
  // ---------------------------------------------------------------------------

  group('missing fallback config', () {
    test('CTA disabled and no crash when config missing on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final vm = createViewModel(
        serviceInitialized: false,
        appStoreId: '',
      );

      expect(vm.canOpenStoreListing, isFalse);
      expect(vm.hasFallbackStoreConfig, isFalse);
    });

    test('CTA disabled and no crash when config missing on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final vm = createViewModel(
        serviceInitialized: false,
        playStorePackageName: '',
      );

      expect(vm.canOpenStoreListing, isFalse);
      expect(vm.hasFallbackStoreConfig, isFalse);
    });
  });
}
