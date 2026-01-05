import 'package:mocktail/mocktail.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDataSourceAbstraction extends Mock implements DataSourceAbstraction {}

class MockGoTrueClient extends Mock implements GoTrueClient {}
