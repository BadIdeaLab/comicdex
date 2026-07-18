// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Comic {

@JsonKey(fromJson: _stringFromDynamic) String get id;@JsonKey(name: 'media_id', fromJson: _stringFromDynamic) String get mediaId; ComicTitle get title; ComicImages get images; String? get scanlator;@JsonKey(name: 'upload_date') int? get uploadDate; List<ComicTag> get tags;@JsonKey(name: 'num_pages') int get numPages;@JsonKey(name: 'num_favorites') int? get numFavorites;
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCopyWith<Comic> get copyWith => _$ComicCopyWithImpl<Comic>(this as Comic, _$identity);

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.images, images) || other.images == images)&&(identical(other.scanlator, scanlator) || other.scanlator == scanlator)&&(identical(other.uploadDate, uploadDate) || other.uploadDate == uploadDate)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&(identical(other.numFavorites, numFavorites) || other.numFavorites == numFavorites));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaId,title,images,scanlator,uploadDate,const DeepCollectionEquality().hash(tags),numPages,numFavorites);

@override
String toString() {
  return 'Comic(id: $id, mediaId: $mediaId, title: $title, images: $images, scanlator: $scanlator, uploadDate: $uploadDate, tags: $tags, numPages: $numPages, numFavorites: $numFavorites)';
}


}

/// @nodoc
abstract mixin class $ComicCopyWith<$Res>  {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) _then) = _$ComicCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _stringFromDynamic) String id,@JsonKey(name: 'media_id', fromJson: _stringFromDynamic) String mediaId, ComicTitle title, ComicImages images, String? scanlator,@JsonKey(name: 'upload_date') int? uploadDate, List<ComicTag> tags,@JsonKey(name: 'num_pages') int numPages,@JsonKey(name: 'num_favorites') int? numFavorites
});


$ComicTitleCopyWith<$Res> get title;$ComicImagesCopyWith<$Res> get images;

}
/// @nodoc
class _$ComicCopyWithImpl<$Res>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._self, this._then);

  final Comic _self;
  final $Res Function(Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mediaId = null,Object? title = null,Object? images = null,Object? scanlator = freezed,Object? uploadDate = freezed,Object? tags = null,Object? numPages = null,Object? numFavorites = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ComicTitle,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as ComicImages,scanlator: freezed == scanlator ? _self.scanlator : scanlator // ignore: cast_nullable_to_non_nullable
as String?,uploadDate: freezed == uploadDate ? _self.uploadDate : uploadDate // ignore: cast_nullable_to_non_nullable
as int?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<ComicTag>,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,numFavorites: freezed == numFavorites ? _self.numFavorites : numFavorites // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicTitleCopyWith<$Res> get title {
  
  return $ComicTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImagesCopyWith<$Res> get images {
  
  return $ComicImagesCopyWith<$Res>(_self.images, (value) {
    return _then(_self.copyWith(images: value));
  });
}
}


/// Adds pattern-matching-related methods to [Comic].
extension ComicPatterns on Comic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comic value)  $default,){
final _that = this;
switch (_that) {
case _Comic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comic value)?  $default,){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _stringFromDynamic)  String id, @JsonKey(name: 'media_id', fromJson: _stringFromDynamic)  String mediaId,  ComicTitle title,  ComicImages images,  String? scanlator, @JsonKey(name: 'upload_date')  int? uploadDate,  List<ComicTag> tags, @JsonKey(name: 'num_pages')  int numPages, @JsonKey(name: 'num_favorites')  int? numFavorites)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.mediaId,_that.title,_that.images,_that.scanlator,_that.uploadDate,_that.tags,_that.numPages,_that.numFavorites);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _stringFromDynamic)  String id, @JsonKey(name: 'media_id', fromJson: _stringFromDynamic)  String mediaId,  ComicTitle title,  ComicImages images,  String? scanlator, @JsonKey(name: 'upload_date')  int? uploadDate,  List<ComicTag> tags, @JsonKey(name: 'num_pages')  int numPages, @JsonKey(name: 'num_favorites')  int? numFavorites)  $default,) {final _that = this;
switch (_that) {
case _Comic():
return $default(_that.id,_that.mediaId,_that.title,_that.images,_that.scanlator,_that.uploadDate,_that.tags,_that.numPages,_that.numFavorites);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _stringFromDynamic)  String id, @JsonKey(name: 'media_id', fromJson: _stringFromDynamic)  String mediaId,  ComicTitle title,  ComicImages images,  String? scanlator, @JsonKey(name: 'upload_date')  int? uploadDate,  List<ComicTag> tags, @JsonKey(name: 'num_pages')  int numPages, @JsonKey(name: 'num_favorites')  int? numFavorites)?  $default,) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.mediaId,_that.title,_that.images,_that.scanlator,_that.uploadDate,_that.tags,_that.numPages,_that.numFavorites);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comic implements Comic {
   _Comic({@JsonKey(fromJson: _stringFromDynamic) required this.id, @JsonKey(name: 'media_id', fromJson: _stringFromDynamic) required this.mediaId, required this.title, required this.images, this.scanlator, @JsonKey(name: 'upload_date') this.uploadDate, final  List<ComicTag> tags = const <ComicTag>[], @JsonKey(name: 'num_pages') required this.numPages, @JsonKey(name: 'num_favorites') this.numFavorites}): _tags = tags;
  factory _Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

@override@JsonKey(fromJson: _stringFromDynamic) final  String id;
@override@JsonKey(name: 'media_id', fromJson: _stringFromDynamic) final  String mediaId;
@override final  ComicTitle title;
@override final  ComicImages images;
@override final  String? scanlator;
@override@JsonKey(name: 'upload_date') final  int? uploadDate;
 final  List<ComicTag> _tags;
@override@JsonKey() List<ComicTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'num_pages') final  int numPages;
@override@JsonKey(name: 'num_favorites') final  int? numFavorites;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicCopyWith<_Comic> get copyWith => __$ComicCopyWithImpl<_Comic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.mediaId, mediaId) || other.mediaId == mediaId)&&(identical(other.title, title) || other.title == title)&&(identical(other.images, images) || other.images == images)&&(identical(other.scanlator, scanlator) || other.scanlator == scanlator)&&(identical(other.uploadDate, uploadDate) || other.uploadDate == uploadDate)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&(identical(other.numFavorites, numFavorites) || other.numFavorites == numFavorites));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,mediaId,title,images,scanlator,uploadDate,const DeepCollectionEquality().hash(_tags),numPages,numFavorites);

@override
String toString() {
  return 'Comic(id: $id, mediaId: $mediaId, title: $title, images: $images, scanlator: $scanlator, uploadDate: $uploadDate, tags: $tags, numPages: $numPages, numFavorites: $numFavorites)';
}


}

/// @nodoc
abstract mixin class _$ComicCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$ComicCopyWith(_Comic value, $Res Function(_Comic) _then) = __$ComicCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _stringFromDynamic) String id,@JsonKey(name: 'media_id', fromJson: _stringFromDynamic) String mediaId, ComicTitle title, ComicImages images, String? scanlator,@JsonKey(name: 'upload_date') int? uploadDate, List<ComicTag> tags,@JsonKey(name: 'num_pages') int numPages,@JsonKey(name: 'num_favorites') int? numFavorites
});


@override $ComicTitleCopyWith<$Res> get title;@override $ComicImagesCopyWith<$Res> get images;

}
/// @nodoc
class __$ComicCopyWithImpl<$Res>
    implements _$ComicCopyWith<$Res> {
  __$ComicCopyWithImpl(this._self, this._then);

  final _Comic _self;
  final $Res Function(_Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mediaId = null,Object? title = null,Object? images = null,Object? scanlator = freezed,Object? uploadDate = freezed,Object? tags = null,Object? numPages = null,Object? numFavorites = freezed,}) {
  return _then(_Comic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mediaId: null == mediaId ? _self.mediaId : mediaId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as ComicTitle,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as ComicImages,scanlator: freezed == scanlator ? _self.scanlator : scanlator // ignore: cast_nullable_to_non_nullable
as String?,uploadDate: freezed == uploadDate ? _self.uploadDate : uploadDate // ignore: cast_nullable_to_non_nullable
as int?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<ComicTag>,numPages: null == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int,numFavorites: freezed == numFavorites ? _self.numFavorites : numFavorites // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicTitleCopyWith<$Res> get title {
  
  return $ComicTitleCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImagesCopyWith<$Res> get images {
  
  return $ComicImagesCopyWith<$Res>(_self.images, (value) {
    return _then(_self.copyWith(images: value));
  });
}
}

// dart format on
