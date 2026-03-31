import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';

class MonthlySummaryScreen extends ConsumerStatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  ConsumerState<MonthlySummaryScreen> createState() =>
      _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends ConsumerState<MonthlySummaryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() => _selectedMonth = next);
  }

  String _monthLabel() {
    final l = AppLocalizations.of(context)!;
    final months = [
      l.january,
      l.february,
      l.march,
      l.april,
      l.may,
      l.june,
      l.july,
      l.august,
      l.september,
      l.october,
      l.november,
      l.december,
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(monthlyJobsProvider(_selectedMonth));
    final expensesAsync = ref.watch(monthlyExpensesProvider(_selectedMonth));
    final earningsAsync = ref.watch(monthlyEarningsProvider(_selectedMonth));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.monthlySummary)),
      body: SafeArea(
        child: ArcticRefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlyJobsProvider(_selectedMonth));
            ref.invalidate(monthlyExpensesProvider(_selectedMonth));
            ref.invalidate(monthlyEarningsProvider(_selectedMonth));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Month Selector
              _buildMonthSelector(context),
              const SizedBox(height: 20),

              // Summary Cards
              _buildOverviewCards(
                context,
                jobsAsync,
                expensesAsync,
                earningsAsync,
              ),
              const SizedBox(height: 24),

              // Earnings Breakdown
              _buildEarningsBreakdown(context, earningsAsync),
              const SizedBox(height: 16),

              // Expenses Breakdown
              _buildExpensesBreakdown(context, expensesAsync),
              const SizedBox(height: 16),

              // Installations Breakdown
              _buildInstallationsBreakdown(context, jobsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            backgroundColor: ArcticTheme.arcticSurface,
          ),
        ),
        Text(
          _monthLabel(),
          style: Theme.of(context).textTheme.titleLarge,
        ).animate(key: ValueKey(_selectedMonth)).fadeIn().slideX(begin: 0.05),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
          style: IconButton.styleFrom(
            backgroundColor: ArcticTheme.arcticSurface,
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildOverviewCards(
    BuildContext context,
    AsyncValue jobsAsync,
    AsyncValue expensesAsync,
    AsyncValue earningsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final jobs = jobsAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];
    final earnings = earningsAsync.value ?? [];

    final totalInstallations = jobs.fold<int>(0, (s, j) => s + j.totalUnits);
    final totalEarnings = earnings.fold<double>(0, (s, e) => s + e.amount);
    final workExpenses = expenses
        .where((item) => item.expenseType != AppConstants.expenseTypeHome)
        .fold<double>(0, (s, e) => s + e.amount);
    final homeExpenses = expenses
        .where((item) => item.expenseType == AppConstants.expenseTypeHome)
        .fold<double>(0, (s, e) => s + e.amount);
    final totalExpenses = workExpenses + homeExpenses;
    final profit = totalEarnings - totalExpenses;

    final isLoading =
        jobsAsync.isLoading ||
        expensesAsync.isLoading ||
        earningsAsync.isLoading;

    if (isLoading) {
      return const ArcticShimmer(height: 90, count: 2);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: l.installations,
                value: l.nUnits(totalInstallations),
                icon: Icons.ac_unit_rounded,
                color: ArcticTheme.arcticBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: l.jobs,
                value: '${jobs.length}',
                icon: Icons.work_outline_rounded,
                color: ArcticTheme.arcticTextSecondary,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: l.earningsIn,
                value: AppFormatters.currency(totalEarnings),
                icon: Icons.arrow_downward_rounded,
                color: ArcticTheme.arcticSuccess,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: l.workExpenses,
                value: AppFormatters.currency(workExpenses),
                icon: Icons.arrow_upward_rounded,
                color: ArcticTheme.arcticError,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: l.homeExpenses,
                value: AppFormatters.currency(homeExpenses),
                icon: Icons.home_work_outlined,
                color: ArcticTheme.arcticBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: l.netProfit,
                value: AppFormatters.currency(profit),
                icon: profit >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: profit >= 0
                    ? ArcticTheme.arcticSuccess
                    : ArcticTheme.arcticError,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildEarningsBreakdown(
    BuildContext context,
    AsyncValue earningsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final earnings = earningsAsync.value ?? [];
    if (earningsAsync.isLoading) {
      return const ArcticShimmer(height: 40, count: 3);
    }
    if (earnings.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by category
    final byCategory = <String, double>{};
    for (final e in earnings) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: ArcticTheme.arcticSuccess,
              ),
              const SizedBox(width: 8),
              Text(
                l.earningsBreakdown,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const Divider(height: 20),
          ...byCategory.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      translateCategory(
                        entry.key,
                        AppLocalizations.of(context)!,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(entry.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArcticTheme.arcticSuccess,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildExpensesBreakdown(
    BuildContext context,
    AsyncValue expensesAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final expenses = expensesAsync.value ?? [];
    if (expensesAsync.isLoading) {
      return const ArcticShimmer(height: 40, count: 3);
    }
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by category
    final workByCategory = _groupExpensesByCategory(expenses, false);
    final homeByCategory = _groupExpensesByCategory(expenses, true);

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: ArcticTheme.arcticError,
              ),
              const SizedBox(width: 8),
              Text(
                l.expensesBreakdown,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const Divider(height: 20),
          if (workByCategory.isNotEmpty) ...[
            Text(
              l.workExpenses,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: ArcticTheme.arcticError),
            ),
            const SizedBox(height: 8),
            ...workByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        translateCategory(
                          entry.key,
                          AppLocalizations.of(context)!,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ArcticTheme.arcticError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (homeByCategory.isNotEmpty) ...[
            if (workByCategory.isNotEmpty) const Divider(height: 24),
            Text(
              l.homeExpenses,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: ArcticTheme.arcticBlue),
            ),
            const SizedBox(height: 8),
            ...homeByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        translateCategory(
                          entry.key,
                          AppLocalizations.of(context)!,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(entry.value),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ArcticTheme.arcticBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Map<String, double> _groupExpensesByCategory(
    List<ExpenseModel> expenses,
    bool homeOnly,
  ) {
    final byCategory = <String, double>{};
    for (final expense in expenses) {
      final isHome = expense.expenseType == AppConstants.expenseTypeHome;
      if (homeOnly != isHome) continue;
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.amount;
    }
    return byCategory;
  }

  Widget _buildInstallationsBreakdown(
    BuildContext context,
    AsyncValue jobsAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final jobs = jobsAsync.value ?? [];
    if (jobsAsync.isLoading) {
      return const ArcticShimmer(height: 40, count: 3);
    }
    if (jobs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group by AC type
    final byType = <String, int>{};
    for (final job in jobs) {
      for (final unit in job.acUnits) {
        byType[unit.type] = ((byType[unit.type] ?? 0) + unit.quantity).toInt();
      }
    }
    if (byType.isEmpty) return const SizedBox.shrink();

    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.ac_unit_rounded,
                size: 18,
                color: ArcticTheme.arcticBlue,
              ),
              const SizedBox(width: 8),
              Text(
                l.installationsByType,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const Divider(height: 20),
          ...byType.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      translateCategory(
                        entry.key,
                        AppLocalizations.of(context)!,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.nUnits(entry.value),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArcticTheme.arcticBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ArcticCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
