// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stored_comic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoredComic {

 String get id;@JsonKey(name: 'mid') String get mediaId; String get title;@JsonKey(name: 'images') String get serializedImages;@JsonKey(name: 'pages') int get pages;
/// Create a copy of StoredComic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoredComicCopyWith<StoredComic> get copyWith => _$StoredComicCopyWithImpl<StoredComic>(this as StoredComic, _$identity);

  /// Serializes this StoredComic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoredComic&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.serializedImages, serializedImages) || other.serializedImages == serializedImages)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaId,title,serializedImages,pages);

@override
String toString() {
  return 'StoredComic(id: $id, mediaId: $mediaId, title: $title, serializedImages: $serializedImages, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $StoredComicCopyWith<$Res>  {
  factory $StoredComicCopyWith(StoredComic value, $Res Function(StoredComic) _then) = _$StoredComicCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'mid') String mediaId, String title,@JsonKey(name: 'images') String serializedImages,@JsonKey(name: 'pages') int pages
});




}
/// @nodoc
class _$StoredComicCopyWithImpl<$Res>
    implements $StoredComicCopyWith<$Res> {
  _$StoredComicCopyWithImpl(this._self, this._then);

  final StoredComic _self;
  final $Res Function(StoredComic) _then;

/// Create a copy of StoredComic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaId = null,Object? title = null,Object? serializedImages = null,Object? pages = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,serializedImages: null == serializedImages ? _self.serializedImages : serializedImages // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StoredComic].
extension StoredComicPatterns on StoredComic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoredComic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoredComic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoredComic value)  $default,){
final _that = this;
switch (_that) {
case _StoredComic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoredComic value)?  $default,){
final _that = this;
switch (_that) {
case _StoredComic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'mid')  String mediaId,  String title, @JsonKey(name: 'images')  String serializedImages, @JsonKey(name: 'pages')  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoredComic() when $default != null:
return $default(_that.id,_that.mediaId,_that.title,_that.serializedImages,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'mid')  String mediaId,  String title, @JsonKey(name: 'images')  String serializedImages, @JsonKey(name: 'pages')  int pages)  $default,) {final _that = this;
switch (_that) {
case _StoredComic():
return $default(_that.id,_that.mediaId,_that.title,_that.serializedImages,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'mid')  String mediaId,  String title, @JsonKey(name: 'images')  String serializedImages, @JsonKey(name: 'pages')  int pages)?  $default,) {final _that = this;
switch (_that) {
case _StoredComic() when $default != null:
return $default(_that.id,_that.mediaId,_that.title,_that.serializedImages,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoredComic implements StoredComic {
   _StoredComic({required this.id, @JsonKey(name: 'mid') required this.mediaId, required this.title, @JsonKey(name: 'images') required this.serializedImages, @JsonKey(name: 'pages') required this.pages});
  factory _StoredComic.fromJson(Map<String, dynamic> json) => _$StoredComicFromJson(json);

@override final  String id;
@override@JsonKey(name: 'mid') final  String mediaId;
@override final  String title;
@override@JsonKey(name: 'images') final  String serializedImages;
@override@JsonKey(name: 'pages') final  int pages;

/// Create a copy of StoredComic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoredComicCopyWith<_StoredComic> get copyWith => __$StoredComicCopyWithImpl<_StoredComic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoredComicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoredComic&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.serializedImages, serializedImages) || other.serializedImages == serializedImages)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaId,title,serializedImages,pages);

@override
String toString() {
  return 'StoredComic(id: $id, mediaId: $mediaId, title: $title, serializedImages: $serializedImages, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$StoredComicCopyWith<$Res> implements $StoredComicCopyWith<$Res> {
  factory _$StoredComicCopyWith(_StoredComic value, $Res Function(_StoredComic) _then) = __$StoredComicCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'mid') String mediaId, String title,@JsonKey(name: 'images') String serializedImages,@JsonKey(name: 'pages') int pages
});




}
/// @nodoc
class __$StoredComicCopyWithImpl<$Res>
    implements _$StoredComicCopyWith<$Res> {
  __$StoredComicCopyWithImpl(this._self, this._then);

  final _StoredComic _self;
  final $Res Function(_StoredComic) _then;

/// Create a copy of StoredComic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaId = null,Object? title = null,Object? serializedImages = null,Object? pages = null,}) {
  return _then(_StoredComic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,serializedImages: null == serializedImages ? _self.serializedImages : serializedImages // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
