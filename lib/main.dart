import 'package:flutter/material.dart';
import 'package:neurostack/core/utils/data_source/data_source_init.dart';
import 'package:neurostack/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:neurostack/startup/startup_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDataSource();
  configureUrlStrategy();
  runApp(const StartupView());
}
