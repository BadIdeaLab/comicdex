// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_page_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicPageImage {

 String? get t; int? get w; int? get h; String? get path; String? get thumbnailPath;
/// Create a copy of ComicPageImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicPageImageCopyWith<ComicPageImage> get copyWith => _$ComicPageImageCopyWithImpl<ComicPageImage>(this as ComicPageImage, _$identity);

  /// Serializes this ComicPageImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicPageImage&&(identical(other.t, t) || other.t == t)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.path, path) || other.path == path)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,w,h,path,thumbnailPath);

@override
String toString() {
  return 'ComicPageImage(t: $t, w: $w, h: $h, path: $path, thumbnailPath: $thumbnailPath)';
}


}

/// @nodoc
abstract mixin class $ComicPageImageCopyWith<$Res>  {
  factory $ComicPageImageCopyWith(ComicPageImage value, $Res Function(ComicPageImage) _then) = _$ComicPageImageCopyWithImpl;
@useResult
$Res call({
 String? t, int? w, int? h, String? path, String? thumbnailPath
});




}
/// @nodoc
class _$ComicPageImageCopyWithImpl<$Res>
    implements $ComicPageImageCopyWith<$Res> {
  _$ComicPageImageCopyWithImpl(this._self, this._then);

  final ComicPageImage _self;
  final $Res Function(ComicPageImage) _then;

/// Create a copy of ComicPageImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = freezed,Object? w = freezed,Object? h = freezed,Object? path = freezed,Object? thumbnailPath = freezed,}) {
  return _then(_self.copyWith(
t: freezed == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String?,w: freezed == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as int?,h: freezed == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as int?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicPageImage].
extension ComicPageImagePatterns on ComicPageImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicPageImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicPageImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicPageImage value)  $default,){
final _that = this;
switch (_that) {
case _ComicPageImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicPageImage value)?  $default,){
final _that = this;
switch (_that) {
case _ComicPageImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? t,  int? w,  int? h,  String? path,  String? thumbnailPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicPageImage() when $default != null:
return $default(_that.t,_that.w,_that.h,_that.path,_that.thumbnailPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? t,  int? w,  int? h,  String? path,  String? thumbnailPath)  $default,) {final _that = this;
switch (_that) {
case _ComicPageImage():
return $default(_that.t,_that.w,_that.h,_that.path,_that.thumbnailPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? t,  int? w,  int? h,  String? path,  String? thumbnailPath)?  $default,) {final _that = this;
switch (_that) {
case _ComicPageImage() when $default != null:
return $default(_that.t,_that.w,_that.h,_that.path,_that.thumbnailPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicPageImage implements ComicPageImage {
   _ComicPageImage({this.t, this.w, this.h, this.path, this.thumbnailPath});
  factory _ComicPageImage.fromJson(Map<String, dynamic> json) => _$ComicPageImageFromJson(json);

@override final  String? t;
@override final  int? w;
@override final  int? h;
@override final  String? path;
@override final  String? thumbnailPath;

/// Create a copy of ComicPageImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicPageImageCopyWith<_ComicPageImage> get copyWith => __$ComicPageImageCopyWithImpl<_ComicPageImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicPageImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicPageImage&&(identical(other.t, t) || other.t == t)&&(identical(other.w, w) || other.w == w)&&(identical(other.h, h) || other.h == h)&&(identical(other.path, path) || other.path == path)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,w,h,path,thumbnailPath);

@override
String toString() {
  return 'ComicPageImage(t: $t, w: $w, h: $h, path: $path, thumbnailPath: $thumbnailPath)';
}


}

/// @nodoc
abstract mixin class _$ComicPageImageCopyWith<$Res> implements $ComicPageImageCopyWith<$Res> {
  factory _$ComicPageImageCopyWith(_ComicPageImage value, $Res Function(_ComicPageImage) _then) = __$ComicPageImageCopyWithImpl;
@override @useResult
$Res call({
 String? t, int? w, int? h, String? path, String? thumbnailPath
});




}
/// @nodoc
class __$ComicPageImageCopyWithImpl<$Res>
    implements _$ComicPageImageCopyWith<$Res> {
  __$ComicPageImageCopyWithImpl(this._self, this._then);

  final _ComicPageImage _self;
  final $Res Function(_ComicPageImage) _then;

/// Create a copy of ComicPageImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = freezed,Object? w = freezed,Object? h = freezed,Object? path = freezed,Object? thumbnailPath = freezed,}) {
  return _then(_ComicPageImage(
t: freezed == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String?,w: freezed == w ? _self.w : w // ignore: cast_nullable_to_non_nullable
as int?,h: freezed == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as int?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
