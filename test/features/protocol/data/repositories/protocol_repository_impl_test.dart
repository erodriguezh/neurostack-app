import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/failures/domain_failure.dart';
import 'package:neurostack/features/protocol/data/repositories/protocol_repository_impl.dart';
import 'package:neurostack/features/protocol/domain/entities/protocol.dart';
import 'package:neurostack/features/protocol/domain/enums/category.dart';
import 'package:neurostack/features/protocol/domain/enums/evidence_level.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/test_constants.dart';
import '../../../../factories/dtos/dtos.dart';
import '../../../../factories/protocol_factory.dart';
import '../../../../matchers/either_matchers.dart';
import '../../../../mocks/data_source_mocks.dart';

void main() {
  late MockProtocolRemoteDataSource mockDataSource;
  late ProtocolRepositoryImpl sut;

  setUpAll(() {
    // Required by mocktail for any() with custom types
    registerFallbackValue(ProtocolDtoFactory.create());
  });

  setUp(() {
    mockDataSource = MockProtocolRemoteDataSource();
    sut = ProtocolRepositoryImpl(mockDataSource);
  });

  group('ProtocolRepositoryImpl', () {
    // Shared error cases for all repository methods (parameterized tests)
    final errorCases = [
      (code: TestConstants.postgrest.notFound, expected: 'Protocol.NotFound'),
      (
        code: TestConstants.postgrest.uniqueViolation,
        expected: 'Protocol.DuplicateRecord',
      ),
      (
        code: TestConstants.postgrest.foreignKeyViolation,
        expected: 'Protocol.InvalidReference',
      ),
      (
        code: TestConstants.postgrest.rlsViolation,
        expected: 'Protocol.PermissionDenied',
      ),
      (
        code: TestConstants.postgrest.connectionFailed,
        expected: 'Protocol.ConnectionFailed',
      ),
    ];

    group('getById', () {
      test('getById_whenDataSourceSucceeds_returnsProtocol', () async {
        // Arrange
        final dto = ProtocolDtoFactory.create(id: 'protocol-123');
        when(
          () => mockDataSource.getProtocol('protocol-123'),
        ).thenAnswer((_) async => dto);

        // Act
        final result = await sut.getById('protocol-123');

        // Assert
        expect(result, isRight<Protocol>());
        result.match(
          (_) => fail('Expected Right'),
          (protocol) {
            expect(protocol.id, 'protocol-123');
            verify(() => mockDataSource.getProtocol('protocol-123')).called(1);
          },
        );
      });

      for (final c in errorCases) {
        test(
          'getById_when${c.expected.split('.').last}_returnsFailure',
          () async {
            // Arrange
            when(() => mockDataSource.getProtocol(any())).thenThrow(
              PostgrestException(code: c.code, message: 'test error'),
            );

            // Act
            final result = await sut.getById('any-id');

            // Assert
            expect(result, isLeftWithCode<Protocol>(c.expected));
          },
        );
      }

      test('getById_whenAuthException_returnsAuthFailure', () async {
        // Arrange
        when(() => mockDataSource.getProtocol(any())).thenThrow(
          AuthException('Session expired'),
        );

        // Act
        final result = await sut.getById('any-id');

        // Assert
        expect(
          result,
          isLeftWithCode<Protocol>('Protocol.AuthenticationFailed'),
        );
      });

      test('getById_whenDtoValidationFails_returnsFailure', () async {
        // Arrange - DTO that fails toDomain
        final invalidDto = ProtocolDtoFactory.createWithInvalidCategory();
        when(
          () => mockDataSource.getProtocol('invalid-protocol'),
        ).thenAnswer((_) async => invalidDto);

        // Act
        final result = await sut.getById('invalid-protocol');

        // Assert
        expect(result, isLeftWithCode<Protocol>('Dto.InvalidCategory'));
      });

      test('getById_whenUnexpectedError_returnsUnknownFailure', () async {
        // Arrange
        when(
          () => mockDataSource.getProtocol(any()),
        ).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await sut.getById('any-id');

        // Assert
        expect(result, isLeftWithCode<Protocol>('Protocol.UnexpectedError'));
      });
    });

    group('list', () {
      test('list_whenDataSourceReturnsEmpty_returnsEmptyList', () async {
        // Arrange
        when(
          () => mockDataSource.getProtocols(
            category: any(named: 'category'),
            evidenceLevel: any(named: 'evidenceLevel'),
            activeOnly: any(named: 'activeOnly'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await sut.list();

        // Assert
        expect(result, isRight<List<Protocol>>());
        result.match(
          (_) => fail('Expected Right'),
          (protocols) => expect(protocols, isEmpty),
        );
      });

      test('list_whenDataSourceSucceeds_returnsProtocols', () async {
        // Arrange
        final dtos = [
          ProtocolDtoFactory.create(id: 'p1'),
          ProtocolDtoFactory.create(id: 'p2'),
          ProtocolDtoFactory.create(id: 'p3'),
        ];
        when(
          () => mockDataSource.getProtocols(
            category: any(named: 'category'),
            evidenceLevel: any(named: 'evidenceLevel'),
            activeOnly: any(named: 'activeOnly'),
          ),
        ).thenAnswer((_) async => dtos);

        // Act
        final result = await sut.list();

        // Assert
        expect(result, isRight<List<Protocol>>());
        result.match(
          (_) => fail('Expected Right'),
          (protocols) {
            expect(protocols.length, 3);
            expect(protocols[0].id, 'p1');
            expect(protocols[1].id, 'p2');
            expect(protocols[2].id, 'p3');
          },
        );
      });

      test('list_whenOneDtoInvalid_returnsFailure', () async {
        // Arrange - Second DTO fails validation
        final dtos = [
          ProtocolDtoFactory.create(id: 'valid'),
          ProtocolDtoFactory.createWithInvalidCategory(),
        ];
        when(
          () => mockDataSource.getProtocols(
            category: any(named: 'category'),
            evidenceLevel: any(named: 'evidenceLevel'),
            activeOnly: any(named: 'activeOnly'),
          ),
        ).thenAnswer((_) async => dtos);

        // Act
        final result = await sut.list();

        // Assert
        expect(result, isLeftWithCode<List<Protocol>>('Dto.InvalidCategory'));
      });

      test('list_passesFiltersToDataSource', () async {
        // Arrange
        when(
          () => mockDataSource.getProtocols(
            category: Category.exercise,
            evidenceLevel: EvidenceLevel.multipleRcts,
            activeOnly: true,
          ),
        ).thenAnswer((_) async => []);

        // Act
        await sut.list(
          category: Category.exercise,
          evidenceLevel: EvidenceLevel.multipleRcts,
          activeOnly: true,
        );

        // Assert
        verify(
          () => mockDataSource.getProtocols(
            category: Category.exercise,
            evidenceLevel: EvidenceLevel.multipleRcts,
            activeOnly: true,
          ),
        ).called(1);
      });

      test('list_withNullFilters_passesNullToDataSource', () async {
        // Arrange
        when(
          () => mockDataSource.getProtocols(
            category: null,
            evidenceLevel: null,
            activeOnly: null,
          ),
        ).thenAnswer((_) async => []);

        // Act
        await sut.list();

        // Assert
        verify(
          () => mockDataSource.getProtocols(
            category: null,
            evidenceLevel: null,
            activeOnly: null,
          ),
        ).called(1);
      });

      // Reuse error mapping pattern for list
      for (final c in errorCases) {
        test('list_when${c.expected.split('.').last}_returnsFailure', () async {
          // Arrange
          when(
            () => mockDataSource.getProtocols(
              category: any(named: 'category'),
              evidenceLevel: any(named: 'evidenceLevel'),
              activeOnly: any(named: 'activeOnly'),
            ),
          ).thenThrow(
            PostgrestException(code: c.code, message: 'test error'),
          );

          // Act
          final result = await sut.list();

          // Assert
          expect(result, isLeftWithCode<List<Protocol>>(c.expected));
        });
      }
    });

    group('save', () {
      test('save_whenDataSourceSucceeds_returnsUnit', () async {
        // Arrange
        final protocolResult = ProtocolFactory.create();

        final protocol = protocolResult.getRight().toNullable()!;

        when(() => mockDataSource.saveProtocol(any())).thenAnswer((_) async {});

        // Act
        final result = await sut.save(protocol);

        // Assert
        expect(result, isRight<Unit>());
      });

      test('save_callsDataSourceWithCorrectDto', () async {
        // Arrange
        final protocolResult = ProtocolFactory.create();

        final protocol = protocolResult.getRight().toNullable()!;

        when(() => mockDataSource.saveProtocol(any())).thenAnswer((_) async {});

        // Act
        await sut.save(protocol);

        // Assert
        final captured = verify(
          () => mockDataSource.saveProtocol(captureAny()),
        ).captured.single;

        expect(captured.id, protocol.id);
        expect(captured.name, protocol.name.value);
        expect(captured.category, 'exercise');
      });

      // Reuse error mapping tests pattern for save
      for (final c in errorCases) {
        test('save_when${c.expected.split('.').last}_returnsFailure', () async {
          // Arrange
          final protocolResult = ProtocolFactory.create();

          final protocol = protocolResult.getRight().toNullable()!;

          when(() => mockDataSource.saveProtocol(any())).thenThrow(
            PostgrestException(code: c.code, message: 'test error'),
          );

          // Act
          final result = await sut.save(protocol);

          // Assert
          expect(result, isLeftWithCode<Unit>(c.expected));
        });
      }

      test('save_whenAuthException_returnsAuthFailure', () async {
        // Arrange
        final protocolResult = ProtocolFactory.create();

        final protocol = protocolResult.getRight().toNullable()!;

        when(() => mockDataSource.saveProtocol(any())).thenThrow(
          AuthException('Not authenticated'),
        );

        // Act
        final result = await sut.save(protocol);

        // Assert
        expect(result, isLeftWithCode<Unit>('Protocol.AuthenticationFailed'));
      });

      test('save_whenUnexpectedError_returnsUnknownFailure', () async {
        // Arrange
        final protocolResult = ProtocolFactory.create();

        final protocol = protocolResult.getRight().toNullable()!;

        when(
          () => mockDataSource.saveProtocol(any()),
        ).thenThrow(Exception('Something went wrong'));

        // Act
        final result = await sut.save(protocol);

        // Assert
        expect(result, isLeftWithCode<Unit>('Protocol.UnexpectedError'));
      });
    });
  });
}
