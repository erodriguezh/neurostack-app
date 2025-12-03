// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stack_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StackDto {

 List<String> get protocolIds;
/// Create a copy of StackDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StackDtoCopyWith<StackDto> get copyWith => _$StackDtoCopyWithImpl<StackDto>(this as StackDto, _$identity);

  /// Serializes this StackDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StackDto&&const DeepCollectionEquality().equals(other.protocolIds, protocolIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(protocolIds));

@override
String toString() {
  return 'StackDto(protocolIds: $protocolIds)';
}


}

/// @nodoc
abstract mixin class $StackDtoCopyWith<$Res>  {
  factory $StackDtoCopyWith(StackDto value, $Res Function(StackDto) _then) = _$StackDtoCopyWithImpl;
@useResult
$Res call({
 List<String> protocolIds
});




}
/// @nodoc
class _$StackDtoCopyWithImpl<$Res>
    implements $StackDtoCopyWith<$Res> {
  _$StackDtoCopyWithImpl(this._self, this._then);

  final StackDto _self;
  final $Res Function(StackDto) _then;

/// Create a copy of StackDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolIds = null,}) {
  return _then(_self.copyWith(
protocolIds: null == protocolIds ? _self.protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [StackDto].
extension StackDtoPatterns on StackDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StackDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StackDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StackDto value)  $default,){
final _that = this;
switch (_that) {
case _StackDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StackDto value)?  $default,){
final _that = this;
switch (_that) {
case _StackDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> protocolIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StackDto() when $default != null:
return $default(_that.protocolIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> protocolIds)  $default,) {final _that = this;
switch (_that) {
case _StackDto():
return $default(_that.protocolIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> protocolIds)?  $default,) {final _that = this;
switch (_that) {
case _StackDto() when $default != null:
return $default(_that.protocolIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StackDto extends StackDto {
  const _StackDto({required final  List<String> protocolIds}): _protocolIds = protocolIds,super._();
  factory _StackDto.fromJson(Map<String, dynamic> json) => _$StackDtoFromJson(json);

 final  List<String> _protocolIds;
@override List<String> get protocolIds {
  if (_protocolIds is EqualUnmodifiableListView) return _protocolIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_protocolIds);
}


/// Create a copy of StackDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StackDtoCopyWith<_StackDto> get copyWith => __$StackDtoCopyWithImpl<_StackDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StackDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StackDto&&const DeepCollectionEquality().equals(other._protocolIds, _protocolIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_protocolIds));

@override
String toString() {
  return 'StackDto(protocolIds: $protocolIds)';
}


}

/// @nodoc
abstract mixin class _$StackDtoCopyWith<$Res> implements $StackDtoCopyWith<$Res> {
  factory _$StackDtoCopyWith(_StackDto value, $Res Function(_StackDto) _then) = __$StackDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> protocolIds
});




}
/// @nodoc
class __$StackDtoCopyWithImpl<$Res>
    implements _$StackDtoCopyWith<$Res> {
  __$StackDtoCopyWithImpl(this._self, this._then);

  final _StackDto _self;
  final $Res Function(_StackDto) _then;

/// Create a copy of StackDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolIds = null,}) {
  return _then(_StackDto(
protocolIds: null == protocolIds ? _self._protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
