import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/settings/data/month_closure_repository.dart';
import 'package:ac_techs/features/settings/data/month_closure_notice_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

final monthClosuresProvider = StreamProvider.autoDispose<List<MonthClosureEvent>>(
  (ref) {
    return ref.watch(monthClosureRepositoryProvider).watchMonthClosures();
  },
);

final latestMonthClosureProvider = Provider.autoDispose<AsyncValue<MonthClosureEvent?>>(
  (ref) {
    return ref.watch(monthClosuresProvider).whenData((entries) {
      if (entries.isEmpty) return null;
      return entries.first;
    });
  },
);

final unreadMonthClosureProvider = FutureProvider.autoDispose<MonthClosureEvent?>(
  (ref) async {
    final user = ref.watch(currentUserProvider).value;
    final latest = ref.watch(latestMonthClosureProvider).value;
    if (user == null || latest == null) return null;

    final repo = ref.watch(monthClosureNoticeRepositoryProvider);
    final seen = await repo.hasSeen(
      techId: user.uid,
      companyId: latest.companyId,
      monthKey: latest.monthKey,
    );
    return seen ? null : latest;
  },
);
