import 'dart:io' as io;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

const _maxCacheSize = 2 * 1024 * 1024;

/// Creates a platform-specific HTTP client for native platforms
http.Client httpClient() {
  if (io.Platform.isAndroid) {
    final engine = CronetEngine.build(
      cacheMode: CacheMode.memory,
      cacheMaxSize: _maxCacheSize,
      userAgent: 'Flutter Kit',
    );
    return CronetClient.fromCronetEngine(engine);
  } else if (io.Platform.isIOS || io.Platform.isMacOS) {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..cache = URLCache.withCapacity(memoryCapacity: _maxCacheSize)
      ..httpAdditionalHeaders = {'User-Agent': 'Flutter Kit'};
    return CupertinoClient.fromSessionConfiguration(config);
  } else {
    final httpClient = io.HttpClient();
    httpClient.userAgent = 'Flutter Kit';
    return IOClient(httpClient);
  }
}
