// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyModel _$CompanyModelFromJson(Map<String, dynamic> json) =>
    _CompanyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
        invoicePrefix: json['invoicePrefix'] as String? ?? '',
        invoicePeriodStartDay: json['invoicePeriodStartDay'] as int? ?? 1,
        invoicePeriodEndDay: json['invoicePeriodEndDay'] as int? ?? 31,
        isActive: json['isActive'] as bool? ?? true,
      logoBase64: json['logoBase64'] as String? ?? '',
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$CompanyModelToJson(_CompanyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'invoicePrefix': instance.invoicePrefix,
      'invoicePeriodStartDay': instance.invoicePeriodStartDay,
      'invoicePeriodEndDay': instance.invoicePeriodEndDay,
      'isActive': instance.isActive,
      'logoBase64': instance.logoBase64,
      'createdAt': _timestampToJson(instance.createdAt),
    };
