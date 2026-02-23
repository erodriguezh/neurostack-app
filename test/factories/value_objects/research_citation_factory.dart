import 'package:fpdart/fpdart.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';
import '../../constants/test_constants.dart';
import '../factory_helpers.dart';

abstract final class ResearchCitationFactory {
  /// Creates a valid ResearchCitation using test constants.
  static ResearchCitation valid() {
    return unwrapOrThrow(
      ResearchCitation.create(
        authors: TestConstants.citation.authors,
        year: TestConstants.citation.year,
        title: TestConstants.citation.title,
        journal: TestConstants.citation.journal,
        doi: TestConstants.citation.doi,
      ),
      'ResearchCitation',
    );
  }

  /// Creates a ResearchCitation with custom values.
  /// Returns Either for testing validation failures.
  static Either<DomainFailure, ResearchCitation> create({
    required String authors,
    required int year,
    required String title,
    required String journal,
    String? doi,
    String? url,
  }) {
    return ResearchCitation.create(
      authors: authors,
      year: year,
      title: title,
      journal: journal,
      doi: doi,
      url: url,
    );
  }
}
