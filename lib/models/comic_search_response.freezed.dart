// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_search_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicSearchResponse {

 List<Comic> get result;@JsonKey(name: 'num_pages') int? get numPages;@JsonKey(name: 'per_page') int? get perPage;
/// Create a copy of ComicSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicSearchResponseCopyWith<ComicSearchResponse> get copyWith => _$ComicSearchResponseCopyWithImpl<ComicSearchResponse>(this as ComicSearchResponse, _$identity);

  /// Serializes this ComicSearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicSearchResponse&&const DeepCollectionEquality().equals(other.result, result)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&(identical(other.perPage, perPage) || other.perPage == perPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(result),numPages,perPage);

@override
String toString() {
  return 'ComicSearchResponse(result: $result, numPages: $numPages, perPage: $perPage)';
}


}

/// @nodoc
abstract mixin class $ComicSearchResponseCopyWith<$Res>  {
  factory $ComicSearchResponseCopyWith(ComicSearchResponse value, $Res Function(ComicSearchResponse) _then) = _$ComicSearchResponseCopyWithImpl;
@useResult
$Res call({
 List<Comic> result,@JsonKey(name: 'num_pages') int? numPages,@JsonKey(name: 'per_page') int? perPage
});




}
/// @nodoc
class _$ComicSearchResponseCopyWithImpl<$Res>
    implements $ComicSearchResponseCopyWith<$Res> {
  _$ComicSearchResponseCopyWithImpl(this._self, this._then);

  final ComicSearchResponse _self;
  final $Res Function(ComicSearchResponse) _then;

/// Create a copy of ComicSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? result = null,Object? numPages = freezed,Object? perPage = freezed,}) {
  return _then(_self.copyWith(
result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as List<Comic>,numPages: freezed == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int?,perPage: freezed == perPage ? _self.perPage : perPage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicSearchResponse].
extension ComicSearchResponsePatterns on ComicSearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicSearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicSearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicSearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _ComicSearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicSearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ComicSearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Comic> result, @JsonKey(name: 'num_pages')  int? numPages, @JsonKey(name: 'per_page')  int? perPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicSearchResponse() when $default != null:
return $default(_that.result,_that.numPages,_that.perPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Comic> result, @JsonKey(name: 'num_pages')  int? numPages, @JsonKey(name: 'per_page')  int? perPage)  $default,) {final _that = this;
switch (_that) {
case _ComicSearchResponse():
return $default(_that.result,_that.numPages,_that.perPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Comic> result, @JsonKey(name: 'num_pages')  int? numPages, @JsonKey(name: 'per_page')  int? perPage)?  $default,) {final _that = this;
switch (_that) {
case _ComicSearchResponse() when $default != null:
return $default(_that.result,_that.numPages,_that.perPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicSearchResponse implements ComicSearchResponse {
   _ComicSearchResponse({final  List<Comic> result = const <Comic>[], @JsonKey(name: 'num_pages') this.numPages, @JsonKey(name: 'per_page') this.perPage}): _result = result;
  factory _ComicSearchResponse.fromJson(Map<String, dynamic> json) => _$ComicSearchResponseFromJson(json);

 final  List<Comic> _result;
@override@JsonKey() List<Comic> get result {
  if (_result is EqualUnmodifiableListView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_result);
}

@override@JsonKey(name: 'num_pages') final  int? numPages;
@override@JsonKey(name: 'per_page') final  int? perPage;

/// Create a copy of ComicSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicSearchResponseCopyWith<_ComicSearchResponse> get copyWith => __$ComicSearchResponseCopyWithImpl<_ComicSearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicSearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicSearchResponse&&const DeepCollectionEquality().equals(other._result, _result)&&(identical(other.numPages, numPages) || other.numPages == numPages)&&(identical(other.perPage, perPage) || other.perPage == perPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_result),numPages,perPage);

@override
String toString() {
  return 'ComicSearchResponse(result: $result, numPages: $numPages, perPage: $perPage)';
}


}

/// @nodoc
abstract mixin class _$ComicSearchResponseCopyWith<$Res> implements $ComicSearchResponseCopyWith<$Res> {
  factory _$ComicSearchResponseCopyWith(_ComicSearchResponse value, $Res Function(_ComicSearchResponse) _then) = __$ComicSearchResponseCopyWithImpl;
@override @useResult
$Res call({
 List<Comic> result,@JsonKey(name: 'num_pages') int? numPages,@JsonKey(name: 'per_page') int? perPage
});




}
/// @nodoc
class __$ComicSearchResponseCopyWithImpl<$Res>
    implements _$ComicSearchResponseCopyWith<$Res> {
  __$ComicSearchResponseCopyWithImpl(this._self, this._then);

  final _ComicSearchResponse _self;
  final $Res Function(_ComicSearchResponse) _then;

/// Create a copy of ComicSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? result = null,Object? numPages = freezed,Object? perPage = freezed,}) {
  return _then(_ComicSearchResponse(
result: null == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as List<Comic>,numPages: freezed == numPages ? _self.numPages : numPages // ignore: cast_nullable_to_non_nullable
as int?,perPage: freezed == perPage ? _self.perPage : perPage // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
