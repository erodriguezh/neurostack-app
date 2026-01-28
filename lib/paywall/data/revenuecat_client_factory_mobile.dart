import 'revenuecat_client.dart';
import 'revenuecat_client_mobile.dart';

/// Creates the mobile RevenueCatClient implementation.
///
/// This file is imported on platforms that support dart:io (iOS, Android, macOS).
RevenueCatClient createPlatformRevenueCatClient() => RevenueCatClientMobile();
