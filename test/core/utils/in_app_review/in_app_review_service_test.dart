import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neurostack/core/utils/in_app_review/in_app_review_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';

import '../../../mocks/mock_services.dart';

void main() {
  late MockInAppReviewAdapter adapter;
  late MockNotifyService notifyService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    adapter = MockInAppReviewAdapter();
    notifyService = MockNotifyService();
  });

  InAppReviewService createService({
    String appStoreId = '123456789',
    String playStorePackageName = 'com.example.app',
  }) {
    return InAppReviewService(
      prefs: prefs,
      notifyService: notifyService,
      adapter: adapter,
      appStoreId: appStoreId,
      playStorePackageName: playStorePackageName,
    );
  }

  group('init', () {
    test('initializes on iOS with valid APP_STORE_ID', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createService(appStoreId: '123456789');
      service.init();

      expect(service.isInitialized, isTrue);
    });

    test('initializes on Android without APP_STORE_ID', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createService(appStoreId: '');
      service.init();

      expect(service.isInitialized, isTrue);
    });

    test('stays uninitialized on iOS when APP_STORE_ID is empty', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createService(appStoreId: '');
      service.init();

      expect(service.isInitialized, isFalse);
    });

    test('stays uninitialized on non-mobile platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createService();
      service.init();

      expect(service.isInitialized, isFalse);
    });
  });

  group('requestReviewIfNeeded', () {
    late InAppReviewService service;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      when(() => adapter.isAvailable()).thenAnswer((_) async => true);
      when(() => adapter.requestReview()).thenAnswer((_) async {});

      service = createService();
      service.init();
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('no-op when not initialized', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final uninitService = createService();
      uninitService.init();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await uninitService.requestReviewIfNeeded(5, 'user-1');

      verifyNever(() => adapter.isAvailable());
      verifyNever(() => adapter.requestReview());
    });

    test('does not trigger below first threshold (4 < 5)', () async {
      await service.requestReviewIfNeeded(4, 'user-1');

      verifyNever(() => adapter.requestReview());
    });

    test('triggers at first threshold (5)', () async {
      await service.requestReviewIfNeeded(5, 'user-1');

      verify(() => adapter.requestReview()).called(1);
    });

    test('does not re-trigger between thresholds (6)', () async {
      await service.requestReviewIfNeeded(5, 'user-1');
      await service.requestReviewIfNeeded(6, 'user-1');

      verify(() => adapter.requestReview()).called(1);
    });

    test('triggers at second threshold (15)', () async {
      await service.requestReviewIfNeeded(5, 'user-1');
      await service.requestReviewIfNeeded(15, 'user-1');

      verify(() => adapter.requestReview()).called(2);
    });

    test('triggers at third threshold (35)', () async {
      await service.requestReviewIfNeeded(5, 'user-1');
      await service.requestReviewIfNeeded(15, 'user-1');
      await service.requestReviewIfNeeded(35, 'user-1');

      verify(() => adapter.requestReview()).called(3);
    });

    test('does not trigger after all thresholds exhausted (36)', () async {
      await service.requestReviewIfNeeded(5, 'user-1');
      await service.requestReviewIfNeeded(15, 'user-1');
      await service.requestReviewIfNeeded(35, 'user-1');
      await service.requestReviewIfNeeded(36, 'user-1');

      verify(() => adapter.requestReview()).called(3);
    });

    test('persists index in SharedPreferences', () async {
      await service.requestReviewIfNeeded(5, 'user-1');

      expect(prefs.getInt('review_request_index_user-1'), equals(1));
    });

    test('index survives across service instances', () async {
      await service.requestReviewIfNeeded(5, 'user-1');

      // Create a new service instance with the same prefs.
      final service2 = createService();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      service2.init();

      // 5 should not trigger again because index is already 1.
      await service2.requestReviewIfNeeded(5, 'user-1');
      // Only the first call triggered it.
      verify(() => adapter.requestReview()).called(1);
    });

    test('user-scoped: different users have independent indices', () async {
      await service.requestReviewIfNeeded(5, 'user-1');
      await service.requestReviewIfNeeded(5, 'user-2');

      verify(() => adapter.requestReview()).called(2);
    });

    test('skips when adapter.isAvailable() returns false', () async {
      when(() => adapter.isAvailable()).thenAnswer((_) async => false);

      await service.requestReviewIfNeeded(5, 'user-1');

      verifyNever(() => adapter.requestReview());
      // Index should NOT be incremented.
      expect(prefs.getInt('review_request_index_user-1'), isNull);
    });

    test('silently catches adapter exceptions', () async {
      when(() => adapter.requestReview()).thenThrow(Exception('iOS freeze'));

      await service.requestReviewIfNeeded(5, 'user-1');

      // Should not throw, and should not show toast (silent).
      verifyNever(() => notifyService.setToastEvent(any()));
    });
  });

  group('requestReviewForScreen', () {
    late InAppReviewService service;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      when(() => adapter.isAvailable()).thenAnswer((_) async => true);
      when(() => adapter.requestReview()).thenAnswer((_) async {});
      when(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).thenAnswer((_) async {});

      service = createService();
      service.init();
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('no-op when not initialized', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final uninitService = createService();
      uninitService.init();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await uninitService.requestReviewForScreen();

      verifyNever(() => adapter.isAvailable());
    });

    test('calls requestReview() when available', () async {
      await service.requestReviewForScreen();

      verify(() => adapter.requestReview()).called(1);
      verifyNever(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      );
    });

    test('falls back to openStoreListing when not available', () async {
      when(() => adapter.isAvailable()).thenAnswer((_) async => false);

      await service.requestReviewForScreen();

      verifyNever(() => adapter.requestReview());
      verify(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).called(1);
    });

    test('falls back to openStoreListing on requestReview failure', () async {
      when(() => adapter.requestReview()).thenThrow(Exception('boom'));

      await service.requestReviewForScreen();

      verify(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).called(1);
    });
  });

  group('openStoreListing', () {
    test('no-op when not initialized', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createService();
      service.init();

      await service.openStoreListing();

      verifyNever(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      );
    });

    test('passes appStoreId on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      when(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).thenAnswer((_) async {});

      final service = createService(appStoreId: '999');
      service.init();

      await service.openStoreListing();

      verify(() => adapter.openStoreListing(appStoreId: '999')).called(1);
    });

    test('passes null appStoreId on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      when(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).thenAnswer((_) async {});

      final service = createService(appStoreId: '999');
      service.init();

      await service.openStoreListing();

      verify(() => adapter.openStoreListing(appStoreId: null)).called(1);
    });

    test('shows error toast on failure', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      when(
        () => adapter.openStoreListing(appStoreId: any(named: 'appStoreId')),
      ).thenThrow(Exception('network error'));

      final service = createService();
      service.init();

      await service.openStoreListing();

      final captured = verify(
        () => notifyService.setToastEvent(captureAny()),
      ).captured;
      expect(captured.single, isA<ToastEventError>());
      expect(
        (captured.single as ToastEventError).message,
        'Could not open store listing',
      );
    });
  });
}
