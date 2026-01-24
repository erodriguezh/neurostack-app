// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trial_period_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrialPeriodDto {

@JsonKey(name: 'start_date', fromJson: _stringFromJson) String get startDate;@JsonKey(name: 'end_date', fromJson: _nullableStringFromJson) String? get endDate;
/// Create a copy of TrialPeriodDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrialPeriodDtoCopyWith<TrialPeriodDto> get copyWith => _$TrialPeriodDtoCopyWithImpl<TrialPeriodDto>(this as TrialPeriodDto, _$identity);

  /// Serializes this TrialPeriodDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrialPeriodDto&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TrialPeriodDto(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $TrialPeriodDtoCopyWith<$Res>  {
  factory $TrialPeriodDtoCopyWith(TrialPeriodDto value, $Res Function(TrialPeriodDto) _then) = _$TrialPeriodDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'start_date', fromJson: _stringFromJson) String startDate,@JsonKey(name: 'end_date', fromJson: _nullableStringFromJson) String? endDate
});




}
/// @nodoc
class _$TrialPeriodDtoCopyWithImpl<$Res>
    implements $TrialPeriodDtoCopyWith<$Res> {
  _$TrialPeriodDtoCopyWithImpl(this._self, this._then);

  final TrialPeriodDto _self;
  final $Res Function(TrialPeriodDto) _then;

/// Create a copy of TrialPeriodDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrialPeriodDto].
extension TrialPeriodDtoPatterns on TrialPeriodDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrialPeriodDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrialPeriodDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrialPeriodDto value)  $default,){
final _that = this;
switch (_that) {
case _TrialPeriodDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrialPeriodDto value)?  $default,){
final _that = this;
switch (_that) {
case _TrialPeriodDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'start_date', fromJson: _stringFromJson)  String startDate, @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson)  String? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrialPeriodDto() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'start_date', fromJson: _stringFromJson)  String startDate, @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson)  String? endDate)  $default,) {final _that = this;
switch (_that) {
case _TrialPeriodDto():
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'start_date', fromJson: _stringFromJson)  String startDate, @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson)  String? endDate)?  $default,) {final _that = this;
switch (_that) {
case _TrialPeriodDto() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrialPeriodDto extends TrialPeriodDto {
  const _TrialPeriodDto({@JsonKey(name: 'start_date', fromJson: _stringFromJson) required this.startDate, @JsonKey(name: 'end_date', fromJson: _nullableStringFromJson) this.endDate}): super._();
  factory _TrialPeriodDto.fromJson(Map<String, dynamic> json) => _$TrialPeriodDtoFromJson(json);

@override@JsonKey(name: 'start_date', fromJson: _stringFromJson) final  String startDate;
@override@JsonKey(name: 'end_date', fromJson: _nullableStringFromJson) final  String? endDate;

/// Create a copy of TrialPeriodDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrialPeriodDtoCopyWith<_TrialPeriodDto> get copyWith => __$TrialPeriodDtoCopyWithImpl<_TrialPeriodDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrialPeriodDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrialPeriodDto&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TrialPeriodDto(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$TrialPeriodDtoCopyWith<$Res> implements $TrialPeriodDtoCopyWith<$Res> {
  factory _$TrialPeriodDtoCopyWith(_TrialPeriodDto value, $Res Function(_TrialPeriodDto) _then) = __$TrialPeriodDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'start_date', fromJson: _stringFromJson) String startDate,@JsonKey(name: 'end_date', fromJson: _nullableStringFromJson) String? endDate
});




}
/// @nodoc
class __$TrialPeriodDtoCopyWithImpl<$Res>
    implements _$TrialPeriodDtoCopyWith<$Res> {
  __$TrialPeriodDtoCopyWithImpl(this._self, this._then);

  final _TrialPeriodDto _self;
  final $Res Function(_TrialPeriodDto) _then;

/// Create a copy of TrialPeriodDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_TrialPeriodDto(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
