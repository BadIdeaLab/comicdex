// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicTag {

 int? get id; String? get type; String? get name; String? get url; int? get count;
/// Create a copy of ComicTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicTagCopyWith<ComicTag> get copyWith => _$ComicTagCopyWithImpl<ComicTag>(this as ComicTag, _$identity);

  /// Serializes this ComicTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicTag&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,url,count);

@override
String toString() {
  return 'ComicTag(id: $id, type: $type, name: $name, url: $url, count: $count)';
}


}

/// @nodoc
abstract mixin class $ComicTagCopyWith<$Res>  {
  factory $ComicTagCopyWith(ComicTag value, $Res Function(ComicTag) _then) = _$ComicTagCopyWithImpl;
@useResult
$Res call({
 int? id, String? type, String? name, String? url, int? count
});




}
/// @nodoc
class _$ComicTagCopyWithImpl<$Res>
    implements $ComicTagCopyWith<$Res> {
  _$ComicTagCopyWithImpl(this._self, this._then);

  final ComicTag _self;
  final $Res Function(ComicTag) _then;

/// Create a copy of ComicTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? type = freezed,Object? name = freezed,Object? url = freezed,Object? count = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicTag].
extension ComicTagPatterns on ComicTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicTag value)  $default,){
final _that = this;
switch (_that) {
case _ComicTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicTag value)?  $default,){
final _that = this;
switch (_that) {
case _ComicTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? type,  String? name,  String? url,  int? count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicTag() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.url,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? type,  String? name,  String? url,  int? count)  $default,) {final _that = this;
switch (_that) {
case _ComicTag():
return $default(_that.id,_that.type,_that.name,_that.url,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? type,  String? name,  String? url,  int? count)?  $default,) {final _that = this;
switch (_that) {
case _ComicTag() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.url,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicTag implements ComicTag {
   _ComicTag({this.id, this.type, this.name, this.url, this.count});
  factory _ComicTag.fromJson(Map<String, dynamic> json) => _$ComicTagFromJson(json);

@override final  int? id;
@override final  String? type;
@override final  String? name;
@override final  String? url;
@override final  int? count;

/// Create a copy of ComicTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicTagCopyWith<_ComicTag> get copyWith => __$ComicTagCopyWithImpl<_ComicTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicTag&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,url,count);

@override
String toString() {
  return 'ComicTag(id: $id, type: $type, name: $name, url: $url, count: $count)';
}


}

/// @nodoc
abstract mixin class _$ComicTagCopyWith<$Res> implements $ComicTagCopyWith<$Res> {
  factory _$ComicTagCopyWith(_ComicTag value, $Res Function(_ComicTag) _then) = __$ComicTagCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? type, String? name, String? url, int? count
});




}
/// @nodoc
class __$ComicTagCopyWithImpl<$Res>
    implements _$ComicTagCopyWith<$Res> {
  __$ComicTagCopyWithImpl(this._self, this._then);

  final _ComicTag _self;
  final $Res Function(_ComicTag) _then;

/// Create a copy of ComicTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = freezed,Object? name = freezed,Object? url = freezed,Object? count = freezed,}) {
  return _then(_ComicTag(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
