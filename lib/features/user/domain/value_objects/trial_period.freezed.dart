// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trial_period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrialPeriod {

 DateTime get startDate; DateTime get endDate;
/// Create a copy of TrialPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrialPeriodCopyWith<TrialPeriod> get copyWith => _$TrialPeriodCopyWithImpl<TrialPeriod>(this as TrialPeriod, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrialPeriod&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TrialPeriod(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $TrialPeriodCopyWith<$Res>  {
  factory $TrialPeriodCopyWith(TrialPeriod value, $Res Function(TrialPeriod) _then) = _$TrialPeriodCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate
});




}
/// @nodoc
class _$TrialPeriodCopyWithImpl<$Res>
    implements $TrialPeriodCopyWith<$Res> {
  _$TrialPeriodCopyWithImpl(this._self, this._then);

  final TrialPeriod _self;
  final $Res Function(TrialPeriod) _then;

/// Create a copy of TrialPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TrialPeriod].
extension TrialPeriodPatterns on TrialPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrialPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrialPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrialPeriod value)  $default,){
final _that = this;
switch (_that) {
case _TrialPeriod():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrialPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _TrialPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrialPeriod() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate)  $default,) {final _that = this;
switch (_that) {
case _TrialPeriod():
return $default(_that.startDate,_that.endDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startDate,  DateTime endDate)?  $default,) {final _that = this;
switch (_that) {
case _TrialPeriod() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc

@internal
class _TrialPeriod extends TrialPeriod {
  const _TrialPeriod({required this.startDate, required this.endDate}): super._();
  

@override final  DateTime startDate;
@override final  DateTime endDate;

/// Create a copy of TrialPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrialPeriodCopyWith<_TrialPeriod> get copyWith => __$TrialPeriodCopyWithImpl<_TrialPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrialPeriod&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'TrialPeriod(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$TrialPeriodCopyWith<$Res> implements $TrialPeriodCopyWith<$Res> {
  factory _$TrialPeriodCopyWith(_TrialPeriod value, $Res Function(_TrialPeriod) _then) = __$TrialPeriodCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, DateTime endDate
});




}
/// @nodoc
class __$TrialPeriodCopyWithImpl<$Res>
    implements _$TrialPeriodCopyWith<$Res> {
  __$TrialPeriodCopyWithImpl(this._self, this._then);

  final _TrialPeriod _self;
  final $Res Function(_TrialPeriod) _then;

/// Create a copy of TrialPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,}) {
  return _then(_TrialPeriod(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
