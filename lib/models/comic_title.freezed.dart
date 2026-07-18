// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_title.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicTitle {

 String? get english; String? get japanese; String? get pretty;
/// Create a copy of ComicTitle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicTitleCopyWith<ComicTitle> get copyWith => _$ComicTitleCopyWithImpl<ComicTitle>(this as ComicTitle, _$identity);

  /// Serializes this ComicTitle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicTitle&&(identical(other.english, english) || other.english == english)&&(identical(other.japanese, japanese) || other.japanese == japanese)&&(identical(other.pretty, pretty) || other.pretty == pretty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,english,japanese,pretty);

@override
String toString() {
  return 'ComicTitle(english: $english, japanese: $japanese, pretty: $pretty)';
}


}

/// @nodoc
abstract mixin class $ComicTitleCopyWith<$Res>  {
  factory $ComicTitleCopyWith(ComicTitle value, $Res Function(ComicTitle) _then) = _$ComicTitleCopyWithImpl;
@useResult
$Res call({
 String? english, String? japanese, String? pretty
});




}
/// @nodoc
class _$ComicTitleCopyWithImpl<$Res>
    implements $ComicTitleCopyWith<$Res> {
  _$ComicTitleCopyWithImpl(this._self, this._then);

  final ComicTitle _self;
  final $Res Function(ComicTitle) _then;

/// Create a copy of ComicTitle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? english = freezed,Object? japanese = freezed,Object? pretty = freezed,}) {
  return _then(_self.copyWith(
english: freezed == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String?,japanese: freezed == japanese ? _self.japanese : japanese // ignore: cast_nullable_to_non_nullable
as String?,pretty: freezed == pretty ? _self.pretty : pretty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicTitle].
extension ComicTitlePatterns on ComicTitle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicTitle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicTitle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicTitle value)  $default,){
final _that = this;
switch (_that) {
case _ComicTitle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicTitle value)?  $default,){
final _that = this;
switch (_that) {
case _ComicTitle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? english,  String? japanese,  String? pretty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicTitle() when $default != null:
return $default(_that.english,_that.japanese,_that.pretty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? english,  String? japanese,  String? pretty)  $default,) {final _that = this;
switch (_that) {
case _ComicTitle():
return $default(_that.english,_that.japanese,_that.pretty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? english,  String? japanese,  String? pretty)?  $default,) {final _that = this;
switch (_that) {
case _ComicTitle() when $default != null:
return $default(_that.english,_that.japanese,_that.pretty);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicTitle implements ComicTitle {
   _ComicTitle({this.english, this.japanese, this.pretty});
  factory _ComicTitle.fromJson(Map<String, dynamic> json) => _$ComicTitleFromJson(json);

@override final  String? english;
@override final  String? japanese;
@override final  String? pretty;

/// Create a copy of ComicTitle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicTitleCopyWith<_ComicTitle> get copyWith => __$ComicTitleCopyWithImpl<_ComicTitle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicTitleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicTitle&&(identical(other.english, english) || other.english == english)&&(identical(other.japanese, japanese) || other.japanese == japanese)&&(identical(other.pretty, pretty) || other.pretty == pretty));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,english,japanese,pretty);

@override
String toString() {
  return 'ComicTitle(english: $english, japanese: $japanese, pretty: $pretty)';
}


}

/// @nodoc
abstract mixin class _$ComicTitleCopyWith<$Res> implements $ComicTitleCopyWith<$Res> {
  factory _$ComicTitleCopyWith(_ComicTitle value, $Res Function(_ComicTitle) _then) = __$ComicTitleCopyWithImpl;
@override @useResult
$Res call({
 String? english, String? japanese, String? pretty
});




}
/// @nodoc
class __$ComicTitleCopyWithImpl<$Res>
    implements _$ComicTitleCopyWith<$Res> {
  __$ComicTitleCopyWithImpl(this._self, this._then);

  final _ComicTitle _self;
  final $Res Function(_ComicTitle) _then;

/// Create a copy of ComicTitle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? english = freezed,Object? japanese = freezed,Object? pretty = freezed,}) {
  return _then(_ComicTitle(
english: freezed == english ? _self.english : english // ignore: cast_nullable_to_non_nullable
as String?,japanese: freezed == japanese ? _self.japanese : japanese // ignore: cast_nullable_to_non_nullable
as String?,pretty: freezed == pretty ? _self.pretty : pretty // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
