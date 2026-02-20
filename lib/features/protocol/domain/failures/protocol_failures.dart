import '../../../../core/failures/domain_failure.dart';

/// Domain failures specific to the Protocol aggregate.
///
/// Naming convention: `Protocol.{Invariant}`
abstract final class ProtocolFailures {
  // INV-P1: Every Protocol MUST have at least one Research Citation
  static const noCitations = DomainFailure(
    code: 'Protocol.NoCitations',
    message: 'Every protocol must have at least one research citation',
  );

  // INV-P3: Protocol names MUST NOT include researcher names
  static const nameEmpty = DomainFailure(
    code: 'Protocol.NameEmpty',
    message: 'Protocol name cannot be empty',
  );

  static const nameTooLong = DomainFailure(
    code: 'Protocol.NameTooLong',
    message: 'Protocol name cannot exceed 100 characters',
  );

  static const descriptionEmpty = DomainFailure(
    code: 'Protocol.DescriptionEmpty',
    message: 'Protocol description cannot be empty',
  );

  static const nameContainsResearcher = DomainFailure(
    code: 'Protocol.NameContainsResearcher',
    message: 'Protocol names must not include researcher names',
  );

  // Frequency validation
  static const invalidFrequency = DomainFailure(
    code: 'Protocol.InvalidFrequency',
    message: 'Frequency must be at least 1 per week',
  );

  static const maxLessThanMin = DomainFailure(
    code: 'Protocol.MaxLessThanMin',
    message: 'Maximum frequency cannot be less than minimum frequency',
  );

  // Research citation validation
  static const citationAuthorsEmpty = DomainFailure(
    code: 'Protocol.CitationAuthorsEmpty',
    message: 'Research citation must have authors',
  );

  static const citationTitleEmpty = DomainFailure(
    code: 'Protocol.CitationTitleEmpty',
    message: 'Research citation must have a title',
  );

  static const citationJournalEmpty = DomainFailure(
    code: 'Protocol.CitationJournalEmpty',
    message: 'Research citation must have a journal',
  );

  static const citationYearInvalid = DomainFailure(
    code: 'Protocol.CitationYearInvalid',
    message: 'Research citation year must be between 1900 and next year',
  );

  // Protocol state
  static const alreadyDeleted = DomainFailure(
    code: 'Protocol.AlreadyDeleted',
    message: 'Protocol has already been deleted',
  );
}
