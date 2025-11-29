import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:neurostack/startup/startup_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  runApp(const StartupView());
}
