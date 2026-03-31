// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earning_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EarningModel {

 String get id; String get techId; String get techName; String get category; double get amount; String get note;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get date;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get createdAt;
/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EarningModelCopyWith<EarningModel> get copyWith => _$EarningModelCopyWithImpl<EarningModel>(this as EarningModel, _$identity);

  /// Serializes this EarningModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,category,amount,note,date,createdAt);

@override
String toString() {
  return 'EarningModel(id: $id, techId: $techId, techName: $techName, category: $category, amount: $amount, note: $note, date: $date, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EarningModelCopyWith<$Res>  {
  factory $EarningModelCopyWith(EarningModel value, $Res Function(EarningModel) _then) = _$EarningModelCopyWithImpl;
@useResult
$Res call({
 String id, String techId, String techName, String category, double amount, String note,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt
});




}
/// @nodoc
class _$EarningModelCopyWithImpl<$Res>
    implements $EarningModelCopyWith<$Res> {
  _$EarningModelCopyWithImpl(this._self, this._then);

  final EarningModel _self;
  final $Res Function(EarningModel) _then;

/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? category = null,Object? amount = null,Object? note = null,Object? date = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EarningModel].
extension EarningModelPatterns on EarningModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EarningModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EarningModel value)  $default,){
final _that = this;
switch (_that) {
case _EarningModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EarningModel value)?  $default,){
final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String category,  double amount,  String note, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.date,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String category,  double amount,  String note, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _EarningModel():
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.date,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String techId,  String techName,  String category,  double amount,  String note, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EarningModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.date,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EarningModel implements EarningModel {
  const _EarningModel({this.id = '', required this.techId, required this.techName, required this.category, required this.amount, this.note = '', @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.createdAt});
  factory _EarningModel.fromJson(Map<String, dynamic> json) => _$EarningModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String techId;
@override final  String techName;
@override final  String category;
@override final  double amount;
@override@JsonKey() final  String note;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? date;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? createdAt;

/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EarningModelCopyWith<_EarningModel> get copyWith => __$EarningModelCopyWithImpl<_EarningModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EarningModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EarningModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,category,amount,note,date,createdAt);

@override
String toString() {
  return 'EarningModel(id: $id, techId: $techId, techName: $techName, category: $category, amount: $amount, note: $note, date: $date, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EarningModelCopyWith<$Res> implements $EarningModelCopyWith<$Res> {
  factory _$EarningModelCopyWith(_EarningModel value, $Res Function(_EarningModel) _then) = __$EarningModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String techId, String techName, String category, double amount, String note,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt
});




}
/// @nodoc
class __$EarningModelCopyWithImpl<$Res>
    implements _$EarningModelCopyWith<$Res> {
  __$EarningModelCopyWithImpl(this._self, this._then);

  final _EarningModel _self;
  final $Res Function(_EarningModel) _then;

/// Create a copy of EarningModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? category = null,Object? amount = null,Object? note = null,Object? date = freezed,Object? createdAt = freezed,}) {
  return _then(_EarningModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
