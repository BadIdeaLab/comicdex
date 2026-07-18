// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_images.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicImages {

 List<ComicPageImage> get pages; ComicPageImage? get cover; ComicPageImage? get thumbnail;
/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicImagesCopyWith<ComicImages> get copyWith => _$ComicImagesCopyWithImpl<ComicImages>(this as ComicImages, _$identity);

  /// Serializes this ComicImages to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicImages&&const DeepCollectionEquality().equals(other.pages, pages)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(pages),cover,thumbnail);

@override
String toString() {
  return 'ComicImages(pages: $pages, cover: $cover, thumbnail: $thumbnail)';
}


}

/// @nodoc
abstract mixin class $ComicImagesCopyWith<$Res>  {
  factory $ComicImagesCopyWith(ComicImages value, $Res Function(ComicImages) _then) = _$ComicImagesCopyWithImpl;
@useResult
$Res call({
 List<ComicPageImage> pages, ComicPageImage? cover, ComicPageImage? thumbnail
});


$ComicPageImageCopyWith<$Res>? get cover;$ComicPageImageCopyWith<$Res>? get thumbnail;

}
/// @nodoc
class _$ComicImagesCopyWithImpl<$Res>
    implements $ComicImagesCopyWith<$Res> {
  _$ComicImagesCopyWithImpl(this._self, this._then);

  final ComicImages _self;
  final $Res Function(ComicImages) _then;

/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? cover = freezed,Object? thumbnail = freezed,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as List<ComicPageImage>,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicPageImage?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as ComicPageImage?,
  ));
}
/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicPageImageCopyWith<$Res>? get cover {
    if (_self.cover == null) {
    return null;
  }

  return $ComicPageImageCopyWith<$Res>(_self.cover!, (value) {
    return _then(_self.copyWith(cover: value));
  });
}/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicPageImageCopyWith<$Res>? get thumbnail {
    if (_self.thumbnail == null) {
    return null;
  }

  return $ComicPageImageCopyWith<$Res>(_self.thumbnail!, (value) {
    return _then(_self.copyWith(thumbnail: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicImages].
extension ComicImagesPatterns on ComicImages {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicImages value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicImages() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicImages value)  $default,){
final _that = this;
switch (_that) {
case _ComicImages():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicImages value)?  $default,){
final _that = this;
switch (_that) {
case _ComicImages() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ComicPageImage> pages,  ComicPageImage? cover,  ComicPageImage? thumbnail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicImages() when $default != null:
return $default(_that.pages,_that.cover,_that.thumbnail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ComicPageImage> pages,  ComicPageImage? cover,  ComicPageImage? thumbnail)  $default,) {final _that = this;
switch (_that) {
case _ComicImages():
return $default(_that.pages,_that.cover,_that.thumbnail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ComicPageImage> pages,  ComicPageImage? cover,  ComicPageImage? thumbnail)?  $default,) {final _that = this;
switch (_that) {
case _ComicImages() when $default != null:
return $default(_that.pages,_that.cover,_that.thumbnail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicImages implements ComicImages {
   _ComicImages({final  List<ComicPageImage> pages = const <ComicPageImage>[], this.cover, this.thumbnail}): _pages = pages;
  factory _ComicImages.fromJson(Map<String, dynamic> json) => _$ComicImagesFromJson(json);

 final  List<ComicPageImage> _pages;
@override@JsonKey() List<ComicPageImage> get pages {
  if (_pages is EqualUnmodifiableListView) return _pages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pages);
}

@override final  ComicPageImage? cover;
@override final  ComicPageImage? thumbnail;

/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicImagesCopyWith<_ComicImages> get copyWith => __$ComicImagesCopyWithImpl<_ComicImages>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicImagesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicImages&&const DeepCollectionEquality().equals(other._pages, _pages)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_pages),cover,thumbnail);

@override
String toString() {
  return 'ComicImages(pages: $pages, cover: $cover, thumbnail: $thumbnail)';
}


}

/// @nodoc
abstract mixin class _$ComicImagesCopyWith<$Res> implements $ComicImagesCopyWith<$Res> {
  factory _$ComicImagesCopyWith(_ComicImages value, $Res Function(_ComicImages) _then) = __$ComicImagesCopyWithImpl;
@override @useResult
$Res call({
 List<ComicPageImage> pages, ComicPageImage? cover, ComicPageImage? thumbnail
});


@override $ComicPageImageCopyWith<$Res>? get cover;@override $ComicPageImageCopyWith<$Res>? get thumbnail;

}
/// @nodoc
class __$ComicImagesCopyWithImpl<$Res>
    implements _$ComicImagesCopyWith<$Res> {
  __$ComicImagesCopyWithImpl(this._self, this._then);

  final _ComicImages _self;
  final $Res Function(_ComicImages) _then;

/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? cover = freezed,Object? thumbnail = freezed,}) {
  return _then(_ComicImages(
pages: null == pages ? _self._pages : pages // ignore: cast_nullable_to_non_nullable
as List<ComicPageImage>,cover: freezed == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicPageImage?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as ComicPageImage?,
  ));
}

/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicPageImageCopyWith<$Res>? get cover {
    if (_self.cover == null) {
    return null;
  }

  return $ComicPageImageCopyWith<$Res>(_self.cover!, (value) {
    return _then(_self.copyWith(cover: value));
  });
}/// Create a copy of ComicImages
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicPageImageCopyWith<$Res>? get thumbnail {
    if (_self.thumbnail == null) {
    return null;
  }

  return $ComicPageImageCopyWith<$Res>(_self.thumbnail!, (value) {
    return _then(_self.copyWith(thumbnail: value));
  });
}
}

// dart format on
