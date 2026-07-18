// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collected_comic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectedComic {

 String get collectionName; String get comicId; DateTime get dateCreated; StoredComic get comic;
/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectedComicCopyWith<CollectedComic> get copyWith => _$CollectedComicCopyWithImpl<CollectedComic>(this as CollectedComic, _$identity);

  /// Serializes this CollectedComic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectedComic&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.dateCreated, dateCreated) || other.dateCreated == dateCreated)&&(identical(other.comic, comic) || other.comic == comic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionName,comicId,dateCreated,comic);

@override
String toString() {
  return 'CollectedComic(collectionName: $collectionName, comicId: $comicId, dateCreated: $dateCreated, comic: $comic)';
}


}

/// @nodoc
abstract mixin class $CollectedComicCopyWith<$Res>  {
  factory $CollectedComicCopyWith(CollectedComic value, $Res Function(CollectedComic) _then) = _$CollectedComicCopyWithImpl;
@useResult
$Res call({
 String collectionName, String comicId, DateTime dateCreated, StoredComic comic
});


$StoredComicCopyWith<$Res> get comic;

}
/// @nodoc
class _$CollectedComicCopyWithImpl<$Res>
    implements $CollectedComicCopyWith<$Res> {
  _$CollectedComicCopyWithImpl(this._self, this._then);

  final CollectedComic _self;
  final $Res Function(CollectedComic) _then;

/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? collectionName = null,Object? comicId = null,Object? dateCreated = null,Object? comic = null,}) {
  return _then(_self.copyWith(
collectionName: null == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,dateCreated: null == dateCreated ? _self.dateCreated : dateCreated // ignore: cast_nullable_to_non_nullable
as DateTime,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as StoredComic,
  ));
}
/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoredComicCopyWith<$Res> get comic {
  
  return $StoredComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}
}


/// Adds pattern-matching-related methods to [CollectedComic].
extension CollectedComicPatterns on CollectedComic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectedComic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectedComic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectedComic value)  $default,){
final _that = this;
switch (_that) {
case _CollectedComic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectedComic value)?  $default,){
final _that = this;
switch (_that) {
case _CollectedComic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String collectionName,  String comicId,  DateTime dateCreated,  StoredComic comic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectedComic() when $default != null:
return $default(_that.collectionName,_that.comicId,_that.dateCreated,_that.comic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String collectionName,  String comicId,  DateTime dateCreated,  StoredComic comic)  $default,) {final _that = this;
switch (_that) {
case _CollectedComic():
return $default(_that.collectionName,_that.comicId,_that.dateCreated,_that.comic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String collectionName,  String comicId,  DateTime dateCreated,  StoredComic comic)?  $default,) {final _that = this;
switch (_that) {
case _CollectedComic() when $default != null:
return $default(_that.collectionName,_that.comicId,_that.dateCreated,_that.comic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectedComic implements CollectedComic {
   _CollectedComic({required this.collectionName, required this.comicId, required this.dateCreated, required this.comic});
  factory _CollectedComic.fromJson(Map<String, dynamic> json) => _$CollectedComicFromJson(json);

@override final  String collectionName;
@override final  String comicId;
@override final  DateTime dateCreated;
@override final  StoredComic comic;

/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectedComicCopyWith<_CollectedComic> get copyWith => __$CollectedComicCopyWithImpl<_CollectedComic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectedComicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectedComic&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.dateCreated, dateCreated) || other.dateCreated == dateCreated)&&(identical(other.comic, comic) || other.comic == comic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionName,comicId,dateCreated,comic);

@override
String toString() {
  return 'CollectedComic(collectionName: $collectionName, comicId: $comicId, dateCreated: $dateCreated, comic: $comic)';
}


}

/// @nodoc
abstract mixin class _$CollectedComicCopyWith<$Res> implements $CollectedComicCopyWith<$Res> {
  factory _$CollectedComicCopyWith(_CollectedComic value, $Res Function(_CollectedComic) _then) = __$CollectedComicCopyWithImpl;
@override @useResult
$Res call({
 String collectionName, String comicId, DateTime dateCreated, StoredComic comic
});


@override $StoredComicCopyWith<$Res> get comic;

}
/// @nodoc
class __$CollectedComicCopyWithImpl<$Res>
    implements _$CollectedComicCopyWith<$Res> {
  __$CollectedComicCopyWithImpl(this._self, this._then);

  final _CollectedComic _self;
  final $Res Function(_CollectedComic) _then;

/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? collectionName = null,Object? comicId = null,Object? dateCreated = null,Object? comic = null,}) {
  return _then(_CollectedComic(
collectionName: null == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,dateCreated: null == dateCreated ? _self.dateCreated : dateCreated // ignore: cast_nullable_to_non_nullable
as DateTime,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as StoredComic,
  ));
}

/// Create a copy of CollectedComic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoredComicCopyWith<$Res> get comic {
  
  return $StoredComicCopyWith<$Res>(_self.comic, (value) {
    return _then(_self.copyWith(comic: value));
  });
}
}

// dart format on
