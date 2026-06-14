// ignore_for_file: invalid_annotation_target
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'company_model.freezed.dart';
part 'company_model.g.dart';

/// A client company whose sold ACs are installed by our technicians.
@freezed
abstract class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    @Default('') String id,
    required String name,
    @Default('') String invoicePrefix,
    @Default(1) int invoicePeriodStartDay,
    @Default(31) int invoicePeriodEndDay,
    @Default(true) bool isActive,
    @Default('') String logoBase64,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    DateTime? createdAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CompanyModel.fromJson({'id': doc.id, ...data});
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

extension CompanyModelX on CompanyModel {
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  bool get hasCustomInvoicePeriod =>
      invoicePeriodStartDay != 1 || invoicePeriodEndDay != 31;

  DateTimeRange invoicePeriodForDate(DateTime date) {
    final startDay = invoicePeriodStartDay.clamp(1, 31);
    final endDay = invoicePeriodEndDay.clamp(1, 31);

    DateTime clampToMonth(int year, int month, int day) {
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, min(day, lastDayOfMonth));
    }

    if (startDay <= endDay) {
      final periodStart = clampToMonth(date.year, date.month, startDay);
      if (date.isBefore(periodStart)) {
        final previousMonth = DateTime(date.year, date.month - 1);
        return DateTimeRange(
          start: clampToMonth(
            previousMonth.year,
            previousMonth.month,
            startDay,
          ),
          end: clampToMonth(previousMonth.year, previousMonth.month, endDay)
              .add(
                const Duration(
                  hours: 23,
                  minutes: 59,
                  seconds: 59,
                  milliseconds: 999,
                ),
              ),
        );
      }
      return DateTimeRange(
        start: periodStart,
        end: clampToMonth(date.year, date.month, endDay).add(
          const Duration(
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        ),
      );
    }

    if (date.day >= startDay) {
      final periodStart = clampToMonth(date.year, date.month, startDay);
      final nextMonth = DateTime(date.year, date.month + 1);
      return DateTimeRange(
        start: periodStart,
        end: clampToMonth(nextMonth.year, nextMonth.month, endDay).add(
          const Duration(
            hours: 23,
            minutes: 59,
            seconds: 59,
            milliseconds: 999,
          ),
        ),
      );
    }

    final previousMonth = DateTime(date.year, date.month - 1);
    return DateTimeRange(
      start: clampToMonth(previousMonth.year, previousMonth.month, startDay),
      end: clampToMonth(date.year, date.month, endDay).add(
        const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
      ),
    );
  }
}
