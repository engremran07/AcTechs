// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'earning_model.freezed.dart';
part 'earning_model.g.dart';

/// A single earning entry (sold old AC, sold scrap, etc.).
@freezed
abstract class EarningModel with _$EarningModel {
  const factory EarningModel({
    @Default('') String id,
    required String techId,
    required String techName,
    required String category,
    required double amount,
    @Default('') String note,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? date,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  }) = _EarningModel;

  factory EarningModel.fromJson(Map<String, dynamic> json) =>
      _$EarningModelFromJson(json);

  factory EarningModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EarningModel.fromJson({'id': doc.id, ...data});
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

extension EarningModelX on EarningModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
}
