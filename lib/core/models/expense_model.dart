// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'expense_model.freezed.dart';
part 'expense_model.g.dart';

/// A single daily expense entry (food, petrol, consumables, rent, etc.).
@freezed
abstract class ExpenseModel with _$ExpenseModel {
  const factory ExpenseModel({
    @Default('') String id,
    required String techId,
    required String techName,
    required String category,
    required double amount,
    @Default('') String note,

    /// 'work' for regular expenses, 'home' for home chores
    @Default('work') String expenseType,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  }) = _ExpenseModel;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExpenseModel.fromJson({'id': doc.id, ...data});
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

extension ExpenseModelX on ExpenseModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}
