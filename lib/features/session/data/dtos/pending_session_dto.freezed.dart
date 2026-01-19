// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingSessionDto {

/// Client-generated UUID for local deduplication.
@JsonKey(name: 'local_id') String get localId;/// User ID for multi-account safety.
@JsonKey(name: 'user_id') String get userId;/// Protocol ID from the embedded SessionDraft.
@JsonKey(name: 'protocol_id') String get protocolId;/// When the session was completed (ISO 8601 string).
@JsonKey(name: 'completed_at') String get completedAt;/// Duration in seconds (from SessionDraft).
@JsonKey(name: 'duration_seconds') int? get durationSeconds;/// Optional notes (from SessionDraft).
 String? get notes;/// When this pending session was created locally (ISO 8601 string).
@JsonKey(name: 'created_at') String get createdAt;/// Number of failed sync attempts.
@JsonKey(name: 'retry_count') int get retryCount;
/// Create a copy of PendingSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingSessionDtoCopyWith<PendingSessionDto> get copyWith => _$PendingSessionDtoCopyWithImpl<PendingSessionDto>(this as PendingSessionDto, _$identity);

  /// Serializes this PendingSessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingSessionDto&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,localId,userId,protocolId,completedAt,durationSeconds,notes,createdAt,retryCount);

@override
String toString() {
  return 'PendingSessionDto(localId: $localId, userId: $userId, protocolId: $protocolId, completedAt: $completedAt, durationSeconds: $durationSeconds, notes: $notes, createdAt: $createdAt, retryCount: $retryCount)';
}


}

/// @nodoc
abstract mixin class $PendingSessionDtoCopyWith<$Res>  {
  factory $PendingSessionDtoCopyWith(PendingSessionDto value, $Res Function(PendingSessionDto) _then) = _$PendingSessionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'local_id') String localId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'protocol_id') String protocolId,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? notes,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'retry_count') int retryCount
});




}
/// @nodoc
class _$PendingSessionDtoCopyWithImpl<$Res>
    implements $PendingSessionDtoCopyWith<$Res> {
  _$PendingSessionDtoCopyWithImpl(this._self, this._then);

  final PendingSessionDto _self;
  final $Res Function(PendingSessionDto) _then;

/// Create a copy of PendingSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? userId = null,Object? protocolId = null,Object? completedAt = null,Object? durationSeconds = freezed,Object? notes = freezed,Object? createdAt = null,Object? retryCount = null,}) {
  return _then(_self.copyWith(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingSessionDto].
extension PendingSessionDtoPatterns on PendingSessionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingSessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingSessionDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingSessionDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingSessionDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingSessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingSessionDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'local_id')  String localId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'retry_count')  int retryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingSessionDto() when $default != null:
return $default(_that.localId,_that.userId,_that.protocolId,_that.completedAt,_that.durationSeconds,_that.notes,_that.createdAt,_that.retryCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'local_id')  String localId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'retry_count')  int retryCount)  $default,) {final _that = this;
switch (_that) {
case _PendingSessionDto():
return $default(_that.localId,_that.userId,_that.protocolId,_that.completedAt,_that.durationSeconds,_that.notes,_that.createdAt,_that.retryCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'local_id')  String localId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'protocol_id')  String protocolId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'retry_count')  int retryCount)?  $default,) {final _that = this;
switch (_that) {
case _PendingSessionDto() when $default != null:
return $default(_that.localId,_that.userId,_that.protocolId,_that.completedAt,_that.durationSeconds,_that.notes,_that.createdAt,_that.retryCount);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _PendingSessionDto extends PendingSessionDto {
  const _PendingSessionDto({@JsonKey(name: 'local_id') required this.localId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'protocol_id') required this.protocolId, @JsonKey(name: 'completed_at') required this.completedAt, @JsonKey(name: 'duration_seconds') this.durationSeconds, this.notes, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'retry_count') required this.retryCount}): super._();
  factory _PendingSessionDto.fromJson(Map<String, dynamic> json) => _$PendingSessionDtoFromJson(json);

/// Client-generated UUID for local deduplication.
@override@JsonKey(name: 'local_id') final  String localId;
/// User ID for multi-account safety.
@override@JsonKey(name: 'user_id') final  String userId;
/// Protocol ID from the embedded SessionDraft.
@override@JsonKey(name: 'protocol_id') final  String protocolId;
/// When the session was completed (ISO 8601 string).
@override@JsonKey(name: 'completed_at') final  String completedAt;
/// Duration in seconds (from SessionDraft).
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
/// Optional notes (from SessionDraft).
@override final  String? notes;
/// When this pending session was created locally (ISO 8601 string).
@override@JsonKey(name: 'created_at') final  String createdAt;
/// Number of failed sync attempts.
@override@JsonKey(name: 'retry_count') final  int retryCount;

/// Create a copy of PendingSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingSessionDtoCopyWith<_PendingSessionDto> get copyWith => __$PendingSessionDtoCopyWithImpl<_PendingSessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingSessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingSessionDto&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,localId,userId,protocolId,completedAt,durationSeconds,notes,createdAt,retryCount);

@override
String toString() {
  return 'PendingSessionDto(localId: $localId, userId: $userId, protocolId: $protocolId, completedAt: $completedAt, durationSeconds: $durationSeconds, notes: $notes, createdAt: $createdAt, retryCount: $retryCount)';
}


}

/// @nodoc
abstract mixin class _$PendingSessionDtoCopyWith<$Res> implements $PendingSessionDtoCopyWith<$Res> {
  factory _$PendingSessionDtoCopyWith(_PendingSessionDto value, $Res Function(_PendingSessionDto) _then) = __$PendingSessionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'local_id') String localId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'protocol_id') String protocolId,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? notes,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'retry_count') int retryCount
});




}
/// @nodoc
class __$PendingSessionDtoCopyWithImpl<$Res>
    implements _$PendingSessionDtoCopyWith<$Res> {
  __$PendingSessionDtoCopyWithImpl(this._self, this._then);

  final _PendingSessionDto _self;
  final $Res Function(_PendingSessionDto) _then;

/// Create a copy of PendingSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? userId = null,Object? protocolId = null,Object? completedAt = null,Object? durationSeconds = freezed,Object? notes = freezed,Object? createdAt = null,Object? retryCount = null,}) {
  return _then(_PendingSessionDto(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
