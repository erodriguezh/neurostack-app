// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionDto {

@JsonKey(fromJson: _requiredStringFromJson) String get id;@JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson) String get protocolId;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'completed_at') String get completedAt;@JsonKey(name: 'duration_seconds') int? get durationSeconds; String? get notes;
/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDtoCopyWith<SessionDto> get copyWith => _$SessionDtoCopyWithImpl<SessionDto>(this as SessionDto, _$identity);

  /// Serializes this SessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,protocolId,userId,completedAt,durationSeconds,notes);

@override
String toString() {
  return 'SessionDto(id: $id, protocolId: $protocolId, userId: $userId, completedAt: $completedAt, durationSeconds: $durationSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $SessionDtoCopyWith<$Res>  {
  factory $SessionDtoCopyWith(SessionDto value, $Res Function(SessionDto) _then) = _$SessionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _requiredStringFromJson) String id,@JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson) String protocolId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? notes
});




}
/// @nodoc
class _$SessionDtoCopyWithImpl<$Res>
    implements $SessionDtoCopyWith<$Res> {
  _$SessionDtoCopyWithImpl(this._self, this._then);

  final SessionDto _self;
  final $Res Function(SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? protocolId = null,Object? userId = null,Object? completedAt = null,Object? durationSeconds = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionDto].
extension SessionDtoPatterns on SessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionDto value)  $default,){
final _that = this;
switch (_that) {
case _SessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _requiredStringFromJson)  String id, @JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson)  String protocolId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.protocolId,_that.userId,_that.completedAt,_that.durationSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _requiredStringFromJson)  String id, @JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson)  String protocolId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _SessionDto():
return $default(_that.id,_that.protocolId,_that.userId,_that.completedAt,_that.durationSeconds,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _requiredStringFromJson)  String id, @JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson)  String protocolId, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'completed_at')  String completedAt, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _SessionDto() when $default != null:
return $default(_that.id,_that.protocolId,_that.userId,_that.completedAt,_that.durationSeconds,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionDto extends SessionDto {
  const _SessionDto({@JsonKey(fromJson: _requiredStringFromJson) required this.id, @JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson) required this.protocolId, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'completed_at') required this.completedAt, @JsonKey(name: 'duration_seconds') this.durationSeconds, this.notes}): super._();
  factory _SessionDto.fromJson(Map<String, dynamic> json) => _$SessionDtoFromJson(json);

@override@JsonKey(fromJson: _requiredStringFromJson) final  String id;
@override@JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson) final  String protocolId;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'completed_at') final  String completedAt;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override final  String? notes;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionDtoCopyWith<_SessionDto> get copyWith => __$SessionDtoCopyWithImpl<_SessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.protocolId, protocolId) || other.protocolId == protocolId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,protocolId,userId,completedAt,durationSeconds,notes);

@override
String toString() {
  return 'SessionDto(id: $id, protocolId: $protocolId, userId: $userId, completedAt: $completedAt, durationSeconds: $durationSeconds, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$SessionDtoCopyWith<$Res> implements $SessionDtoCopyWith<$Res> {
  factory _$SessionDtoCopyWith(_SessionDto value, $Res Function(_SessionDto) _then) = __$SessionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _requiredStringFromJson) String id,@JsonKey(name: 'protocol_id', fromJson: _requiredStringFromJson) String protocolId,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'completed_at') String completedAt,@JsonKey(name: 'duration_seconds') int? durationSeconds, String? notes
});




}
/// @nodoc
class __$SessionDtoCopyWithImpl<$Res>
    implements _$SessionDtoCopyWith<$Res> {
  __$SessionDtoCopyWithImpl(this._self, this._then);

  final _SessionDto _self;
  final $Res Function(_SessionDto) _then;

/// Create a copy of SessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? protocolId = null,Object? userId = null,Object? completedAt = null,Object? durationSeconds = freezed,Object? notes = freezed,}) {
  return _then(_SessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,protocolId: null == protocolId ? _self.protocolId : protocolId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,completedAt: null == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
