import 'revenuecat_client.dart';
import 'revenuecat_client_stub.dart';

/// Creates the stub RevenueCatClient implementation for web.
///
/// This file is imported on web platform (fallback when dart:io is not available).
RevenueCatClient createPlatformRevenueCatClient() => RevenueCatClientStub();
