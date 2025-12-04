// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserDto {

 String get id;@JsonKey(name: 'subscription_status') String get subscriptionStatus;@JsonKey(name: 'trial_period') TrialPeriodDto? get trialPeriod;@JsonKey(name: 'protocol_ids') List<String> get protocolIds;@JsonKey(name: 'onboarding_completed') bool get onboardingCompleted;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDtoCopyWith<UserDto> get copyWith => _$UserDtoCopyWithImpl<UserDto>(this as UserDto, _$identity);

  /// Serializes this UserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDto&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.trialPeriod, trialPeriod) || other.trialPeriod == trialPeriod)&&const DeepCollectionEquality().equals(other.protocolIds, protocolIds)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionStatus,trialPeriod,const DeepCollectionEquality().hash(protocolIds),onboardingCompleted,createdAt);

@override
String toString() {
  return 'UserDto(id: $id, subscriptionStatus: $subscriptionStatus, trialPeriod: $trialPeriod, protocolIds: $protocolIds, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserDtoCopyWith<$Res>  {
  factory $UserDtoCopyWith(UserDto value, $Res Function(UserDto) _then) = _$UserDtoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'subscription_status') String subscriptionStatus,@JsonKey(name: 'trial_period') TrialPeriodDto? trialPeriod,@JsonKey(name: 'protocol_ids') List<String> protocolIds,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'created_at') String createdAt
});


$TrialPeriodDtoCopyWith<$Res>? get trialPeriod;

}
/// @nodoc
class _$UserDtoCopyWithImpl<$Res>
    implements $UserDtoCopyWith<$Res> {
  _$UserDtoCopyWithImpl(this._self, this._then);

  final UserDto _self;
  final $Res Function(UserDto) _then;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subscriptionStatus = null,Object? trialPeriod = freezed,Object? protocolIds = null,Object? onboardingCompleted = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as String,trialPeriod: freezed == trialPeriod ? _self.trialPeriod : trialPeriod // ignore: cast_nullable_to_non_nullable
as TrialPeriodDto?,protocolIds: null == protocolIds ? _self.protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrialPeriodDtoCopyWith<$Res>? get trialPeriod {
    if (_self.trialPeriod == null) {
    return null;
  }

  return $TrialPeriodDtoCopyWith<$Res>(_self.trialPeriod!, (value) {
    return _then(_self.copyWith(trialPeriod: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserDto].
extension UserDtoPatterns on UserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDto value)  $default,){
final _that = this;
switch (_that) {
case _UserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'subscription_status')  String subscriptionStatus, @JsonKey(name: 'trial_period')  TrialPeriodDto? trialPeriod, @JsonKey(name: 'protocol_ids')  List<String> protocolIds, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDto() when $default != null:
return $default(_that.id,_that.subscriptionStatus,_that.trialPeriod,_that.protocolIds,_that.onboardingCompleted,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'subscription_status')  String subscriptionStatus, @JsonKey(name: 'trial_period')  TrialPeriodDto? trialPeriod, @JsonKey(name: 'protocol_ids')  List<String> protocolIds, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserDto():
return $default(_that.id,_that.subscriptionStatus,_that.trialPeriod,_that.protocolIds,_that.onboardingCompleted,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'subscription_status')  String subscriptionStatus, @JsonKey(name: 'trial_period')  TrialPeriodDto? trialPeriod, @JsonKey(name: 'protocol_ids')  List<String> protocolIds, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserDto() when $default != null:
return $default(_that.id,_that.subscriptionStatus,_that.trialPeriod,_that.protocolIds,_that.onboardingCompleted,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDto extends UserDto {
  const _UserDto({required this.id, @JsonKey(name: 'subscription_status') required this.subscriptionStatus, @JsonKey(name: 'trial_period') this.trialPeriod, @JsonKey(name: 'protocol_ids') required final  List<String> protocolIds, @JsonKey(name: 'onboarding_completed') required this.onboardingCompleted, @JsonKey(name: 'created_at') required this.createdAt}): _protocolIds = protocolIds,super._();
  factory _UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);

@override final  String id;
@override@JsonKey(name: 'subscription_status') final  String subscriptionStatus;
@override@JsonKey(name: 'trial_period') final  TrialPeriodDto? trialPeriod;
 final  List<String> _protocolIds;
@override@JsonKey(name: 'protocol_ids') List<String> get protocolIds {
  if (_protocolIds is EqualUnmodifiableListView) return _protocolIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_protocolIds);
}

@override@JsonKey(name: 'onboarding_completed') final  bool onboardingCompleted;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDtoCopyWith<_UserDto> get copyWith => __$UserDtoCopyWithImpl<_UserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDto&&(identical(other.id, id) || other.id == id)&&(identical(other.subscriptionStatus, subscriptionStatus) || other.subscriptionStatus == subscriptionStatus)&&(identical(other.trialPeriod, trialPeriod) || other.trialPeriod == trialPeriod)&&const DeepCollectionEquality().equals(other._protocolIds, _protocolIds)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subscriptionStatus,trialPeriod,const DeepCollectionEquality().hash(_protocolIds),onboardingCompleted,createdAt);

@override
String toString() {
  return 'UserDto(id: $id, subscriptionStatus: $subscriptionStatus, trialPeriod: $trialPeriod, protocolIds: $protocolIds, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserDtoCopyWith<$Res> implements $UserDtoCopyWith<$Res> {
  factory _$UserDtoCopyWith(_UserDto value, $Res Function(_UserDto) _then) = __$UserDtoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'subscription_status') String subscriptionStatus,@JsonKey(name: 'trial_period') TrialPeriodDto? trialPeriod,@JsonKey(name: 'protocol_ids') List<String> protocolIds,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'created_at') String createdAt
});


@override $TrialPeriodDtoCopyWith<$Res>? get trialPeriod;

}
/// @nodoc
class __$UserDtoCopyWithImpl<$Res>
    implements _$UserDtoCopyWith<$Res> {
  __$UserDtoCopyWithImpl(this._self, this._then);

  final _UserDto _self;
  final $Res Function(_UserDto) _then;

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subscriptionStatus = null,Object? trialPeriod = freezed,Object? protocolIds = null,Object? onboardingCompleted = null,Object? createdAt = null,}) {
  return _then(_UserDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subscriptionStatus: null == subscriptionStatus ? _self.subscriptionStatus : subscriptionStatus // ignore: cast_nullable_to_non_nullable
as String,trialPeriod: freezed == trialPeriod ? _self.trialPeriod : trialPeriod // ignore: cast_nullable_to_non_nullable
as TrialPeriodDto?,protocolIds: null == protocolIds ? _self._protocolIds : protocolIds // ignore: cast_nullable_to_non_nullable
as List<String>,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of UserDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrialPeriodDtoCopyWith<$Res>? get trialPeriod {
    if (_self.trialPeriod == null) {
    return null;
  }

  return $TrialPeriodDtoCopyWith<$Res>(_self.trialPeriod!, (value) {
    return _then(_self.copyWith(trialPeriod: value));
  });
}
}

// dart format on
