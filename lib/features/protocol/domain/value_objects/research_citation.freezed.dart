// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'research_citation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResearchCitation {

 String get authors; int get year; String get title; String get journal; String? get doi; String? get url;
/// Create a copy of ResearchCitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResearchCitationCopyWith<ResearchCitation> get copyWith => _$ResearchCitationCopyWithImpl<ResearchCitation>(this as ResearchCitation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResearchCitation&&(identical(other.authors, authors) || other.authors == authors)&&(identical(other.year, year) || other.year == year)&&(identical(other.title, title) || other.title == title)&&(identical(other.journal, journal) || other.journal == journal)&&(identical(other.doi, doi) || other.doi == doi)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,authors,year,title,journal,doi,url);

@override
String toString() {
  return 'ResearchCitation(authors: $authors, year: $year, title: $title, journal: $journal, doi: $doi, url: $url)';
}


}

/// @nodoc
abstract mixin class $ResearchCitationCopyWith<$Res>  {
  factory $ResearchCitationCopyWith(ResearchCitation value, $Res Function(ResearchCitation) _then) = _$ResearchCitationCopyWithImpl;
@useResult
$Res call({
 String authors, int year, String title, String journal, String? doi, String? url
});




}
/// @nodoc
class _$ResearchCitationCopyWithImpl<$Res>
    implements $ResearchCitationCopyWith<$Res> {
  _$ResearchCitationCopyWithImpl(this._self, this._then);

  final ResearchCitation _self;
  final $Res Function(ResearchCitation) _then;

/// Create a copy of ResearchCitation
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



/// @nodoc


class _ResearchCitation extends ResearchCitation {
  const _ResearchCitation({required this.authors, required this.year, required this.title, required this.journal, this.doi, this.url}): super._();
  

@override final  String authors;
@override final  int year;
@override final  String title;
@override final  String journal;
@override final  String? doi;
@override final  String? url;

/// Create a copy of ResearchCitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResearchCitationCopyWith<_ResearchCitation> get copyWith => __$ResearchCitationCopyWithImpl<_ResearchCitation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResearchCitation&&(identical(other.authors, authors) || other.authors == authors)&&(identical(other.year, year) || other.year == year)&&(identical(other.title, title) || other.title == title)&&(identical(other.journal, journal) || other.journal == journal)&&(identical(other.doi, doi) || other.doi == doi)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,authors,year,title,journal,doi,url);

@override
String toString() {
  return 'ResearchCitation._internal(authors: $authors, year: $year, title: $title, journal: $journal, doi: $doi, url: $url)';
}


}

/// @nodoc
abstract mixin class _$ResearchCitationCopyWith<$Res> implements $ResearchCitationCopyWith<$Res> {
  factory _$ResearchCitationCopyWith(_ResearchCitation value, $Res Function(_ResearchCitation) _then) = __$ResearchCitationCopyWithImpl;
@override @useResult
$Res call({
 String authors, int year, String title, String journal, String? doi, String? url
});




}
/// @nodoc
class __$ResearchCitationCopyWithImpl<$Res>
    implements _$ResearchCitationCopyWith<$Res> {
  __$ResearchCitationCopyWithImpl(this._self, this._then);

  final _ResearchCitation _self;
  final $Res Function(_ResearchCitation) _then;

/// Create a copy of ResearchCitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authors = null,Object? year = null,Object? title = null,Object? journal = null,Object? doi = freezed,Object? url = freezed,}) {
  return _then(_ResearchCitation(
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
