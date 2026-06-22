import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/config/route_config.dart';
import 'package:neurostack/core/utils/navigation/route_information_parser.dart';
import 'package:neurostack/core/utils/navigation/utils.dart';

void main() {
  test('isAuthCallbackUri only matches the callback path', () {
    expect(isAuthCallbackUri(Uri.parse('/auth/callback')), isTrue);
    expect(
      isAuthCallbackUri(Uri.parse('/?access_token=token&refresh_token=token')),
      isFalse,
    );
    expect(
      isAuthCallbackUri(Uri.parse('/#access_token=token&refresh_token=token')),
      isFalse,
    );
  });

  test('route parser sends old auth callback links to auth', () async {
    final parser = AppRouteInformationParser(routes: routes);

    final routeData = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/auth/callback?code=old')),
    );

    expect(routeData.uri.path, '/auth');
    expect(routeData.uri.queryParameters, isEmpty);
    expect(routeData.routePattern, '/auth');
  });
}
