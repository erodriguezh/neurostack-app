import 'package:supabase_flutter/supabase_flutter.dart';

initDataSource() async {
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: '',
    ),
  );
}
