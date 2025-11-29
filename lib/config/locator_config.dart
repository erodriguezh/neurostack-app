import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/http/http_abstraction.dart';
import 'package:neurostack/core/utils/http/http_interceptor.dart';
import 'package:neurostack/config/route_config.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';

final modules = [
  Module<RouterService>(
    builder: () => RouterService(supportedRoutes: routes),
    lazy: false,
  ),
  Module<NotifyService>(builder: () => NotifyService(), lazy: false),
  Module<HttpAbstraction>(
    builder: () => HttpAbstraction(
      interceptors: [
        LoggingInterceptor(
          logBody: !kReleaseMode, // Only log bodies in debug mode
        ),
      ],
    ),
    lazy: true,
  ),
];
