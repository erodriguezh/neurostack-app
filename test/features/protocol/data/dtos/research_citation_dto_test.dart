import 'package:flutter_test/flutter_test.dart';
import 'package:neurostack/features/protocol/data/dtos/research_citation_dto.dart';
import 'package:neurostack/features/protocol/domain/value_objects/research_citation.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/dtos/dtos.dart';
import '../../../../helpers/helpers.dart';
import '../../../../matchers/either_matchers.dart';

void main() {
  group('ResearchCitationDto', () {
    group('toDomain', () {
      test('toDomain_whenValid_returnsResearchCitation', () {
        // Arrange
        final dto = ResearchCitationDtoFactory.create();

        // Act
        final result = dto.toDomain();

        // Assert
        expect(result, isRight<ResearchCitation>());
      });

      final invalidCases = [
        (
          factory: ResearchCitationDtoFactory.createWithEmptyAuthors,
          code: 'Protocol.CitationAuthorsEmpty',
        ),
        (
          factory: ResearchCitationDtoFactory.createWithEmptyTitle,
          code: 'Protocol.CitationTitleEmpty',
        ),
        (
          factory: ResearchCitationDtoFactory.createWithEmptyJournal,
          code: 'Protocol.CitationJournalEmpty',
        ),
        (
          factory: ResearchCitationDtoFactory.createWithInvalidYear,
          code: 'Protocol.CitationYearInvalid',
        ),
      ];

      for (final c in invalidCases) {
        test('toDomain_when${c.code.split('.').last}_returnsFailure', () {
          // Arrange
          final dto = c.factory();

          // Act
          final result = dto.toDomain();

          // Assert
          expect(
            result,
            isLeftWithCode<ResearchCitation>(c.code),
          );
        });
      }
    });

    group('fromJson', () {
      test('fromJson_whenValid_returnsDto', () {
        // Arrange
        final json = ResearchCitationDtoFactory.createValidJson();

        // Act
        final dto = ResearchCitationDto.fromJson(json);

        // Assert
        expect(dto.authors, TestConstants.citation.authors);
        expect(dto.year, TestConstants.citation.year);
        expect(dto.title, TestConstants.citation.title);
        expect(dto.journal, TestConstants.citation.journal);
        expect(dto.doi, TestConstants.citation.doi);
      });

      final requiredFields = ['authors', 'year', 'title', 'journal'];

      for (final field in requiredFields) {
        test('fromJson_whenMissing${pascalCase(field)}_throws', () {
          // Arrange
          final json = ResearchCitationDtoFactory.createJsonMissingField(field);

          // Act & Assert
          expect(
            () => ResearchCitationDto.fromJson(json),
            throwsA(isA<TypeError>()),
          );
        });
      }

      test('fromJson_whenNullDoi_succeeds', () {
        // Arrange — construct directly to bypass factory default
        final json = ResearchCitationDtoFactory.createValidJson();
        json['doi'] = null;

        // Act
        final dto = ResearchCitationDto.fromJson(json);

        // Assert
        expect(dto.doi, isNull);
      });

      test('fromJson_whenNullUrl_succeeds', () {
        // Arrange — url defaults to null in factory, but be explicit
        final json = ResearchCitationDtoFactory.createValidJson();
        json['url'] = null;

        // Act
        final dto = ResearchCitationDto.fromJson(json);

        // Assert
        expect(dto.url, isNull);
      });
    });

    group('fromDomain roundtrip', () {
      test('fromDomain_roundtrip_preservesAllFields', () {
        // Arrange
        final original = ResearchCitationDtoFactory.create(
          url: 'https://example.com/paper',
        );
        final domainResult = original.toDomain();
        expect(domainResult, isRight<ResearchCitation>());
        final domain = domainResult.getOrElse(
          (l) => throw Exception('Failed: $l'),
        );

        // Act
        final restored = ResearchCitationDto.fromDomain(domain);

        // Assert
        expect(restored.authors, original.authors);
        expect(restored.year, original.year);
        expect(restored.title, original.title);
        expect(restored.journal, original.journal);
        expect(restored.doi, original.doi);
        expect(restored.url, original.url);
      });

      test('fromJson_toJson_roundtrip_preservesKeys', () {
        // Arrange
        final json = ResearchCitationDtoFactory.createValidJson();

        // Act
        final dto = ResearchCitationDto.fromJson(json);
        final reserialized = dto.toJson();

        // Assert
        expect(reserialized['authors'], TestConstants.citation.authors);
        expect(reserialized['year'], TestConstants.citation.year);
        expect(reserialized['title'], TestConstants.citation.title);
        expect(reserialized['journal'], TestConstants.citation.journal);
        expect(reserialized['doi'], TestConstants.citation.doi);
      });
    });
  });
}
