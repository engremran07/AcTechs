// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) =>
    _ExpenseModel(
      id: json['id'] as String? ?? '',
      techId: json['techId'] as String,
      techName: json['techName'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      expenseType: json['expenseType'] as String? ?? 'work',
      date: _timestampFromJson(json['date']),
      createdAt: _timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$ExpenseModelToJson(_ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'techId': instance.techId,
      'techName': instance.techName,
      'category': instance.category,
      'amount': instance.amount,
      'note': instance.note,
      'expenseType': instance.expenseType,
      'date': _timestampToJson(instance.date),
      'createdAt': _timestampToJson(instance.createdAt),
    };
