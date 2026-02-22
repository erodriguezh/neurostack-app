import 'package:neurostack/features/protocol/data/dtos/protocol_dto.dart';
import 'package:neurostack/features/protocol/data/dtos/research_citation_dto.dart'
    show ResearchCitationDto;
import 'package:neurostack/features/protocol/data/dtos/target_dto.dart';
import '../../constants/test_constants.dart';
import 'research_citation_dto_factory.dart';
import 'target_dto_factory.dart';

/// Factory for creating ProtocolDto test instances.
///
/// Provides valid DTOs and invalid variations for testing toDomain failures.
abstract final class ProtocolDtoFactory {
  // --- Core Factory ---

  /// Creates a valid ProtocolDto with optional overrides.
  ///
  /// Default: Valid exercise protocol with single citation.
  static ProtocolDto create({
    String? id,
    String? name,
    String? description,
    TargetDto? target,
    String category = 'exercise',
    String evidenceLevel = 'multipleRcts',
    List<ResearchCitationDto>? citations,
    String? createdAt,
    String? deletedAt,
  }) {
    return ProtocolDto(
      id: id ?? TestConstants.dto.defaultProtocolId,
      name: name ?? TestConstants.protocol.validName,
      description: description ?? TestConstants.protocol.validDescription,
      target: target ?? TargetDtoFactory.create(),
      category: category,
      evidenceLevel: evidenceLevel,
      citations: citations ?? [ResearchCitationDtoFactory.create()],
      createdAt: createdAt ?? TestConstants.dto.validIsoDateTime,
      deletedAt: deletedAt,
    );
  }

  // --- State Variations (toDomain failures) ---

  /// Name fails ProtocolName.create validation (too long)
  /// Triggers Protocol.NameTooLong
  static ProtocolDto createWithInvalidName() {
    return create(name: TestConstants.protocol.tooLongName);
  }

  /// Name contains researcher name pattern
  /// Triggers Protocol.NameContainsResearcher
  static ProtocolDto createWithResearcherName() {
    return create(name: TestConstants.protocol.researcherNamePossessive);
  }

  /// Invalid category enum string
  /// Triggers Dto.InvalidCategory
  static ProtocolDto createWithInvalidCategory() {
    return create(category: TestConstants.dto.invalidCategory);
  }

  /// Invalid evidenceLevel enum string
  /// Triggers Dto.InvalidEvidenceLevel
  static ProtocolDto createWithInvalidEvidenceLevel() {
    return create(evidenceLevel: TestConstants.dto.invalidEvidenceLevel);
  }

  /// Invalid date format
  /// Triggers Dto.ParseError
  static ProtocolDto createWithInvalidDateTime() {
    return create(createdAt: TestConstants.dto.invalidDateTime);
  }

  /// Nested Target fails validation (invalid frequency)
  /// Triggers Protocol.InvalidFrequency
  static ProtocolDto createWithInvalidTarget() {
    return create(target: TargetDtoFactory.createWithInvalidFrequency());
  }

  /// Nested citation fails validation (empty authors)
  /// Triggers Protocol.CitationAuthorsEmpty
  static ProtocolDto createWithInvalidCitation() {
    return create(
      citations: [ResearchCitationDtoFactory.createWithEmptyAuthors()],
    );
  }

  /// Description fails ProtocolDescription.create validation (empty)
  /// Triggers Protocol.DescriptionEmpty
  static ProtocolDto createWithEmptyDescription() {
    return create(description: TestConstants.protocol.emptyDescription);
  }

  /// Empty citations list
  /// Note: toDomain succeeds, but Protocol.create would fail with NoCitations
  static ProtocolDto createWithEmptyCitations() {
    return create(citations: []);
  }

  // --- JSON Variations (fromJson failures) ---

  /// Valid JSON map matching generated fromJson/toJson keys.
  static Map<String, dynamic> createValidJson({String? id}) {
    return {
      'id': id ?? TestConstants.dto.defaultProtocolId,
      'name': TestConstants.protocol.validName,
      'description': TestConstants.protocol.validDescription,
      'target': TargetDtoFactory.createValidJson(),
      'category': 'exercise',
      'evidence_level': 'multipleRcts',
      'research_citations': [ResearchCitationDtoFactory.createValidJson()],
      'created_at': TestConstants.dto.validIsoDateTime,
    };
  }

  /// JSON missing a required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }

  /// JSON with wrong type for a field.
  static Map<String, dynamic> createJsonWithWrongType(
    String field,
    Object value,
  ) {
    final json = createValidJson();
    json[field] = value;
    return json;
  }
}
