// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'protocol_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProtocolDto {

 String get id; String get name; TargetDto get target; String get category; String get evidenceLevel; List<ResearchCitationDto> get citations; String get createdAt; String? get deletedAt;
/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProtocolDtoCopyWith<ProtocolDto> get copyWith => _$ProtocolDtoCopyWithImpl<ProtocolDto>(this as ProtocolDto, _$identity);

  /// Serializes this ProtocolDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProtocolDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.target, target) || other.target == target)&&(identical(other.category, category) || other.category == category)&&(identical(other.evidenceLevel, evidenceLevel) || other.evidenceLevel == evidenceLevel)&&const DeepCollectionEquality().equals(other.citations, citations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,target,category,evidenceLevel,const DeepCollectionEquality().hash(citations),createdAt,deletedAt);

@override
String toString() {
  return 'ProtocolDto(id: $id, name: $name, target: $target, category: $category, evidenceLevel: $evidenceLevel, citations: $citations, createdAt: $createdAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ProtocolDtoCopyWith<$Res>  {
  factory $ProtocolDtoCopyWith(ProtocolDto value, $Res Function(ProtocolDto) _then) = _$ProtocolDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, TargetDto target, String category, String evidenceLevel, List<ResearchCitationDto> citations, String createdAt, String? deletedAt
});


$TargetDtoCopyWith<$Res> get target;

}
/// @nodoc
class _$ProtocolDtoCopyWithImpl<$Res>
    implements $ProtocolDtoCopyWith<$Res> {
  _$ProtocolDtoCopyWithImpl(this._self, this._then);

  final ProtocolDto _self;
  final $Res Function(ProtocolDto) _then;

/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? target = null,Object? category = null,Object? evidenceLevel = null,Object? citations = null,Object? createdAt = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TargetDto,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,evidenceLevel: null == evidenceLevel ? _self.evidenceLevel : evidenceLevel // ignore: cast_nullable_to_non_nullable
as String,citations: null == citations ? _self.citations : citations // ignore: cast_nullable_to_non_nullable
as List<ResearchCitationDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TargetDtoCopyWith<$Res> get target {
  
  return $TargetDtoCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProtocolDto].
extension ProtocolDtoPatterns on ProtocolDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProtocolDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProtocolDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProtocolDto value)  $default,){
final _that = this;
switch (_that) {
case _ProtocolDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProtocolDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProtocolDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  TargetDto target,  String category,  String evidenceLevel,  List<ResearchCitationDto> citations,  String createdAt,  String? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProtocolDto() when $default != null:
return $default(_that.id,_that.name,_that.target,_that.category,_that.evidenceLevel,_that.citations,_that.createdAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  TargetDto target,  String category,  String evidenceLevel,  List<ResearchCitationDto> citations,  String createdAt,  String? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ProtocolDto():
return $default(_that.id,_that.name,_that.target,_that.category,_that.evidenceLevel,_that.citations,_that.createdAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  TargetDto target,  String category,  String evidenceLevel,  List<ResearchCitationDto> citations,  String createdAt,  String? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProtocolDto() when $default != null:
return $default(_that.id,_that.name,_that.target,_that.category,_that.evidenceLevel,_that.citations,_that.createdAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProtocolDto extends ProtocolDto {
  const _ProtocolDto({required this.id, required this.name, required this.target, required this.category, required this.evidenceLevel, required final  List<ResearchCitationDto> citations, required this.createdAt, this.deletedAt}): _citations = citations,super._();
  factory _ProtocolDto.fromJson(Map<String, dynamic> json) => _$ProtocolDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  TargetDto target;
@override final  String category;
@override final  String evidenceLevel;
 final  List<ResearchCitationDto> _citations;
@override List<ResearchCitationDto> get citations {
  if (_citations is EqualUnmodifiableListView) return _citations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_citations);
}

@override final  String createdAt;
@override final  String? deletedAt;

/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProtocolDtoCopyWith<_ProtocolDto> get copyWith => __$ProtocolDtoCopyWithImpl<_ProtocolDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProtocolDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProtocolDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.target, target) || other.target == target)&&(identical(other.category, category) || other.category == category)&&(identical(other.evidenceLevel, evidenceLevel) || other.evidenceLevel == evidenceLevel)&&const DeepCollectionEquality().equals(other._citations, _citations)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,target,category,evidenceLevel,const DeepCollectionEquality().hash(_citations),createdAt,deletedAt);

@override
String toString() {
  return 'ProtocolDto(id: $id, name: $name, target: $target, category: $category, evidenceLevel: $evidenceLevel, citations: $citations, createdAt: $createdAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ProtocolDtoCopyWith<$Res> implements $ProtocolDtoCopyWith<$Res> {
  factory _$ProtocolDtoCopyWith(_ProtocolDto value, $Res Function(_ProtocolDto) _then) = __$ProtocolDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, TargetDto target, String category, String evidenceLevel, List<ResearchCitationDto> citations, String createdAt, String? deletedAt
});


@override $TargetDtoCopyWith<$Res> get target;

}
/// @nodoc
class __$ProtocolDtoCopyWithImpl<$Res>
    implements _$ProtocolDtoCopyWith<$Res> {
  __$ProtocolDtoCopyWithImpl(this._self, this._then);

  final _ProtocolDto _self;
  final $Res Function(_ProtocolDto) _then;

/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? target = null,Object? category = null,Object? evidenceLevel = null,Object? citations = null,Object? createdAt = null,Object? deletedAt = freezed,}) {
  return _then(_ProtocolDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as TargetDto,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,evidenceLevel: null == evidenceLevel ? _self.evidenceLevel : evidenceLevel // ignore: cast_nullable_to_non_nullable
as String,citations: null == citations ? _self._citations : citations // ignore: cast_nullable_to_non_nullable
as List<ResearchCitationDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProtocolDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TargetDtoCopyWith<$Res> get target {
  
  return $TargetDtoCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

// dart format on
