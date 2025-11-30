import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/domain/failures/protocol_failures.dart';
import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';
import '../../../constants/test_constants.dart';
import '../../../factories/factories.dart';
import '../../../matchers/either_matchers.dart';

void main() {
  group('ResearchCitation', () {
    group('create succeeds', () {
      test('create_withValidData_succeeds', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: TestConstants.citation.authors,
          year: TestConstants.citation.year,
          title: TestConstants.citation.title,
          journal: TestConstants.citation.journal,
          doi: TestConstants.citation.doi,
        );

        // Assert
        expect(result, isRight<ResearchCitation>());
      });

      test('create_withoutDoi_succeeds', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: 'Smith J',
          year: 2020,
          title: 'A Study',
          journal: 'Science',
        );

        // Assert
        expect(result, isRight<ResearchCitation>());
      });

      test('create_withUrl_succeeds', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: 'Smith J',
          year: 2020,
          title: 'A Study',
          journal: 'Science',
          url: 'https://example.com/study',
        );

        // Assert
        expect(result, isRight<ResearchCitation>());
      });
    });

    group('create fails', () {
      test('create_whenAuthorsEmpty_returnsCitationAuthorsEmpty', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: '',
          year: 2020,
          title: 'A Study',
          journal: 'Science',
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.citationAuthorsEmpty));
      });

      test('create_whenTitleEmpty_returnsCitationTitleEmpty', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: 'Smith J',
          year: 2020,
          title: '',
          journal: 'Science',
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.citationTitleEmpty));
      });

      test('create_whenJournalEmpty_returnsCitationJournalEmpty', () {
        // Act
        final result = ResearchCitationFactory.create(
          authors: 'Smith J',
          year: 2020,
          title: 'A Study',
          journal: '',
        );

        // Assert
        expect(result, isLeftWith(ProtocolFailures.citationJournalEmpty));
      });

      final invalidYearCases = [
        (year: 1899, desc: 'before1900'),
        (year: 2027, desc: 'futureYear'),
      ];

      for (final c in invalidYearCases) {
        test('create_when${c.desc}_returnsCitationYearInvalid', () {
          // Act
          final result = ResearchCitationFactory.create(
            authors: 'Smith J',
            year: c.year,
            title: 'A Study',
            journal: 'Science',
          );

          // Assert
          expect(result, isLeftWith(ProtocolFailures.citationYearInvalid));
        });
      }
    });

    group('shortCitation', () {
      test('shortCitation_returnsAuthorYearFormat', () {
        // Arrange
        final citation = ResearchCitationFactory.valid();

        // Act
        final short = citation.shortCitation;

        // Assert
        expect(short, 'Wisløff et al. (2007)');
      });
    });

    group('fullCitation', () {
      test('fullCitation_withDoi_includesDoiLink', () {
        // Arrange
        final citation = ResearchCitationFactory.valid();

        // Act
        final full = citation.fullCitation;

        // Assert
        expect(full, contains('Wisløff U, Støylen A, Loennechen JP'));
        expect(full, contains('2007'));
        expect(full, contains('Superior cardiovascular effect'));
        expect(full, contains('Circulation'));
        expect(full, contains('10.1161/CIRCULATIONAHA.106.675041'));
      });

      test('fullCitation_withUrl_includesUrl', () {
        // Arrange
        final citation = ResearchCitationFactory.create(
          authors: 'Smith J',
          year: 2020,
          title: 'A Study',
          journal: 'Science',
          url: 'https://example.com/study',
        ).getOrElse((l) => throw Exception('Failed to create citation: $l'));

        // Act
        final full = citation.fullCitation;

        // Assert
        expect(full, contains('https://example.com/study'));
      });
    });
  });
}
