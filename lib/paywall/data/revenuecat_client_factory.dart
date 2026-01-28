import 'revenuecat_client.dart';
import 'revenuecat_client_factory_stub.dart'
    if (dart.library.io) 'revenuecat_client_factory_mobile.dart';

/// Creates the platform-appropriate [RevenueCatClient] implementation.
///
/// Uses conditional imports to return:
/// - [RevenueCatClientMobile] on iOS, Android, and macOS (dart.library.io)
/// - [RevenueCatClientStub] on web (fallback)
///
/// This pattern allows the app to compile for web without importing
/// purchases_flutter (which doesn't support web).
RevenueCatClient createRevenueCatClient() => createPlatformRevenueCatClient();
