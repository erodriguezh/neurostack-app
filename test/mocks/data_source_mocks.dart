import 'package:mocktail/mocktail.dart';
import 'package:neurostack/features/protocol/data/data_sources/protocol_remote_data_source.dart';
import 'package:neurostack/features/session/data/data_sources/session_remote_data_source.dart';
import 'package:neurostack/features/user/data/data_sources/user_remote_data_source.dart';

/// Mock data sources for repository testing.
///
/// Per testing documentation: mock at the data source boundary, not Supabase client.

class MockProtocolRemoteDataSource extends Mock
    implements ProtocolRemoteDataSource {}

class MockSessionRemoteDataSource extends Mock
    implements SessionRemoteDataSource {}

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}
