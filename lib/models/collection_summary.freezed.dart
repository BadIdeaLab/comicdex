// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CollectionSummary {

 String get collectionName; int get collectedCount; String get thumbnailUrl; int get thumbnailWidth; int get thumbnailHeight;
/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionSummaryCopyWith<CollectionSummary> get copyWith => _$CollectionSummaryCopyWithImpl<CollectionSummary>(this as CollectionSummary, _$identity);

  /// Serializes this CollectionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionSummary&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.collectedCount, collectedCount) || other.collectedCount == collectedCount)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.thumbnailWidth, thumbnailWidth) || other.thumbnailWidth == thumbnailWidth)&&(identical(other.thumbnailHeight, thumbnailHeight) || other.thumbnailHeight == thumbnailHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionName,collectedCount,thumbnailUrl,thumbnailWidth,thumbnailHeight);

@override
String toString() {
  return 'CollectionSummary(collectionName: $collectionName, collectedCount: $collectedCount, thumbnailUrl: $thumbnailUrl, thumbnailWidth: $thumbnailWidth, thumbnailHeight: $thumbnailHeight)';
}


}

/// @nodoc
abstract mixin class $CollectionSummaryCopyWith<$Res>  {
  factory $CollectionSummaryCopyWith(CollectionSummary value, $Res Function(CollectionSummary) _then) = _$CollectionSummaryCopyWithImpl;
@useResult
$Res call({
 String collectionName, int collectedCount, String thumbnailUrl, int thumbnailWidth, int thumbnailHeight
});




}
/// @nodoc
class _$CollectionSummaryCopyWithImpl<$Res>
    implements $CollectionSummaryCopyWith<$Res> {
  _$CollectionSummaryCopyWithImpl(this._self, this._then);

  final CollectionSummary _self;
  final $Res Function(CollectionSummary) _then;

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? collectionName = null,Object? collectedCount = null,Object? thumbnailUrl = null,Object? thumbnailWidth = null,Object? thumbnailHeight = null,}) {
  return _then(_self.copyWith(
collectionName: null == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String,collectedCount: null == collectedCount ? _self.collectedCount : collectedCount // ignore: cast_nullable_to_non_nullable
as int,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnailWidth: null == thumbnailWidth ? _self.thumbnailWidth : thumbnailWidth // ignore: cast_nullable_to_non_nullable
as int,thumbnailHeight: null == thumbnailHeight ? _self.thumbnailHeight : thumbnailHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionSummary].
extension CollectionSummaryPatterns on CollectionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionSummary value)  $default,){
final _that = this;
switch (_that) {
case _CollectionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String collectionName,  int collectedCount,  String thumbnailUrl,  int thumbnailWidth,  int thumbnailHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that.collectionName,_that.collectedCount,_that.thumbnailUrl,_that.thumbnailWidth,_that.thumbnailHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String collectionName,  int collectedCount,  String thumbnailUrl,  int thumbnailWidth,  int thumbnailHeight)  $default,) {final _that = this;
switch (_that) {
case _CollectionSummary():
return $default(_that.collectionName,_that.collectedCount,_that.thumbnailUrl,_that.thumbnailWidth,_that.thumbnailHeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String collectionName,  int collectedCount,  String thumbnailUrl,  int thumbnailWidth,  int thumbnailHeight)?  $default,) {final _that = this;
switch (_that) {
case _CollectionSummary() when $default != null:
return $default(_that.collectionName,_that.collectedCount,_that.thumbnailUrl,_that.thumbnailWidth,_that.thumbnailHeight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionSummary implements CollectionSummary {
   _CollectionSummary({required this.collectionName, required this.collectedCount, required this.thumbnailUrl, required this.thumbnailWidth, required this.thumbnailHeight});
  factory _CollectionSummary.fromJson(Map<String, dynamic> json) => _$CollectionSummaryFromJson(json);

@override final  String collectionName;
@override final  int collectedCount;
@override final  String thumbnailUrl;
@override final  int thumbnailWidth;
@override final  int thumbnailHeight;

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionSummaryCopyWith<_CollectionSummary> get copyWith => __$CollectionSummaryCopyWithImpl<_CollectionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionSummary&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.collectedCount, collectedCount) || other.collectedCount == collectedCount)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.thumbnailWidth, thumbnailWidth) || other.thumbnailWidth == thumbnailWidth)&&(identical(other.thumbnailHeight, thumbnailHeight) || other.thumbnailHeight == thumbnailHeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionName,collectedCount,thumbnailUrl,thumbnailWidth,thumbnailHeight);

@override
String toString() {
  return 'CollectionSummary(collectionName: $collectionName, collectedCount: $collectedCount, thumbnailUrl: $thumbnailUrl, thumbnailWidth: $thumbnailWidth, thumbnailHeight: $thumbnailHeight)';
}


}

/// @nodoc
abstract mixin class _$CollectionSummaryCopyWith<$Res> implements $CollectionSummaryCopyWith<$Res> {
  factory _$CollectionSummaryCopyWith(_CollectionSummary value, $Res Function(_CollectionSummary) _then) = __$CollectionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String collectionName, int collectedCount, String thumbnailUrl, int thumbnailWidth, int thumbnailHeight
});




}
/// @nodoc
class __$CollectionSummaryCopyWithImpl<$Res>
    implements _$CollectionSummaryCopyWith<$Res> {
  __$CollectionSummaryCopyWithImpl(this._self, this._then);

  final _CollectionSummary _self;
  final $Res Function(_CollectionSummary) _then;

/// Create a copy of CollectionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? collectionName = null,Object? collectedCount = null,Object? thumbnailUrl = null,Object? thumbnailWidth = null,Object? thumbnailHeight = null,}) {
  return _then(_CollectionSummary(
collectionName: null == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String,collectedCount: null == collectedCount ? _self.collectedCount : collectedCount // ignore: cast_nullable_to_non_nullable
as int,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnailWidth: null == thumbnailWidth ? _self.thumbnailWidth : thumbnailWidth // ignore: cast_nullable_to_non_nullable
as int,thumbnailHeight: null == thumbnailHeight ? _self.thumbnailHeight : thumbnailHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
