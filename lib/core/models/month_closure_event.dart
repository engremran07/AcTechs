import 'package:cloud_firestore/cloud_firestore.dart';

class MonthClosureEvent {
  const MonthClosureEvent({
    required this.companyId,
    required this.companyName,
    required this.month,
    required this.closedBy,
    required this.closedAt,
    required this.lockedBefore,
  });

  final String companyId;
  final String companyName;
  final DateTime month;
  final String closedBy;
  final DateTime closedAt;
  final DateTime lockedBefore;

  String get monthKey => '${month.year}-${month.month.toString().padLeft(2, '0')}';

  factory MonthClosureEvent.fromMap(Map<String, dynamic>? data) {
    final rawMonth = data?['month'];
    final rawClosedAt = data?['closedAt'];
    final rawLockedBefore = data?['lockedBefore'];

    DateTime parseDate(Object? value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final month = parseDate(rawMonth, now);
    return MonthClosureEvent(
      companyId: (data?['companyId'] as String? ?? '').trim(),
      companyName: (data?['companyName'] as String? ?? '').trim(),
      month: DateTime(month.year, month.month),
      closedBy: (data?['closedBy'] as String? ?? '').trim(),
      closedAt: parseDate(rawClosedAt, now),
      lockedBefore: parseDate(rawLockedBefore, DateTime(now.year, now.month, now.day)),
    );
  }

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'companyName': companyName,
        'month': Timestamp.fromDate(DateTime(month.year, month.month)),
        'monthKey': monthKey,
        'closedBy': closedBy,
        'closedAt': Timestamp.fromDate(closedAt),
        'lockedBefore': Timestamp.fromDate(lockedBefore),
      };
}
