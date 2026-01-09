# Investigation: Library screen errorMessage cast

## Summary
Investigation in progress. Initial evidence points to `LibraryViewState.copyWith` casting `errorMessage` via `as String?`, which will crash if any call site passes a non-String (e.g., an `int`).

## Symptoms
- Library screen load throws: `type int is not a subtype of type String in type cast`.
- Error references `state.errorMessage`.

## Investigation Log

### 2025-02-15 - Initial scan of library/home state
**Hypothesis:** `LibraryViewState.copyWith` is casting a non-String `errorMessage` provided by a caller.  
**Findings:** `LibraryViewState.copyWith` takes `Object? errorMessage = _unset` and casts with `errorMessage as String?`. Same pattern in `HomeViewState`.  
**Evidence:** `lib/library/library_state.dart:78`, `lib/library/library_state.dart:98`, `lib/home/home_state.dart:82`, `lib/home/home_state.dart:99`.  
**Conclusion:** Confirmed risk point; need to identify call site passing an `int`.

### 2025-02-15 - Call-site scan for `errorMessage`
**Hypothesis:** A call site passes an `int` to `copyWith(errorMessage: ...)`.  
**Findings:** `errorMessage` usage found only in `library_view_model.dart` and `home_view_model.dart`; values are `null` or `String`-typed variables.  
**Evidence:** `lib/library/library_view_model.dart:274`, `lib/library/library_view_model.dart:355`, `lib/library/library_view_model.dart:594`, `lib/library/library_view_model.dart:602`, `lib/home/home_view_model.dart:199`, `lib/home/home_view_model.dart:231`, `lib/home/home_view_model.dart:439`.  
**Conclusion:** No obvious int assignment found; need deeper trace or stack trace to identify caller.

### 2025-02-15 - Library view/model sanity check
**Hypothesis:** Library UI is passing a non-String into `_ErrorState` or building `LibraryViewState` with an int.  
**Findings:** `_ErrorState` takes `String? message`; `LibraryView` only reads `state.errorMessage`. `LibraryViewModel` writes `errorMessage` only with `null` or `String`-typed values.  
**Evidence:** `lib/library/library_view.dart:178`, `lib/library/library_view.dart:407`, `lib/library/library_view_model.dart:265`, `lib/library/library_view_model.dart:588`.  
**Conclusion:** No direct UI or ViewModel path found that assigns an int; suggests external caller or dynamic value flowing into `copyWith`.

### 2025-02-15 - Git history scan
**Hypothesis:** Recent changes to library/home state introduced the cast.  
**Findings:** Recent commits touching library/home state include “library screen 1/2” and “progress screen 1”. No specific evidence of errorMessage change without diff inspection.  
**Evidence:** `git log -- lib/library/library_state.dart lib/home/home_state.dart` (see console output).  
**Conclusion:** History doesn’t isolate the issue without deeper diffing; stack trace is still the fastest path to the offending line.

### 2025-02-15 - Instrumentation added
**Hypothesis:** Logging non-String errorMessage before casting will reveal the caller context.  
**Findings:** Added `Logger.severe` guard in `LibraryViewState.copyWith` and `HomeViewState.copyWith` when `errorMessage` is non-String.  
**Evidence:** `lib/library/library_state.dart:78`, `lib/home/home_state.dart:72`.  
**Conclusion:** Awaiting runtime logs to identify offending call site and value.

### 2025-02-15 - Protocol/Citation DTO vs schema mismatch
**Hypothesis:** Supabase returns integer IDs that are being cast to `String` in DTOs, causing the observed error.  
**Findings:** Schema defines `protocols.id`, `research_citations.id`, `research_citations.protocol_id`, `sessions.id`, and `sessions.protocol_id` as `bigint`. DTOs for Protocol and Session cast these fields using `as String`, which will throw when Supabase returns `int`.  
**Evidence:** `supabase/migrations/20251204192228_initial_schema.sql:12`, `supabase/migrations/20251204192228_initial_schema.sql:38`, `supabase/migrations/20251204192228_initial_schema.sql:60`, `lib/features/protocol/data/dtos/protocol_dto.g.dart:9`, `lib/features/session/data/dtos/session_dto.g.dart:9`.  
**Conclusion:** Highly likely root cause: int IDs from Supabase are cast to String in DTOs during library load (protocol list).

### 2025-02-15 - Protocol citations JSON key mismatch
**Hypothesis:** Protocol JSON includes `research_citations` but DTO expects `citations`.  
**Findings:** Protocol query selects `research_citations(*)`, while `ProtocolDto.fromJson` expects `citations` key and casts it to `List<dynamic>`. This can throw if `citations` is missing/null.  
**Evidence:** `lib/features/protocol/data/data_sources/protocol_remote_data_source.dart:24`, `lib/features/protocol/data/dtos/protocol_dto.g.dart:13`.  
**Conclusion:** Potential secondary parsing failure (null cast to List), though the reported error mentions int-to-String.

### 2025-02-15 - Target JSON key mismatch
**Hypothesis:** Target JSON uses snake_case keys not mapped by DTO.  
**Findings:** Schema uses `duration_seconds` inside `target` JSON, but `TargetDto` expects `durationSeconds` without `@JsonKey`, so `durationSeconds` will always parse as null.  
**Evidence:** `supabase/migrations/20251204192228_initial_schema.sql:25`, `lib/features/protocol/data/dtos/target_dto.dart:19`.  
**Conclusion:** Not likely the int-to-String error, but causes loss of duration data.

### 2025-02-15 - Patch applied (DTO parsing)
**Hypothesis:** Converting numeric IDs to String and aligning citations key fixes the runtime cast error.  
**Findings:** Added `fromJson: _stringFromJson` for protocol/session IDs, mapped citations to `research_citations`, and removed the correct key during upsert. Updated generated `*.g.dart` to match annotations.  
**Evidence:** `lib/features/protocol/data/dtos/protocol_dto.dart:27`, `lib/features/protocol/data/dtos/protocol_dto.g.dart:9`, `lib/features/session/data/dtos/session_dto.dart:20`, `lib/features/session/data/dtos/session_dto.g.dart:9`, `lib/features/protocol/data/data_sources/protocol_remote_data_source.dart:70`.  
**Conclusion:** Fixes the int-to-String cast at protocol/session DTO boundaries; rerun to confirm error resolved.

## Root Cause
Likely: `ProtocolDto.fromJson` (and potentially `SessionDto.fromJson`) casts Supabase integer IDs to `String`, throwing `type 'int' is not a subtype of type 'String' in type cast` during library load.

## Recommendations
1. Normalize Supabase integer IDs to String in DTOs using `fromJson: _stringFromJson`.
2. Align Protocol citations JSON key with Supabase relation (`research_citations`) in DTO and serialization.
3. Consider adding `@JsonKey(name: 'duration_seconds')` to `TargetDto.durationSeconds` if duration is needed.

## Preventive Measures
- Keep DTOs aligned with Supabase schema (IDs and JSON keys), regenerate `*.g.dart` after annotation changes.
