import '../../../../core/utils/data_source/data_source_abstraction.dart';
import '../../domain/enums/category.dart';
import '../../domain/enums/evidence_level.dart';
import '../dtos/protocol_dto.dart';

/// Remote data source for Protocol aggregate.
///
/// Handles all Supabase table operations for protocols and their related
/// research citations. Returns [ProtocolDto] objects, not raw JSON.
class ProtocolRemoteDataSource {
  final DataSourceAbstraction _dataSource;

  ProtocolRemoteDataSource(this._dataSource);

  static const _table = 'protocols';
  static const _citationsTable = 'research_citations';

  /// Retrieves a single protocol by ID with all related citations.
  ///
  /// Uses Supabase's relation syntax to fetch nested citations in one query.
  /// Throws [Exception] if protocol not found or connection fails.
  Future<ProtocolDto> getProtocol(String id) async {
    final json = await _dataSource
        .from(_table)
        .select('*, research_citations(*)')
        .eq('id', id)
        .single();
    return ProtocolDto.fromJson(json);
  }

  /// Queries protocols with optional filters.
  ///
  /// All filters combine with AND logic. Returns empty list if no matches.
  Future<List<ProtocolDto>> getProtocols({
    Category? category,
    EvidenceLevel? evidenceLevel,
    bool? activeOnly,
  }) async {
    var query = _dataSource.from(_table).select('*, research_citations(*)');

    if (category != null) {
      query = query.eq('category', category.name);
    }

    if (evidenceLevel != null) {
      query = query.eq('evidence_level', evidenceLevel.name);
    }

    if (activeOnly == true) {
      query = query.isFilter('deleted_at', null);
    }

    final jsonList = await query;
    return jsonList
        .map<ProtocolDto>((json) => ProtocolDto.fromJson(json))
        .toList();
  }

  /// Persists a protocol (insert or update).
  ///
  /// Handles both the protocol record and its citations:
  /// 1. Upsert the protocol
  /// 2. Delete old citations
  /// 3. Insert new citations
  ///
  /// Note: This is not transactional. For atomic operations, use Edge Functions.
  Future<void> saveProtocol(ProtocolDto dto) async {
    // 1. Upsert the main protocol record
    final protocolJson = dto.toJson();
    // Remove citations from protocol JSON - they're in a separate table
    protocolJson.remove('citations');
    protocolJson.remove('research_citations');
    await _dataSource.from(_table).upsert(protocolJson);

    // 2. Delete existing citations for this protocol
    await _dataSource.from(_citationsTable).delete().eq('protocol_id', dto.id);

    // 3. Insert new citations
    if (dto.citations.isNotEmpty) {
      final citationsJson = dto.citations.map((citation) {
        final json = citation.toJson();
        // Add protocol_id foreign key
        json['protocol_id'] = dto.id;
        return json;
      }).toList();

      await _dataSource.from(_citationsTable).insert(citationsJson);
    }
  }
}
