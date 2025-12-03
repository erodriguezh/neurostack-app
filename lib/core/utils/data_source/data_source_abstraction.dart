import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper for testability.
/// Community pattern from GitHub issue #864 discussions.
class DataSourceAbstraction {
  final SupabaseClient _client;

  DataSourceAbstraction(this._client);

  /// Factory for production use
  factory DataSourceAbstraction.instance() =>
      DataSourceAbstraction(Supabase.instance.client);

  SupabaseClient get client => _client;

  SupabaseQueryBuilder from(String table) => _client.from(table);
  GoTrueClient get auth => _client.auth;
  SupabaseStorageClient get storage => _client.storage;
  RealtimeClient get realtime => _client.realtime;
}
