// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'research_citation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResearchCitationDto {

 String get authors; int get year; String get title; String get journal; String? get doi; String? get url;
/// Create a copy of ResearchCitationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchCitationDtoCopyWith<ResearchCitationDto> get copyWith => _$ResearchCitationDtoCopyWithImpl<ResearchCitationDto>(this as ResearchCitationDto, _$identity);

  /// Serializes this ResearchCitationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchCitationDto&&(identical(other.authors, authors) || other.authors == authors)&&(identical(other.year, year) || other.year == year)&&(identical(other.title, title) || other.title == title)&&(identical(other.journal, journal) || other.journal == journal)&&(identical(other.doi, doi) || other.doi == doi)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authors,year,title,journal,doi,url);

@override
String toString() {
  return 'ResearchCitationDto(authors: $authors, year: $year, title: $title, journal: $journal, doi: $doi, url: $url)';
}


}

/// @nodoc
abstract mixin class $ResearchCitationDtoCopyWith<$Res>  {
  factory $ResearchCitationDtoCopyWith(ResearchCitationDto value, $Res Function(ResearchCitationDto) _then) = _$ResearchCitationDtoCopyWithImpl;
@useResult
$Res call({
 String authors, int year, String title, String journal, String? doi, String? url
});




}
/// @nodoc
class _$ResearchCitationDtoCopyWithImpl<$Res>
    implements $ResearchCitationDtoCopyWith<$Res> {
  _$ResearchCitationDtoCopyWithImpl(this._self, this._then);

  final ResearchCitationDto _self;
  final $Res Function(ResearchCitationDto) _then;

/// Create a copy of ResearchCitationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authors = null,Object? year = null,Object? title = null,Object? journal = null,Object? doi = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,journal: null == journal ? _self.journal : journal // ignore: cast_nullable_to_non_nullable
as String,doi: freezed == doi ? _self.doi : doi // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResearchCitationDto].
extension ResearchCitationDtoPatterns on ResearchCitationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResearchCitationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResearchCitationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResearchCitationDto value)  $default,){
final _that = this;
switch (_that) {
case _ResearchCitationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResearchCitationDto value)?  $default,){
final _that = this;
switch (_that) {
case _ResearchCitationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String authors,  int year,  String title,  String journal,  String? doi,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResearchCitationDto() when $default != null:
return $default(_that.authors,_that.year,_that.title,_that.journal,_that.doi,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String authors,  int year,  String title,  String journal,  String? doi,  String? url)  $default,) {final _that = this;
switch (_that) {
case _ResearchCitationDto():
return $default(_that.authors,_that.year,_that.title,_that.journal,_that.doi,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String authors,  int year,  String title,  String journal,  String? doi,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _ResearchCitationDto() when $default != null:
return $default(_that.authors,_that.year,_that.title,_that.journal,_that.doi,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResearchCitationDto extends ResearchCitationDto {
  const _ResearchCitationDto({required this.authors, required this.year, required this.title, required this.journal, this.doi, this.url}): super._();
  factory _ResearchCitationDto.fromJson(Map<String, dynamic> json) => _$ResearchCitationDtoFromJson(json);

@override final  String authors;
@override final  int year;
@override final  String title;
@override final  String journal;
@override final  String? doi;
@override final  String? url;

/// Create a copy of ResearchCitationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchCitationDtoCopyWith<_ResearchCitationDto> get copyWith => __$ResearchCitationDtoCopyWithImpl<_ResearchCitationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResearchCitationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchCitationDto&&(identical(other.authors, authors) || other.authors == authors)&&(identical(other.year, year) || other.year == year)&&(identical(other.title, title) || other.title == title)&&(identical(other.journal, journal) || other.journal == journal)&&(identical(other.doi, doi) || other.doi == doi)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authors,year,title,journal,doi,url);

@override
String toString() {
  return 'ResearchCitationDto(authors: $authors, year: $year, title: $title, journal: $journal, doi: $doi, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ResearchCitationDtoCopyWith<$Res> implements $ResearchCitationDtoCopyWith<$Res> {
  factory _$ResearchCitationDtoCopyWith(_ResearchCitationDto value, $Res Function(_ResearchCitationDto) _then) = __$ResearchCitationDtoCopyWithImpl;
@override @useResult
$Res call({
 String authors, int year, String title, String journal, String? doi, String? url
});




}
/// @nodoc
class __$ResearchCitationDtoCopyWithImpl<$Res>
    implements _$ResearchCitationDtoCopyWith<$Res> {
  __$ResearchCitationDtoCopyWithImpl(this._self, this._then);

  final _ResearchCitationDto _self;
  final $Res Function(_ResearchCitationDto) _then;

/// Create a copy of ResearchCitationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authors = null,Object? year = null,Object? title = null,Object? journal = null,Object? doi = freezed,Object? url = freezed,}) {
  return _then(_ResearchCitationDto(
authors: null == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as String,year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,journal: null == journal ? _self.journal : journal // ignore: cast_nullable_to_non_nullable
as String,doi: freezed == doi ? _self.doi : doi // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
