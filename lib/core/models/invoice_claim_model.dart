import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceClaimModel {
  const InvoiceClaimModel({
    this.id = '',
    this.invoiceNumber = '',
    this.companyId = '',
    this.companyName = '',
    this.reuseMode = 'solo',
    this.activeJobCount = 0,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String invoiceNumber;
  final String companyId;
  final String companyName;
  final String reuseMode;
  final int activeJobCount;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InvoiceClaimModel.fromJson(Map<String, dynamic> json) {
    return InvoiceClaimModel(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      companyId: (json['companyId'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      reuseMode: (json['reuseMode'] ?? 'solo').toString(),
      activeJobCount: _asInt(json['activeJobCount']),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: _timestampFromJson(json['createdAt']),
      updatedAt: _timestampFromJson(json['updatedAt']),
    );
  }

  factory InvoiceClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InvoiceClaimModel.fromJson({'id': doc.id, ...data});
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'invoiceNumber': invoiceNumber,
      'companyId': companyId,
      'companyName': companyName,
      'reuseMode': reuseMode,
      'activeJobCount': activeJobCount,
      'createdBy': createdBy,
      'createdAt': _timestampToJson(createdAt),
      'updatedAt': _timestampToJson(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  bool get isActive => activeJobCount > 0;
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
