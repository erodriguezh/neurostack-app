import 'package:neurostack/features/protocol/data/dtos/research_citation_dto.dart';
import '../../constants/test_constants.dart';

/// Factory for creating ResearchCitationDto test instances.
///
/// Provides valid DTOs and invalid variations for testing toDomain failures.
abstract final class ResearchCitationDtoFactory {
  /// Creates a valid ResearchCitationDto with optional overrides.
  ///
  /// Uses TestConstants.citation for defaults.
  static ResearchCitationDto create({
    String? authors,
    int? year,
    String? title,
    String? journal,
    String? doi,
    String? url,
  }) {
    return ResearchCitationDto(
      authors: authors ?? TestConstants.citation.authors,
      year: year ?? TestConstants.citation.year,
      title: title ?? TestConstants.citation.title,
      journal: journal ?? TestConstants.citation.journal,
      doi: doi ?? TestConstants.citation.doi,
      url: url,
    );
  }

  // --- State Variations (toDomain failures) ---

  /// Invalid: empty authors triggers Protocol.CitationAuthorsEmpty
  static ResearchCitationDto createWithEmptyAuthors() {
    return create(authors: '');
  }

  /// Invalid: empty title triggers Protocol.CitationTitleEmpty
  static ResearchCitationDto createWithEmptyTitle() {
    return create(title: '');
  }

  /// Invalid: empty journal triggers Protocol.CitationJournalEmpty
  static ResearchCitationDto createWithEmptyJournal() {
    return create(journal: '');
  }

  /// Invalid: year out of range triggers Protocol.CitationYearInvalid
  static ResearchCitationDto createWithInvalidYear() {
    return create(year: 1800); // Before 1900 threshold
  }

  // --- JSON Variations ---

  /// Valid JSON map with snake_case keys.
  static Map<String, dynamic> createValidJson({
    String? authors,
    int? year,
    String? title,
    String? journal,
    String? doi,
    String? url,
  }) {
    return {
      'authors': authors ?? TestConstants.citation.authors,
      'year': year ?? TestConstants.citation.year,
      'title': title ?? TestConstants.citation.title,
      'journal': journal ?? TestConstants.citation.journal,
      'doi': doi ?? TestConstants.citation.doi,
      'url': url,
    };
  }

  /// JSON missing a required field.
  static Map<String, dynamic> createJsonMissingField(String field) {
    final json = createValidJson();
    json.remove(field);
    return json;
  }
}
