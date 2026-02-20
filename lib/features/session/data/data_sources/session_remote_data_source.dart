import '../../../../core/utils/data_source/data_source_abstraction.dart';
import '../dtos/session_dto.dart';
import '../dtos/session_insert_dto.dart';

/// Remote data source for Session aggregate.
///
/// Handles all Supabase table operations for sessions.
/// Returns [SessionDto] objects, not raw JSON.
class SessionRemoteDataSource {
  final DataSourceAbstraction _dataSource;

  SessionRemoteDataSource(this._dataSource);

  static const _table = 'sessions';

  /// Retrieves a single session by ID.
  ///
  /// Throws [Exception] if session not found or connection fails.
  Future<SessionDto> getSession(String id) async {
    final json = await _dataSource.from(_table).select().eq('id', id).single();
    return SessionDto.fromJson(json);
  }

  /// Queries sessions with optional filters.
  ///
  /// All filters combine with AND logic. Returns empty list if no matches.
  /// Date range filtering is critical for streak calculation and calendar views.
  Future<List<SessionDto>> getSessions({
    String? protocolId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _dataSource.from(_table).select();

    if (protocolId != null) {
      query = query.eq('protocol_id', protocolId);
    }

    if (from != null) {
      query = query.gte('completed_at', from.toIso8601String());
    }

    if (to != null) {
      query = query.lte('completed_at', to.toIso8601String());
    }

    final jsonList = await query;
    return jsonList
        .map<SessionDto>((json) => SessionDto.fromJson(json))
        .toList();
  }

  /// Persists a session and returns the inserted record.
  ///
  /// Sessions are immutable after creation, so this issues an insert and lets
  /// the database generate the identity primary key.
  Future<SessionDto> createSession(SessionInsertDto dto) async {
    final json = await _dataSource
        .from(_table)
        .insert(dto.toJson())
        .select()
        .single();
    return SessionDto.fromJson(json);
  }
}
