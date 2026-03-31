// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(Map<String, dynamic> json) =>
    _EarningModel(
      id: json['id'] as String? ?? '',
      techId: json['techId'] as String,
      techName: json['techName'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      date: _timestampFromJson(json['date']),
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$EarningModelToJson(_EarningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'techId': instance.techId,
      'techName': instance.techName,
      'category': instance.category,
      'amount': instance.amount,
      'note': instance.note,
      'date': _timestampToJson(instance.date),
      'createdAt': _timestampToJson(instance.createdAt),
    };
