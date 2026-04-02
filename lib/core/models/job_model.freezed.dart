// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcUnit {

 String get type; int get quantity;
/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcUnitCopyWith<AcUnit> get copyWith => _$AcUnitCopyWithImpl<AcUnit>(this as AcUnit, _$identity);

  /// Serializes this AcUnit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcUnit&&(identical(other.type, type) || other.type == type)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,quantity);

@override
String toString() {
  return 'AcUnit(type: $type, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $AcUnitCopyWith<$Res>  {
  factory $AcUnitCopyWith(AcUnit value, $Res Function(AcUnit) _then) = _$AcUnitCopyWithImpl;
@useResult
$Res call({
 String type, int quantity
});




}
/// @nodoc
class _$AcUnitCopyWithImpl<$Res>
    implements $AcUnitCopyWith<$Res> {
  _$AcUnitCopyWithImpl(this._self, this._then);

  final AcUnit _self;
  final $Res Function(AcUnit) _then;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AcUnit].
extension AcUnitPatterns on AcUnit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcUnit value)  $default,){
final _that = this;
switch (_that) {
case _AcUnit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcUnit value)?  $default,){
final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
return $default(_that.type,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _AcUnit():
return $default(_that.type,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
return $default(_that.type,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcUnit implements AcUnit {
  const _AcUnit({required this.type, this.quantity = 1});
  factory _AcUnit.fromJson(Map<String, dynamic> json) => _$AcUnitFromJson(json);

@override final  String type;
@override@JsonKey() final  int quantity;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcUnitCopyWith<_AcUnit> get copyWith => __$AcUnitCopyWithImpl<_AcUnit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcUnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcUnit&&(identical(other.type, type) || other.type == type)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,quantity);

@override
String toString() {
  return 'AcUnit(type: $type, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$AcUnitCopyWith<$Res> implements $AcUnitCopyWith<$Res> {
  factory _$AcUnitCopyWith(_AcUnit value, $Res Function(_AcUnit) _then) = __$AcUnitCopyWithImpl;
@override @useResult
$Res call({
 String type, int quantity
});




}
/// @nodoc
class __$AcUnitCopyWithImpl<$Res>
    implements _$AcUnitCopyWith<$Res> {
  __$AcUnitCopyWithImpl(this._self, this._then);

  final _AcUnit _self;
  final $Res Function(_AcUnit) _then;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? quantity = null,}) {
  return _then(_AcUnit(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InvoiceCharges {

 bool get acBracket; int get bracketCount; double get bracketAmount; bool get deliveryCharge; double get deliveryAmount; String get deliveryNote;
/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<InvoiceCharges> get copyWith => _$InvoiceChargesCopyWithImpl<InvoiceCharges>(this as InvoiceCharges, _$identity);

  /// Serializes this InvoiceCharges to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceCharges&&(identical(other.acBracket, acBracket) || other.acBracket == acBracket)&&(identical(other.bracketCount, bracketCount) || other.bracketCount == bracketCount)&&(identical(other.bracketAmount, bracketAmount) || other.bracketAmount == bracketAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.deliveryAmount, deliveryAmount) || other.deliveryAmount == deliveryAmount)&&(identical(other.deliveryNote, deliveryNote) || other.deliveryNote == deliveryNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acBracket,bracketCount,bracketAmount,deliveryCharge,deliveryAmount,deliveryNote);

@override
String toString() {
  return 'InvoiceCharges(acBracket: $acBracket, bracketCount: $bracketCount, bracketAmount: $bracketAmount, deliveryCharge: $deliveryCharge, deliveryAmount: $deliveryAmount, deliveryNote: $deliveryNote)';
}


}

/// @nodoc
abstract mixin class $InvoiceChargesCopyWith<$Res>  {
  factory $InvoiceChargesCopyWith(InvoiceCharges value, $Res Function(InvoiceCharges) _then) = _$InvoiceChargesCopyWithImpl;
@useResult
$Res call({
 bool acBracket, int bracketCount, double bracketAmount, bool deliveryCharge, double deliveryAmount, String deliveryNote
});




}
/// @nodoc
class _$InvoiceChargesCopyWithImpl<$Res>
    implements $InvoiceChargesCopyWith<$Res> {
  _$InvoiceChargesCopyWithImpl(this._self, this._then);

  final InvoiceCharges _self;
  final $Res Function(InvoiceCharges) _then;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acBracket = null,Object? bracketCount = null,Object? bracketAmount = null,Object? deliveryCharge = null,Object? deliveryAmount = null,Object? deliveryNote = null,}) {
  return _then(_self.copyWith(
acBracket: null == acBracket ? _self.acBracket : acBracket // ignore: cast_nullable_to_non_nullable
as bool,bracketCount: null == bracketCount ? _self.bracketCount : bracketCount // ignore: cast_nullable_to_non_nullable
as int,bracketAmount: null == bracketAmount ? _self.bracketAmount : bracketAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as bool,deliveryAmount: null == deliveryAmount ? _self.deliveryAmount : deliveryAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryNote: null == deliveryNote ? _self.deliveryNote : deliveryNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceCharges].
extension InvoiceChargesPatterns on InvoiceCharges {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceCharges value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceCharges value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceCharges():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceCharges value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)  $default,) {final _that = this;
switch (_that) {
case _InvoiceCharges():
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceCharges implements InvoiceCharges {
  const _InvoiceCharges({this.acBracket = false, this.bracketCount = 0, this.bracketAmount = 0.0, this.deliveryCharge = false, this.deliveryAmount = 0.0, this.deliveryNote = ''});
  factory _InvoiceCharges.fromJson(Map<String, dynamic> json) => _$InvoiceChargesFromJson(json);

@override@JsonKey() final  bool acBracket;
@override@JsonKey() final  int bracketCount;
@override@JsonKey() final  double bracketAmount;
@override@JsonKey() final  bool deliveryCharge;
@override@JsonKey() final  double deliveryAmount;
@override@JsonKey() final  String deliveryNote;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceChargesCopyWith<_InvoiceCharges> get copyWith => __$InvoiceChargesCopyWithImpl<_InvoiceCharges>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceChargesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceCharges&&(identical(other.acBracket, acBracket) || other.acBracket == acBracket)&&(identical(other.bracketCount, bracketCount) || other.bracketCount == bracketCount)&&(identical(other.bracketAmount, bracketAmount) || other.bracketAmount == bracketAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.deliveryAmount, deliveryAmount) || other.deliveryAmount == deliveryAmount)&&(identical(other.deliveryNote, deliveryNote) || other.deliveryNote == deliveryNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acBracket,bracketCount,bracketAmount,deliveryCharge,deliveryAmount,deliveryNote);

@override
String toString() {
  return 'InvoiceCharges(acBracket: $acBracket, bracketCount: $bracketCount, bracketAmount: $bracketAmount, deliveryCharge: $deliveryCharge, deliveryAmount: $deliveryAmount, deliveryNote: $deliveryNote)';
}


}

/// @nodoc
abstract mixin class _$InvoiceChargesCopyWith<$Res> implements $InvoiceChargesCopyWith<$Res> {
  factory _$InvoiceChargesCopyWith(_InvoiceCharges value, $Res Function(_InvoiceCharges) _then) = __$InvoiceChargesCopyWithImpl;
@override @useResult
$Res call({
 bool acBracket, int bracketCount, double bracketAmount, bool deliveryCharge, double deliveryAmount, String deliveryNote
});




}
/// @nodoc
class __$InvoiceChargesCopyWithImpl<$Res>
    implements _$InvoiceChargesCopyWith<$Res> {
  __$InvoiceChargesCopyWithImpl(this._self, this._then);

  final _InvoiceCharges _self;
  final $Res Function(_InvoiceCharges) _then;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acBracket = null,Object? bracketCount = null,Object? bracketAmount = null,Object? deliveryCharge = null,Object? deliveryAmount = null,Object? deliveryNote = null,}) {
  return _then(_InvoiceCharges(
acBracket: null == acBracket ? _self.acBracket : acBracket // ignore: cast_nullable_to_non_nullable
as bool,bracketCount: null == bracketCount ? _self.bracketCount : bracketCount // ignore: cast_nullable_to_non_nullable
as int,bracketAmount: null == bracketAmount ? _self.bracketAmount : bracketAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as bool,deliveryAmount: null == deliveryAmount ? _self.deliveryAmount : deliveryAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryNote: null == deliveryNote ? _self.deliveryNote : deliveryNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JobModel {

 String get id; String get techId; String get techName; String get companyId; String get companyName; String get invoiceNumber; String get clientName; String get clientContact; List<AcUnit> get acUnits; JobStatus get status; double get expenses; String get expenseNote; String get adminNote; Map<String, dynamic> get importMeta; String get approvedBy;/// Additional invoice charges (bracket, delivery).
 InvoiceCharges? get charges;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get date;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get submittedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get reviewedAt;
/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobModelCopyWith<JobModel> get copyWith => _$JobModelCopyWithImpl<JobModel>(this as JobModel, _$identity);

  /// Serializes this JobModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientContact, clientContact) || other.clientContact == clientContact)&&const DeepCollectionEquality().equals(other.acUnits, acUnits)&&(identical(other.status, status) || other.status == status)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.expenseNote, expenseNote) || other.expenseNote == expenseNote)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&const DeepCollectionEquality().equals(other.importMeta, importMeta)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.charges, charges) || other.charges == charges)&&(identical(other.date, date) || other.date == date)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,techId,techName,companyId,companyName,invoiceNumber,clientName,clientContact,const DeepCollectionEquality().hash(acUnits),status,expenses,expenseNote,adminNote,const DeepCollectionEquality().hash(importMeta),approvedBy,charges,date,submittedAt,reviewedAt]);

@override
String toString() {
  return 'JobModel(id: $id, techId: $techId, techName: $techName, companyId: $companyId, companyName: $companyName, invoiceNumber: $invoiceNumber, clientName: $clientName, clientContact: $clientContact, acUnits: $acUnits, status: $status, expenses: $expenses, expenseNote: $expenseNote, adminNote: $adminNote, importMeta: $importMeta, approvedBy: $approvedBy, charges: $charges, date: $date, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class $JobModelCopyWith<$Res>  {
  factory $JobModelCopyWith(JobModel value, $Res Function(JobModel) _then) = _$JobModelCopyWithImpl;
@useResult
$Res call({
 String id, String techId, String techName, String companyId, String companyName, String invoiceNumber, String clientName, String clientContact, List<AcUnit> acUnits, JobStatus status, double expenses, String expenseNote, String adminNote, Map<String, dynamic> importMeta, String approvedBy, InvoiceCharges? charges,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? submittedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt
});


$InvoiceChargesCopyWith<$Res>? get charges;

}
/// @nodoc
class _$JobModelCopyWithImpl<$Res>
    implements $JobModelCopyWith<$Res> {
  _$JobModelCopyWithImpl(this._self, this._then);

  final JobModel _self;
  final $Res Function(JobModel) _then;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? companyId = null,Object? companyName = null,Object? invoiceNumber = null,Object? clientName = null,Object? clientContact = null,Object? acUnits = null,Object? status = null,Object? expenses = null,Object? expenseNote = null,Object? adminNote = null,Object? importMeta = null,Object? approvedBy = null,Object? charges = freezed,Object? date = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientContact: null == clientContact ? _self.clientContact : clientContact // ignore: cast_nullable_to_non_nullable
as String,acUnits: null == acUnits ? _self.acUnits : acUnits // ignore: cast_nullable_to_non_nullable
as List<AcUnit>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as double,expenseNote: null == expenseNote ? _self.expenseNote : expenseNote // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,importMeta: null == importMeta ? _self.importMeta : importMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,charges: freezed == charges ? _self.charges : charges // ignore: cast_nullable_to_non_nullable
as InvoiceCharges?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
    return null;
  }

  return $InvoiceChargesCopyWith<$Res>(_self.charges!, (value) {
    return _then(_self.copyWith(charges: value));
  });
}
}


/// Adds pattern-matching-related methods to [JobModel].
extension JobModelPatterns on JobModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobModel value)  $default,){
final _that = this;
switch (_that) {
case _JobModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobModel value)?  $default,){
final _that = this;
switch (_that) {
case _JobModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  Map<String, dynamic> importMeta,  String approvedBy,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.importMeta,_that.approvedBy,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  Map<String, dynamic> importMeta,  String approvedBy,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _JobModel():
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.importMeta,_that.approvedBy,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  Map<String, dynamic> importMeta,  String approvedBy,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _JobModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.importMeta,_that.approvedBy,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _JobModel implements JobModel {
  const _JobModel({this.id = '', required this.techId, required this.techName, this.companyId = '', this.companyName = '', required this.invoiceNumber, required this.clientName, this.clientContact = '', final  List<AcUnit> acUnits = const <AcUnit>[], this.status = JobStatus.pending, this.expenses = 0.0, this.expenseNote = '', this.adminNote = '', final  Map<String, dynamic> importMeta = const <String, dynamic>{}, this.approvedBy = '', this.charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.reviewedAt}): _acUnits = acUnits,_importMeta = importMeta;
  factory _JobModel.fromJson(Map<String, dynamic> json) => _$JobModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String techId;
@override final  String techName;
@override@JsonKey() final  String companyId;
@override@JsonKey() final  String companyName;
@override final  String invoiceNumber;
@override final  String clientName;
@override@JsonKey() final  String clientContact;
 final  List<AcUnit> _acUnits;
@override@JsonKey() List<AcUnit> get acUnits {
  if (_acUnits is EqualUnmodifiableListView) return _acUnits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_acUnits);
}

@override@JsonKey() final  JobStatus status;
@override@JsonKey() final  double expenses;
@override@JsonKey() final  String expenseNote;
@override@JsonKey() final  String adminNote;
 final  Map<String, dynamic> _importMeta;
@override@JsonKey() Map<String, dynamic> get importMeta {
  if (_importMeta is EqualUnmodifiableMapView) return _importMeta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_importMeta);
}

@override@JsonKey() final  String approvedBy;
/// Additional invoice charges (bracket, delivery).
@override final  InvoiceCharges? charges;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? date;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? submittedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? reviewedAt;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobModelCopyWith<_JobModel> get copyWith => __$JobModelCopyWithImpl<_JobModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientContact, clientContact) || other.clientContact == clientContact)&&const DeepCollectionEquality().equals(other._acUnits, _acUnits)&&(identical(other.status, status) || other.status == status)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.expenseNote, expenseNote) || other.expenseNote == expenseNote)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&const DeepCollectionEquality().equals(other._importMeta, _importMeta)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.charges, charges) || other.charges == charges)&&(identical(other.date, date) || other.date == date)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,techId,techName,companyId,companyName,invoiceNumber,clientName,clientContact,const DeepCollectionEquality().hash(_acUnits),status,expenses,expenseNote,adminNote,const DeepCollectionEquality().hash(_importMeta),approvedBy,charges,date,submittedAt,reviewedAt]);

@override
String toString() {
  return 'JobModel(id: $id, techId: $techId, techName: $techName, companyId: $companyId, companyName: $companyName, invoiceNumber: $invoiceNumber, clientName: $clientName, clientContact: $clientContact, acUnits: $acUnits, status: $status, expenses: $expenses, expenseNote: $expenseNote, adminNote: $adminNote, importMeta: $importMeta, approvedBy: $approvedBy, charges: $charges, date: $date, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$JobModelCopyWith<$Res> implements $JobModelCopyWith<$Res> {
  factory _$JobModelCopyWith(_JobModel value, $Res Function(_JobModel) _then) = __$JobModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String techId, String techName, String companyId, String companyName, String invoiceNumber, String clientName, String clientContact, List<AcUnit> acUnits, JobStatus status, double expenses, String expenseNote, String adminNote, Map<String, dynamic> importMeta, String approvedBy, InvoiceCharges? charges,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? submittedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt
});


@override $InvoiceChargesCopyWith<$Res>? get charges;

}
/// @nodoc
class __$JobModelCopyWithImpl<$Res>
    implements _$JobModelCopyWith<$Res> {
  __$JobModelCopyWithImpl(this._self, this._then);

  final _JobModel _self;
  final $Res Function(_JobModel) _then;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? companyId = null,Object? companyName = null,Object? invoiceNumber = null,Object? clientName = null,Object? clientContact = null,Object? acUnits = null,Object? status = null,Object? expenses = null,Object? expenseNote = null,Object? adminNote = null,Object? importMeta = null,Object? approvedBy = null,Object? charges = freezed,Object? date = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,}) {
  return _then(_JobModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientContact: null == clientContact ? _self.clientContact : clientContact // ignore: cast_nullable_to_non_nullable
as String,acUnits: null == acUnits ? _self._acUnits : acUnits // ignore: cast_nullable_to_non_nullable
as List<AcUnit>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as double,expenseNote: null == expenseNote ? _self.expenseNote : expenseNote // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,importMeta: null == importMeta ? _self._importMeta : importMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,charges: freezed == charges ? _self.charges : charges // ignore: cast_nullable_to_non_nullable
as InvoiceCharges?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
    return null;
  }

  return $InvoiceChargesCopyWith<$Res>(_self.charges!, (value) {
    return _then(_self.copyWith(charges: value));
  });
}
}

// dart format on
