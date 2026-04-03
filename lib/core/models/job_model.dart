// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

enum JobStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

/// Represents one AC service line item on an invoice.
@freezed
abstract class AcUnit with _$AcUnit {
  const factory AcUnit({required String type, @Default(1) int quantity}) =
      _AcUnit;

  factory AcUnit.fromJson(Map<String, dynamic> json) => _$AcUnitFromJson(json);
}

/// Additional charges that may appear on an invoice.
@freezed
abstract class InvoiceCharges with _$InvoiceCharges {
  const factory InvoiceCharges({
    @Default(false) bool acBracket,
    @Default(0) int bracketCount,
    @Default(0.0) double bracketAmount,
    @Default(false) bool deliveryCharge,
    @Default(0.0) double deliveryAmount,
    @Default('') String deliveryNote,
  }) = _InvoiceCharges;

  factory InvoiceCharges.fromJson(Map<String, dynamic> json) =>
      _$InvoiceChargesFromJson(json);
}

@freezed
abstract class JobModel with _$JobModel {
  @JsonSerializable(explicitToJson: true)
  const factory JobModel({
    @Default('') String id,
    required String techId,
    required String techName,
    @Default('') String companyId,
    @Default('') String companyName,
    required String invoiceNumber,
    required String clientName,
    @Default('') String clientContact,
    @Default(<AcUnit>[]) List<AcUnit> acUnits,
    @Default(JobStatus.pending) JobStatus status,
    @Default(0.0) double expenses,
    @Default('') String expenseNote,
    @Default('') String adminNote,
    @Default(<String, dynamic>{}) Map<String, dynamic> importMeta,
    @Default('') String approvedBy,
    @Default(false) bool isSharedInstall,
    @Default('') String sharedInstallGroupKey,
    @Default(0) int sharedInvoiceTotalUnits,
    @Default(0) int sharedContributionUnits,
    @Default(0) int sharedInvoiceSplitUnits,
    @Default(0) int sharedInvoiceWindowUnits,
    @Default(0) int sharedInvoiceFreestandingUnits,
    @Default(0) int sharedDeliveryTeamCount,
    @Default(0.0) double sharedInvoiceDeliveryAmount,

    /// Additional invoice charges (bracket, delivery).
    InvoiceCharges? charges,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? submittedAt,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? reviewedAt,
  }) = _JobModel;

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JobModel.fromJson({'id': doc.id, ...data});
  }
}

DateTime? _timestampFromJson(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

dynamic _timestampToJson(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

extension JobModelX on JobModel {
  bool get isPending => status == JobStatus.pending;
  bool get isApproved => status == JobStatus.approved;
  bool get isRejected => status == JobStatus.rejected;

  int get totalUnits => acUnits.fold(0, (s, unit) => s + unit.quantity);

  int unitsForType(String type) {
    return acUnits
        .where((unit) => unit.type == type)
        .fold(0, (total, unit) => total + unit.quantity);
  }

  int get sharedInstallUnitsTotal =>
      unitsForType('Split AC') +
      unitsForType('Window AC') +
      unitsForType('Freestanding AC');

  /// Total of all additional charges on this invoice.
  double get totalCharges {
    final c = charges;
    if (c == null) return 0;
    return (c.acBracket ? c.bracketAmount : 0) +
        (c.deliveryCharge ? c.deliveryAmount : 0);
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}
