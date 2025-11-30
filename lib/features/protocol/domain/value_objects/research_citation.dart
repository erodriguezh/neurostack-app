import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/failures/domain_failure.dart';
import '../failures/protocol_failures.dart';

part 'research_citation.freezed.dart';

/// Academic source backing a protocol.
///
/// Supports **INV-P1**: Every Protocol MUST have at least one Research Citation.
///
/// Example: "Wisløff et al. (2007). Superior cardiovascular... Circulation."
@freezed
sealed class ResearchCitation with _$ResearchCitation {
  const ResearchCitation._();

  const factory ResearchCitation._internal({
    required String authors,
    required int year,
    required String title,
    required String journal,
    String? doi,
    String? url,
  }) = _ResearchCitation;

  /// Creates a ResearchCitation value object with validation.
  ///
  /// Validation rules:
  /// - [authors] cannot be empty
  /// - [title] cannot be empty
  /// - [journal] cannot be empty
  /// - [year] must be between 1900 and current year + 1
  static Either<DomainFailure, ResearchCitation> create({
    required String authors,
    required int year,
    required String title,
    required String journal,
    String? doi,
    String? url,
  }) {
    final trimmedAuthors = authors.trim();
    final trimmedTitle = title.trim();
    final trimmedJournal = journal.trim();

    if (trimmedAuthors.isEmpty) {
      return left(ProtocolFailures.citationAuthorsEmpty);
    }

    if (trimmedTitle.isEmpty) {
      return left(ProtocolFailures.citationTitleEmpty);
    }

    if (trimmedJournal.isEmpty) {
      return left(ProtocolFailures.citationJournalEmpty);
    }

    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return left(ProtocolFailures.citationYearInvalid);
    }

    return right(ResearchCitation._internal(
      authors: trimmedAuthors,
      year: year,
      title: trimmedTitle,
      journal: trimmedJournal,
      doi: doi?.trim().isEmpty == true ? null : doi?.trim(),
      url: url?.trim().isEmpty == true ? null : url?.trim(),
    ));
  }

  /// Short citation format for compact display.
  /// Example: "Wisløff et al. (2007)"
  String get shortCitation {
    // Extract first author's last name
    final firstAuthor = authors.split(',').first.split(' ').first;
    final hasMultipleAuthors = authors.contains(',') || authors.contains('&') || authors.contains('and');
    final etAl = hasMultipleAuthors ? ' et al.' : '';
    return '$firstAuthor$etAl ($year)';
  }

  /// Full citation format for detailed display.
  /// Example: "Wisløff et al. (2007). Superior cardiovascular effect... Circulation. DOI: 10.1161/..."
  String get fullCitation {
    final shortTitle = title.length > 60 ? '${title.substring(0, 57)}...' : title;
    final citation = '$shortCitation. $shortTitle. $journal.';
    
    // Add DOI or URL if available (DOI preferred)
    if (doi != null && doi!.isNotEmpty) {
      return '$citation DOI: $doi';
    } else if (url != null && url!.isNotEmpty) {
      return '$citation URL: $url';
    }
    
    return citation;
  }
}
