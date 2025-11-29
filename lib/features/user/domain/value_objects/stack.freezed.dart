// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Stack {

 List<String> get protocolIds;
/// Create a copy of Stack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StackCopyWith<Stack> get copyWith => _$StackCopyWithImpl<Stack>(this as Stack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Stack&&const DeepCollectionEquality().equals(other.protocolIds, protocolIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(protocolIds));

@override
String toString() {
  return 'Stack(protocolIds: $protocolIds)';
}


}

/// @nodoc
abstract mixin class $StackCopyWith<$Res>  {
  factory $StackCopyWith(Stack value, $Res Function(Stack) _then) = _$StackCopyWithImpl;
@useResult
$Res call({
 List<String> protocolIds
});




}
/// @nodoc
class _$StackCopyWithImpl<$Res>
    implements $StackCopyWith<$Res> {
  _$StackCopyWithImpl(this._self, this._then);

  final Stack _self;
  final $Res Function(Stack) _then;

/// Create a copy of Stack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolIds = null,}) {
  return _then(_self.copyWith(
protocolIds: null == protocolIds ? _self.protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Stack].
extension StackPatterns on Stack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Stack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Stack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Stack value)  $default,){
final _that = this;
switch (_that) {
case _Stack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Stack value)?  $default,){
final _that = this;
switch (_that) {
case _Stack() when $default != null:
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
case _Stack() when $default != null:
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
case _Stack():
return $default(_that.protocolIds);}
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
case _Stack() when $default != null:
return $default(_that.protocolIds);case _:
  return null;

}
}

}

/// @nodoc

@internal
class _Stack extends Stack {
  const _Stack({required final  List<String> protocolIds}): _protocolIds = protocolIds,super._();
  

 final  List<String> _protocolIds;
@override List<String> get protocolIds {
  if (_protocolIds is EqualUnmodifiableListView) return _protocolIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_protocolIds);
}


/// Create a copy of Stack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StackCopyWith<_Stack> get copyWith => __$StackCopyWithImpl<_Stack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Stack&&const DeepCollectionEquality().equals(other._protocolIds, _protocolIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_protocolIds));

@override
String toString() {
  return 'Stack(protocolIds: $protocolIds)';
}


}

/// @nodoc
abstract mixin class _$StackCopyWith<$Res> implements $StackCopyWith<$Res> {
  factory _$StackCopyWith(_Stack value, $Res Function(_Stack) _then) = __$StackCopyWithImpl;
@override @useResult
$Res call({
 List<String> protocolIds
});




}
/// @nodoc
class __$StackCopyWithImpl<$Res>
    implements _$StackCopyWith<$Res> {
  __$StackCopyWithImpl(this._self, this._then);

  final _Stack _self;
  final $Res Function(_Stack) _then;

/// Create a copy of Stack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolIds = null,}) {
  return _then(_Stack(
protocolIds: null == protocolIds ? _self._protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
