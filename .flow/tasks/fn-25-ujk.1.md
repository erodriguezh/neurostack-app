# fn-25-ujk.1 Update UserDto: add trialEndsAt denormalized field

## Description
Phase 6.5 of the Trial Expiration Cronjob feature. The backend migration (6.1) added a `trial_ends_at` column to the users table. This column is a **denormalized query index** for SQL queries (cron, analytics), while `trial_period` JSONB remains the source of truth per INV-B6.

## File to Modify
`lib/features/user/data/dtos/user_dto.dart`

## Changes Required

### 1. Add `trialEndsAt` field
```dart
@JsonKey(name: 'trial_ends_at', fromJson: _nullableDateTimeFromJson)
DateTime? trialEndsAt, // For SQL queries only, not used in toDomain()
```
- Place near `trialPeriod` field (around line 37)

### 2. Add helper function
```dart
DateTime? _nullableDateTimeFromJson(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
```

### 3. Update `fromDomain()` to write to both fields
```dart
trialEndsAt: user.trialPeriod?.endDate,
```

### 4. `toDomain()` does NOT need changes
- It already reads only from `trialPeriod` (source of truth)
- `trialEndsAt` is intentionally ignored in `toDomain()` - it's only for SQL queries

## Design Note
`trial_ends_at` column exists for efficient SQL queries (cron job to expire trials, analytics).
`trialPeriod` JSONB remains the source of truth per **INV-B6** (historical data preserved).

## Acceptance
- [ ] `trialEndsAt` field added to UserDto with proper JSON annotation
- [ ] Helper function `_nullableDateTimeFromJson` added
- [ ] `fromDomain()` writes `trialEndsAt` from `user.trialPeriod?.endDate`
- [ ] `toDomain()` unchanged (ignores `trialEndsAt`)
- [ ] Codegen runs successfully
- [ ] `flutter analyze` passes
- [ ] Tests pass

## Done summary
Added trialEndsAt denormalized field to UserDto for efficient SQL queries (cron job for trial expiration). The field maps to trial_ends_at column and is populated from trialPeriod.endDate in fromDomain(), while toDomain() ignores it since trialPeriod JSONB remains the source of truth per INV-B6.
## Evidence
- Commits: 475f4b069be6cc988ffe22dd2c134c8e6e2eb359
- Tests: flutter test, flutter analyze, dart run build_runner build
- PRs: