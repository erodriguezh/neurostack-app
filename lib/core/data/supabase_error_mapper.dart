import 'package:supabase_flutter/supabase_flutter.dart';
import '../failures/domain_failure.dart';

/// Maps PostgrestException to DomainFailure with aggregate prefix.
/// 
/// Common error codes from Supabase/PostgreSQL documentation:
/// - 23505: Unique violation (duplicate record)
/// - 23503: Foreign key violation (invalid reference)
/// - 42501: Insufficient privilege (permission denied)
/// - PGRST116: Row not found (single query returned no rows)
/// - PGRST301: Connection failed
DomainFailure mapPostgrestError(String aggregate, PostgrestException e) {
  return switch (e.code) {
    '23505' => DomainFailure(
        code: '$aggregate.DuplicateRecord',
        message: 'Record already exists',
      ),
    '23503' => DomainFailure(
        code: '$aggregate.InvalidReference',
        message: 'Referenced record does not exist',
      ),
    '42501' => DomainFailure(
        code: '$aggregate.PermissionDenied',
        message: 'Access denied by security policy',
      ),
    'PGRST116' => DomainFailure(
        code: '$aggregate.NotFound',
        message: 'Record not found',
      ),
    'PGRST301' => DomainFailure(
        code: '$aggregate.ConnectionFailed',
        message: 'Database connection failed',
      ),
    _ => DomainFailure(
        code: '$aggregate.DatabaseError',
        message: '${e.code}: ${e.message}',
      ),
  };
}
