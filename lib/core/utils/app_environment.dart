class AppEnvironment {
  static const String tag =
      String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  static bool get isDev => tag.toLowerCase() == 'dev';
}
