// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frequency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Frequency {

 int get minPerWeek; int get maxPerWeek;
/// Create a copy of Frequency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FrequencyCopyWith<Frequency> get copyWith => _$FrequencyCopyWithImpl<Frequency>(this as Frequency, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Frequency&&(identical(other.minPerWeek, minPerWeek) || other.minPerWeek == minPerWeek)&&(identical(other.maxPerWeek, maxPerWeek) || other.maxPerWeek == maxPerWeek));
}


@override
int get hashCode => Object.hash(runtimeType,minPerWeek,maxPerWeek);

@override
String toString() {
  return 'Frequency(minPerWeek: $minPerWeek, maxPerWeek: $maxPerWeek)';
}


}

/// @nodoc
abstract mixin class $FrequencyCopyWith<$Res>  {
  factory $FrequencyCopyWith(Frequency value, $Res Function(Frequency) _then) = _$FrequencyCopyWithImpl;
@useResult
$Res call({
 int minPerWeek, int maxPerWeek
});




}
/// @nodoc
class _$FrequencyCopyWithImpl<$Res>
    implements $FrequencyCopyWith<$Res> {
  _$FrequencyCopyWithImpl(this._self, this._then);

  final Frequency _self;
  final $Res Function(Frequency) _then;

/// Create a copy of Frequency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minPerWeek = null,Object? maxPerWeek = null,}) {
  return _then(_self.copyWith(
minPerWeek: null == minPerWeek ? _self.minPerWeek : minPerWeek // ignore: cast_nullable_to_non_nullable
as int,maxPerWeek: null == maxPerWeek ? _self.maxPerWeek : maxPerWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc


class _Frequency extends Frequency {
  const _Frequency({required this.minPerWeek, required this.maxPerWeek}): super._();
  

@override final  int minPerWeek;
@override final  int maxPerWeek;

/// Create a copy of Frequency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FrequencyCopyWith<_Frequency> get copyWith => __$FrequencyCopyWithImpl<_Frequency>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Frequency&&(identical(other.minPerWeek, minPerWeek) || other.minPerWeek == minPerWeek)&&(identical(other.maxPerWeek, maxPerWeek) || other.maxPerWeek == maxPerWeek));
}


@override
int get hashCode => Object.hash(runtimeType,minPerWeek,maxPerWeek);

@override
String toString() {
  return 'Frequency._internal(minPerWeek: $minPerWeek, maxPerWeek: $maxPerWeek)';
}


}

/// @nodoc
abstract mixin class _$FrequencyCopyWith<$Res> implements $FrequencyCopyWith<$Res> {
  factory _$FrequencyCopyWith(_Frequency value, $Res Function(_Frequency) _then) = __$FrequencyCopyWithImpl;
@override @useResult
$Res call({
 int minPerWeek, int maxPerWeek
});




}
/// @nodoc
class __$FrequencyCopyWithImpl<$Res>
    implements _$FrequencyCopyWith<$Res> {
  __$FrequencyCopyWithImpl(this._self, this._then);

  final _Frequency _self;
  final $Res Function(_Frequency) _then;

/// Create a copy of Frequency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minPerWeek = null,Object? maxPerWeek = null,}) {
  return _then(_Frequency(
minPerWeek: null == minPerWeek ? _self.minPerWeek : minPerWeek // ignore: cast_nullable_to_non_nullable
as int,maxPerWeek: null == maxPerWeek ? _self.maxPerWeek : maxPerWeek // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
