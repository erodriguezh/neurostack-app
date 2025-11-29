// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Target {

 Frequency get frequency; Duration? get duration; String? get intensity;
/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TargetCopyWith<Target> get copyWith => _$TargetCopyWithImpl<Target>(this as Target, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Target&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,frequency,duration,intensity);

@override
String toString() {
  return 'Target(frequency: $frequency, duration: $duration, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class $TargetCopyWith<$Res>  {
  factory $TargetCopyWith(Target value, $Res Function(Target) _then) = _$TargetCopyWithImpl;
@useResult
$Res call({
 Frequency frequency, Duration? duration, String? intensity
});


$FrequencyCopyWith<$Res> get frequency;

}
/// @nodoc
class _$TargetCopyWithImpl<$Res>
    implements $TargetCopyWith<$Res> {
  _$TargetCopyWithImpl(this._self, this._then);

  final Target _self;
  final $Res Function(Target) _then;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? duration = freezed,Object? intensity = freezed,}) {
  return _then(_self.copyWith(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,intensity: freezed == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrequencyCopyWith<$Res> get frequency {
  
  return $FrequencyCopyWith<$Res>(_self.frequency, (value) {
    return _then(_self.copyWith(frequency: value));
  });
}
}



/// @nodoc


class _Target extends Target {
  const _Target({required this.frequency, this.duration, this.intensity}): super._();
  

@override final  Frequency frequency;
@override final  Duration? duration;
@override final  String? intensity;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TargetCopyWith<_Target> get copyWith => __$TargetCopyWithImpl<_Target>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Target&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.intensity, intensity) || other.intensity == intensity));
}


@override
int get hashCode => Object.hash(runtimeType,frequency,duration,intensity);

@override
String toString() {
  return 'Target._internal(frequency: $frequency, duration: $duration, intensity: $intensity)';
}


}

/// @nodoc
abstract mixin class _$TargetCopyWith<$Res> implements $TargetCopyWith<$Res> {
  factory _$TargetCopyWith(_Target value, $Res Function(_Target) _then) = __$TargetCopyWithImpl;
@override @useResult
$Res call({
 Frequency frequency, Duration? duration, String? intensity
});


@override $FrequencyCopyWith<$Res> get frequency;

}
/// @nodoc
class __$TargetCopyWithImpl<$Res>
    implements _$TargetCopyWith<$Res> {
  __$TargetCopyWithImpl(this._self, this._then);

  final _Target _self;
  final $Res Function(_Target) _then;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? duration = freezed,Object? intensity = freezed,}) {
  return _then(_Target(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as Frequency,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration?,intensity: freezed == intensity ? _self.intensity : intensity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FrequencyCopyWith<$Res> get frequency {
  
  return $FrequencyCopyWith<$Res>(_self.frequency, (value) {
    return _then(_self.copyWith(frequency: value));
  });
}
}

// dart format on
