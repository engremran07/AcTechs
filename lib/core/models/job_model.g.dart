// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AcUnit _$AcUnitFromJson(Map<String, dynamic> json) => _AcUnit(
  type: json['type'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$AcUnitToJson(_AcUnit instance) => <String, dynamic>{
  'type': instance.type,
  'quantity': instance.quantity,
};

_InvoiceCharges _$InvoiceChargesFromJson(Map<String, dynamic> json) =>
    _InvoiceCharges(
      acBracket: json['acBracket'] as bool? ?? false,
      bracketCount: (json['bracketCount'] as num?)?.toInt() ?? 0,
      bracketAmount: (json['bracketAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: json['deliveryCharge'] as bool? ?? false,
      deliveryAmount: (json['deliveryAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryNote: json['deliveryNote'] as String? ?? '',
    );

Map<String, dynamic> _$InvoiceChargesToJson(_InvoiceCharges instance) =>
    <String, dynamic>{
      'acBracket': instance.acBracket,
      'bracketCount': instance.bracketCount,
      'bracketAmount': instance.bracketAmount,
      'deliveryCharge': instance.deliveryCharge,
      'deliveryAmount': instance.deliveryAmount,
      'deliveryNote': instance.deliveryNote,
    };

_JobModel _$JobModelFromJson(Map<String, dynamic> json) => _JobModel(
  id: json['id'] as String? ?? '',
  techId: json['techId'] as String,
  techName: json['techName'] as String,
  companyId: json['companyId'] as String? ?? '',
  companyName: json['companyName'] as String? ?? '',
  invoiceNumber: json['invoiceNumber'] as String,
  clientName: json['clientName'] as String,
  clientContact: json['clientContact'] as String? ?? '',
  acUnits:
      (json['acUnits'] as List<dynamic>?)
          ?.map((e) => AcUnit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AcUnit>[],
  status:
      $enumDecodeNullable(_$JobStatusEnumMap, json['status']) ??
      JobStatus.pending,
  expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
  expenseNote: json['expenseNote'] as String? ?? '',
  adminNote: json['adminNote'] as String? ?? '',
  importMeta:
      json['importMeta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  approvedBy: json['approvedBy'] as String?,
  isSharedInstall: json['isSharedInstall'] as bool? ?? false,
  sharedInstallGroupKey: json['sharedInstallGroupKey'] as String? ?? '',
  sharedInvoiceTotalUnits:
      (json['sharedInvoiceTotalUnits'] as num?)?.toInt() ?? 0,
  sharedContributionUnits:
      (json['sharedContributionUnits'] as num?)?.toInt() ?? 0,
  sharedInvoiceSplitUnits:
      (json['sharedInvoiceSplitUnits'] as num?)?.toInt() ?? 0,
  sharedInvoiceWindowUnits:
      (json['sharedInvoiceWindowUnits'] as num?)?.toInt() ?? 0,
  sharedInvoiceFreestandingUnits:
      (json['sharedInvoiceFreestandingUnits'] as num?)?.toInt() ?? 0,
  sharedDeliveryTeamCount:
      (json['sharedDeliveryTeamCount'] as num?)?.toInt() ?? 0,
  sharedInvoiceDeliveryAmount:
      (json['sharedInvoiceDeliveryAmount'] as num?)?.toDouble() ?? 0.0,
  techSplitShare: (json['techSplitShare'] as num?)?.toInt() ?? 0,
  techWindowShare: (json['techWindowShare'] as num?)?.toInt() ?? 0,
  techFreestandingShare: (json['techFreestandingShare'] as num?)?.toInt() ?? 0,
  charges: json['charges'] == null
      ? null
      : InvoiceCharges.fromJson(json['charges'] as Map<String, dynamic>),
  date: _timestampFromJson(json['date']),
  submittedAt: _timestampFromJson(json['submittedAt']),
  reviewedAt: _timestampFromJson(json['reviewedAt']),
);

Map<String, dynamic> _$JobModelToJson(_JobModel instance) => <String, dynamic>{
  'id': instance.id,
  'techId': instance.techId,
  'techName': instance.techName,
  'companyId': instance.companyId,
  'companyName': instance.companyName,
  'invoiceNumber': instance.invoiceNumber,
  'clientName': instance.clientName,
  'clientContact': instance.clientContact,
  'acUnits': instance.acUnits.map((e) => e.toJson()).toList(),
  'status': _$JobStatusEnumMap[instance.status]!,
  'expenses': instance.expenses,
  'expenseNote': instance.expenseNote,
  'adminNote': instance.adminNote,
  'importMeta': instance.importMeta,
  'approvedBy': instance.approvedBy,
  'isSharedInstall': instance.isSharedInstall,
  'sharedInstallGroupKey': instance.sharedInstallGroupKey,
  'sharedInvoiceTotalUnits': instance.sharedInvoiceTotalUnits,
  'sharedContributionUnits': instance.sharedContributionUnits,
  'sharedInvoiceSplitUnits': instance.sharedInvoiceSplitUnits,
  'sharedInvoiceWindowUnits': instance.sharedInvoiceWindowUnits,
  'sharedInvoiceFreestandingUnits': instance.sharedInvoiceFreestandingUnits,
  'sharedDeliveryTeamCount': instance.sharedDeliveryTeamCount,
  'sharedInvoiceDeliveryAmount': instance.sharedInvoiceDeliveryAmount,
  'techSplitShare': instance.techSplitShare,
  'techWindowShare': instance.techWindowShare,
  'techFreestandingShare': instance.techFreestandingShare,
  'charges': instance.charges?.toJson(),
  'date': _timestampToJson(instance.date),
  'submittedAt': _timestampToJson(instance.submittedAt),
  'reviewedAt': _timestampToJson(instance.reviewedAt),
};

const _$JobStatusEnumMap = {
  JobStatus.pending: 'pending',
  JobStatus.approved: 'approved',
  JobStatus.rejected: 'rejected',
};
