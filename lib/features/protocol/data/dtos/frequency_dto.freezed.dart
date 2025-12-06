// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frequency_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FrequencyDto {

@JsonKey(name: 'min_per_week') int get minPerWeek;@JsonKey(name: 'max_per_week') int get maxPerWeek;
/// Create a copy of FrequencyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrequencyDtoCopyWith<FrequencyDto> get copyWith => _$FrequencyDtoCopyWithImpl<FrequencyDto>(this as FrequencyDto, _$identity);

  /// Serializes this FrequencyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FrequencyDto&&(identical(other.minPerWeek, minPerWeek) || other.minPerWeek == minPerWeek)&&(identical(other.maxPerWeek, maxPerWeek) || other.maxPerWeek == maxPerWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minPerWeek,maxPerWeek);

@override
String toString() {
  return 'FrequencyDto(minPerWeek: $minPerWeek, maxPerWeek: $maxPerWeek)';
}


}

/// @nodoc
abstract mixin class $FrequencyDtoCopyWith<$Res>  {
  factory $FrequencyDtoCopyWith(FrequencyDto value, $Res Function(FrequencyDto) _then) = _$FrequencyDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'min_per_week') int minPerWeek,@JsonKey(name: 'max_per_week') int maxPerWeek
});




}
/// @nodoc
class _$FrequencyDtoCopyWithImpl<$Res>
    implements $FrequencyDtoCopyWith<$Res> {
  _$FrequencyDtoCopyWithImpl(this._self, this._then);

  final FrequencyDto _self;
  final $Res Function(FrequencyDto) _then;

/// Create a copy of FrequencyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minPerWeek = null,Object? maxPerWeek = null,}) {
  return _then(_self.copyWith(
minPerWeek: null == minPerWeek ? _self.minPerWeek : minPerWeek // ignore: cast_nullable_to_non_nullable
as int,maxPerWeek: null == maxPerWeek ? _self.maxPerWeek : maxPerWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FrequencyDto].
extension FrequencyDtoPatterns on FrequencyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FrequencyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FrequencyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FrequencyDto value)  $default,){
final _that = this;
switch (_that) {
case _FrequencyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FrequencyDto value)?  $default,){
final _that = this;
switch (_that) {
case _FrequencyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_per_week')  int minPerWeek, @JsonKey(name: 'max_per_week')  int maxPerWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FrequencyDto() when $default != null:
return $default(_that.minPerWeek,_that.maxPerWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_per_week')  int minPerWeek, @JsonKey(name: 'max_per_week')  int maxPerWeek)  $default,) {final _that = this;
switch (_that) {
case _FrequencyDto():
return $default(_that.minPerWeek,_that.maxPerWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'min_per_week')  int minPerWeek, @JsonKey(name: 'max_per_week')  int maxPerWeek)?  $default,) {final _that = this;
switch (_that) {
case _FrequencyDto() when $default != null:
return $default(_that.minPerWeek,_that.maxPerWeek);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FrequencyDto extends FrequencyDto {
  const _FrequencyDto({@JsonKey(name: 'min_per_week') required this.minPerWeek, @JsonKey(name: 'max_per_week') required this.maxPerWeek}): super._();
  factory _FrequencyDto.fromJson(Map<String, dynamic> json) => _$FrequencyDtoFromJson(json);

@override@JsonKey(name: 'min_per_week') final  int minPerWeek;
@override@JsonKey(name: 'max_per_week') final  int maxPerWeek;

/// Create a copy of FrequencyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrequencyDtoCopyWith<_FrequencyDto> get copyWith => __$FrequencyDtoCopyWithImpl<_FrequencyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FrequencyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FrequencyDto&&(identical(other.minPerWeek, minPerWeek) || other.minPerWeek == minPerWeek)&&(identical(other.maxPerWeek, maxPerWeek) || other.maxPerWeek == maxPerWeek));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minPerWeek,maxPerWeek);

@override
String toString() {
  return 'FrequencyDto(minPerWeek: $minPerWeek, maxPerWeek: $maxPerWeek)';
}


}

/// @nodoc
abstract mixin class _$FrequencyDtoCopyWith<$Res> implements $FrequencyDtoCopyWith<$Res> {
  factory _$FrequencyDtoCopyWith(_FrequencyDto value, $Res Function(_FrequencyDto) _then) = __$FrequencyDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'min_per_week') int minPerWeek,@JsonKey(name: 'max_per_week') int maxPerWeek
});




}
/// @nodoc
class __$FrequencyDtoCopyWithImpl<$Res>
    implements _$FrequencyDtoCopyWith<$Res> {
  __$FrequencyDtoCopyWithImpl(this._self, this._then);

  final _FrequencyDto _self;
  final $Res Function(_FrequencyDto) _then;

/// Create a copy of FrequencyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minPerWeek = null,Object? maxPerWeek = null,}) {
  return _then(_FrequencyDto(
minPerWeek: null == minPerWeek ? _self.minPerWeek : minPerWeek // ignore: cast_nullable_to_non_nullable
as int,maxPerWeek: null == maxPerWeek ? _self.maxPerWeek : maxPerWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
