import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class SettlementBreakdown {
  SettlementBreakdown({
    required this.splitUnits,
    required this.windowUnits,
    required this.freestandingUnits,
    required this.bracketCount,
    required this.deliveryAmount,
    required this.dueAmount,
    required this.paidAmount,
    required this.totalUnits,
    required this.totalAmount,
  });

  factory SettlementBreakdown.fromJobs(Iterable<JobModel> jobs) {
    var splitUnits = 0;
    var windowUnits = 0;
    var freestandingUnits = 0;
    var bracketCount = 0;
    var deliveryAmount = 0.0;
    var dueAmount = 0.0;
    var paidAmount = 0.0;
    var totalUnits = 0;
    var totalAmount = 0.0;

    for (final job in jobs) {
      final units = job.sharedInstallUnitsTotal;
      totalUnits += units;
      splitUnits += job.techSplitShare > 0
          ? job.techSplitShare
          : job.unitsForType(AppConstants.unitTypeSplitAc);
      windowUnits += job.techWindowShare > 0
          ? job.techWindowShare
          : job.unitsForType(AppConstants.unitTypeWindowAc);
      freestandingUnits += job.techFreestandingShare > 0
          ? job.techFreestandingShare
          : job.unitsForType(AppConstants.unitTypeFreestandingAc);
      bracketCount += job.techBracketShare > 0
          ? job.techBracketShare
          : job.effectiveBracketCount;
      deliveryAmount += job.totalCharges;
      totalAmount += job.settlementAmount;
      if (job.isSettlementConfirmed) {
        paidAmount += job.settlementAmount;
      } else {
        dueAmount += job.settlementAmount;
      }
    }

    return SettlementBreakdown(
      splitUnits: splitUnits,
      windowUnits: windowUnits,
      freestandingUnits: freestandingUnits,
      bracketCount: bracketCount,
      deliveryAmount: deliveryAmount,
      dueAmount: dueAmount,
      paidAmount: paidAmount,
      totalUnits: totalUnits,
      totalAmount: totalAmount,
    );
  }

  final int splitUnits;
  final int windowUnits;
  final int freestandingUnits;
  final int bracketCount;
  final double deliveryAmount;
  final double dueAmount;
  final double paidAmount;
  final int totalUnits;
  final double totalAmount;

  String label(AppLocalizations l) {
    return '${l.total}: ${AppFormatters.currency(totalAmount)}';
  }
}
