// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'target_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TargetDto {

 FrequencyDto get frequency; int? get durationSeconds; String? get intensity;
/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TargetDtoCopyWith<TargetDto> get copyWith => _$TargetDtoCopyWithImpl<TargetDto>(this as TargetDto, _$identity);

  /// Serializes this TargetDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TargetDto&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,durationSeconds,intensity);

@override
String toString() {
  return 'TargetDto(frequency: $frequency, durationSeconds: $durationSeconds, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $TargetDtoCopyWith<$Res>  {
  factory $TargetDtoCopyWith(TargetDto value, $Res Function(TargetDto) _then) = _$TargetDtoCopyWithImpl;
@useResult
$Res call({
 FrequencyDto frequency, int? durationSeconds, String? intensity
});


$FrequencyDtoCopyWith<$Res> get frequency;

}
/// @nodoc
class _$TargetDtoCopyWithImpl<$Res>
    implements $TargetDtoCopyWith<$Res> {
  _$TargetDtoCopyWithImpl(this._self, this._then);

  final TargetDto _self;
  final $Res Function(TargetDto) _then;

/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? durationSeconds = freezed,Object? intensity = freezed,}) {
  return _then(_self.copyWith(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as FrequencyDto,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,intensity: freezed == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrequencyDtoCopyWith<$Res> get frequency {
  
  return $FrequencyDtoCopyWith<$Res>(_self.frequency, (value) {
    return _then(_self.copyWith(frequency: value));
  });
}
}


/// Adds pattern-matching-related methods to [TargetDto].
extension TargetDtoPatterns on TargetDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TargetDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TargetDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TargetDto value)  $default,){
final _that = this;
switch (_that) {
case _TargetDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TargetDto value)?  $default,){
final _that = this;
switch (_that) {
case _TargetDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FrequencyDto frequency,  int? durationSeconds,  String? intensity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TargetDto() when $default != null:
return $default(_that.frequency,_that.durationSeconds,_that.intensity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FrequencyDto frequency,  int? durationSeconds,  String? intensity)  $default,) {final _that = this;
switch (_that) {
case _TargetDto():
return $default(_that.frequency,_that.durationSeconds,_that.intensity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FrequencyDto frequency,  int? durationSeconds,  String? intensity)?  $default,) {final _that = this;
switch (_that) {
case _TargetDto() when $default != null:
return $default(_that.frequency,_that.durationSeconds,_that.intensity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TargetDto extends TargetDto {
  const _TargetDto({required this.frequency, this.durationSeconds, this.intensity}): super._();
  factory _TargetDto.fromJson(Map<String, dynamic> json) => _$TargetDtoFromJson(json);

@override final  FrequencyDto frequency;
@override final  int? durationSeconds;
@override final  String? intensity;

/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TargetDtoCopyWith<_TargetDto> get copyWith => __$TargetDtoCopyWithImpl<_TargetDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TargetDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TargetDto&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,frequency,durationSeconds,intensity);

@override
String toString() {
  return 'TargetDto(frequency: $frequency, durationSeconds: $durationSeconds, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$TargetDtoCopyWith<$Res> implements $TargetDtoCopyWith<$Res> {
  factory _$TargetDtoCopyWith(_TargetDto value, $Res Function(_TargetDto) _then) = __$TargetDtoCopyWithImpl;
@override @useResult
$Res call({
 FrequencyDto frequency, int? durationSeconds, String? intensity
});


@override $FrequencyDtoCopyWith<$Res> get frequency;

}
/// @nodoc
class __$TargetDtoCopyWithImpl<$Res>
    implements _$TargetDtoCopyWith<$Res> {
  __$TargetDtoCopyWithImpl(this._self, this._then);

  final _TargetDto _self;
  final $Res Function(_TargetDto) _then;

/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? durationSeconds = freezed,Object? intensity = freezed,}) {
  return _then(_TargetDto(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as FrequencyDto,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,intensity: freezed == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TargetDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrequencyDtoCopyWith<$Res> get frequency {
  
  return $FrequencyDtoCopyWith<$Res>(_self.frequency, (value) {
    return _then(_self.copyWith(frequency: value));
  });
}
}

// dart format on
