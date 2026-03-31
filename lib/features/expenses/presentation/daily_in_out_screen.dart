import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/expenses/data/expense_repository.dart';
import 'package:ac_techs/features/expenses/data/earning_repository.dart';
import 'package:ac_techs/features/expenses/providers/expense_providers.dart';

/// Unified daily In/Out screen — techs add earnings (IN) and expenses (OUT)
/// in a single view with a running profit/loss summary on top.
class DailyInOutScreen extends ConsumerStatefulWidget {
  const DailyInOutScreen({super.key});

  @override
  ConsumerState<DailyInOutScreen> createState() => _DailyInOutScreenState();
}

class _DailyInOutScreenState extends ConsumerState<DailyInOutScreen> {
  /// true = IN (earning), false = OUT (expense)
  bool _isIn = true;
  bool _isSaving = false;
  String _expenseType = AppConstants.expenseTypeWork;

  /// Batch entry rows — each has its own category, amount, remark
  final List<_EntryRow> _entryRows = [];

  @override
  void initState() {
    super.initState();
    _entryRows.add(
      _EntryRow(
        category: AppConstants.earningCategories.first,
        amountController: TextEditingController(),
        remarkController: TextEditingController(),
      ),
    );
  }

  @override
  void dispose() {
    for (final row in _entryRows) {
      row.amountController.dispose();
      row.remarkController.dispose();
    }
    super.dispose();
  }

  void _onDirectionChanged(bool isIn) {
    setState(() {
      _isIn = isIn;
      if (isIn) {
        _expenseType = AppConstants.expenseTypeWork;
      }
      final defaultCat = isIn
          ? AppConstants.earningCategories.first
          : _expenseCategories.first;
      for (final row in _entryRows) {
        row.category = defaultCat;
      }
    });
  }

  List<String> get _expenseCategories =>
      _expenseType == AppConstants.expenseTypeHome
      ? AppConstants.homeChoreCategories
      : AppConstants.expenseCategories;

  List<String> get _categories =>
      _isIn ? AppConstants.earningCategories : _expenseCategories;

  void _addRow() {
    setState(() {
      _entryRows.add(
        _EntryRow(
          category: _categories.first,
          amountController: TextEditingController(),
          remarkController: TextEditingController(),
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_entryRows.length > 1) {
      setState(() {
        _entryRows[index].amountController.dispose();
        _entryRows[index].remarkController.dispose();
        _entryRows.removeAt(index);
      });
    }
  }

  Future<void> _addEntries() async {
    // Validate all rows have amounts
    bool hasValid = false;
    for (final row in _entryRows) {
      final amountText = row.amountController.text.trim();
      if (amountText.isNotEmpty) {
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) {
          ErrorSnackbar.show(
            context,
            message: AppLocalizations.of(context)!.enterValidAmount,
          );
          return;
        }
        hasValid = true;
      }
    }

    if (!hasValid) {
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.enterAmount,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final now = DateTime.now();

      for (final row in _entryRows) {
        final amountText = row.amountController.text.trim();
        if (amountText.isEmpty) continue;
        final amount = double.tryParse(amountText);
        if (amount == null || amount <= 0) continue;
        final remark = row.remarkController.text.trim();

        if (_isIn) {
          final earning = EarningModel(
            techId: user.uid,
            techName: user.name,
            category: row.category,
            amount: amount,
            note: remark,
            date: now,
            createdAt: now,
          );
          await ref.read(earningRepositoryProvider).addEarning(earning);
        } else {
          final expense = ExpenseModel(
            techId: user.uid,
            techName: user.name,
            category: row.category,
            amount: amount,
            note: remark,
            expenseType: _expenseType,
            date: now,
            createdAt: now,
          );
          await ref.read(expenseRepositoryProvider).addExpense(expense);
        }
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        // Reset all rows to single empty row
        for (final row in _entryRows) {
          row.amountController.dispose();
          row.remarkController.dispose();
        }
        _entryRows.clear();
        _entryRows.add(
          _EntryRow(
            category: _categories.first,
            amountController: TextEditingController(),
            remarkController: TextEditingController(),
          ),
        );
        setState(() {});
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEarning(String id) async {
    try {
      await ref.read(earningRepositoryProvider).deleteEarning(id);
      if (mounted) HapticFeedback.mediumImpact();
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await ref.read(expenseRepositoryProvider).deleteExpense(id);
      if (mounted) HapticFeedback.mediumImpact();
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final earningsAsync = ref.watch(todaysEarningsProvider);
    final expensesAsync = ref.watch(todaysExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.scaleDown, child: Text(l.todaysInOut)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: l.monthlySummary,
            onPressed: () => context.push('/tech/summary'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary Card ──
            _buildSummaryCard(theme, earningsAsync, expensesAsync),
            const SizedBox(height: 20),

            // ── Add Entry Form ──
            _buildAddForm(theme),
            const SizedBox(height: 24),

            // ── Today's Entries ──
            Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  color: ArcticTheme.arcticBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(l.todaysEntries, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),

            _buildEntryList(theme, earningsAsync, expensesAsync),
          ],
        ),
      ),
    );
  }

  // ── Summary: IN | OUT | Profit/Loss ──
  Widget _buildSummaryCard(
    ThemeData theme,
    AsyncValue<List<EarningModel>> earningsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    final totalIn =
        earningsAsync.value?.fold<double>(0, (s, e) => s + e.amount) ?? 0;
    final totalOut =
        expensesAsync.value?.fold<double>(0, (s, e) => s + e.amount) ?? 0;
    final net = totalIn - totalOut;
    final isProfit = net >= 0;

    return ArcticCard(
      child: Column(
        children: [
          Row(
            children: [
              // IN
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: ArcticTheme.arcticSuccess,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(l.earned, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${totalIn.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ArcticTheme.arcticSuccess,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 50, color: ArcticTheme.arcticDivider),
              // OUT
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: ArcticTheme.arcticError,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(l.spent, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${totalOut.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: ArcticTheme.arcticError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Divider
              Container(width: 1, height: 50, color: ArcticTheme.arcticDivider),
              // Net
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isProfit
                          ? ArcticTheme.arcticSuccess
                          : ArcticTheme.arcticError,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProfit ? l.profit : l.loss,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SAR ${net.abs().toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isProfit
                            ? ArcticTheme.arcticSuccess
                            : ArcticTheme.arcticError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Add Entry Form ──
  Widget _buildAddForm(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return ArcticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IN / OUT Toggle
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: l.inEarned,
                  icon: Icons.arrow_downward_rounded,
                  isSelected: _isIn,
                  color: ArcticTheme.arcticSuccess,
                  onTap: () => _onDirectionChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DirectionButton(
                  label: l.outSpent,
                  icon: Icons.arrow_upward_rounded,
                  isSelected: !_isIn,
                  color: ArcticTheme.arcticError,
                  onTap: () => _onDirectionChanged(false),
                ),
              ),
            ],
          ),
          if (!_isIn) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DirectionButton(
                    label: l.workExpenses,
                    icon: Icons.work_outline_rounded,
                    isSelected: _expenseType == AppConstants.expenseTypeWork,
                    color: ArcticTheme.arcticWarning,
                    onTap: () {
                      setState(() {
                        _expenseType = AppConstants.expenseTypeWork;
                        for (final row in _entryRows) {
                          row.category = _expenseCategories.first;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionButton(
                    label: l.homeExpenses,
                    icon: Icons.home_work_outlined,
                    isSelected: _expenseType == AppConstants.expenseTypeHome,
                    color: ArcticTheme.arcticBlue,
                    onTap: () {
                      setState(() {
                        _expenseType = AppConstants.expenseTypeHome;
                        for (final row in _entryRows) {
                          row.category = _expenseCategories.first;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Batch entry rows
          ...List.generate(_entryRows.length, (i) {
            final row = _entryRows[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < _entryRows.length - 1 ? 12 : 0,
              ),
              child: Column(
                children: [
                  if (i > 0) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('cat_${_isIn}_$i'),
                          initialValue: row.category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: l.category,
                            prefixIcon: Icon(
                              _isIn
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: ArcticTheme.arcticTextSecondary,
                            ),
                            isDense: true,
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(translateCategory(c, l)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => row.category = v);
                          },
                        ),
                      ),
                      if (_entryRows.length > 1) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          color: ArcticTheme.arcticError,
                          onPressed: () => _removeRow(i),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ObjectKey(row.amountController),
                    controller: row.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.amountSar,
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ObjectKey(row.remarkController),
                    controller: row.remarkController,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.remarksOptional,
                      prefixIcon: Icon(
                        Icons.note_outlined,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Add another row button
          OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              _isIn ? l.addMoreEarning : l.addMoreExpense,
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticBlue,
              side: BorderSide(
                color: ArcticTheme.arcticBlue.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Submit all button
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _addEntries,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArcticTheme.arcticDarkBg,
                      ),
                    )
                  : Icon(_isIn ? Icons.add_rounded : Icons.remove_rounded),
              label: Text(
                _isSaving
                    ? l.saving
                    : _isIn
                    ? l.addEarning
                    : l.addExpense,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Merged chronological entry list ──
  Widget _buildEntryList(
    ThemeData theme,
    AsyncValue<List<EarningModel>> earningsAsync,
    AsyncValue<List<ExpenseModel>> expensesAsync,
  ) {
    final l = AppLocalizations.of(context)!;
    // Show loading if either is loading
    if (earningsAsync.isLoading || expensesAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final earnings = earningsAsync.value ?? [];
    final expenses = expensesAsync.value ?? [];

    if (earnings.isEmpty && expenses.isEmpty) {
      return ArcticCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: ArcticTheme.arcticTextSecondary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  l.noEntriesToday,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.addFirstEntry,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Merge into a single sorted list (newest first)
    final items =
        <_EntryItem>[
          for (final e in earnings)
            _EntryItem(
              id: e.id,
              isIn: true,
              category: e.category,
              amount: e.amount,
              note: e.note,
              date: e.date,
            ),
          for (final e in expenses)
            _EntryItem(
              id: e.id,
              isIn: false,
              category: e.category,
              amount: e.amount,
              note: e.note,
              expenseType: e.expenseType,
              date: e.date,
            ),
        ]..sort(
          (a, b) =>
              (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
        );

    return Column(
      children: items.asMap().entries.map((entry) {
        final item = entry.value;
        return Dismissible(
          key: Key('${item.isIn ? "in" : "out"}_${item.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: ArcticTheme.arcticError,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            if (item.isIn) {
              _deleteEarning(item.id);
            } else {
              _deleteExpense(item.id);
            }
          },
          child: ArcticCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Direction icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        (item.isIn
                                ? ArcticTheme.arcticSuccess
                                : ArcticTheme.arcticError)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.isIn
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: item.isIn
                        ? ArcticTheme.arcticSuccess
                        : ArcticTheme.arcticError,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translateCategory(item.category, l),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (item.note.isNotEmpty)
                        Text(
                          item.note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                        ),
                      if (!item.isIn &&
                          item.expenseType == AppConstants.expenseTypeHome)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ArcticTheme.arcticBlue.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.homeExpenses,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ArcticTheme.arcticBlue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '${item.isIn ? "+" : "-"} SAR ${item.amount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: item.isIn
                        ? ArcticTheme.arcticSuccess
                        : ArcticTheme.arcticError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (50 + entry.key * 40).ms),
        );
      }).toList(),
    );
  }
}

// ── Batch entry row data ──
class _EntryRow {
  _EntryRow({
    required this.category,
    required this.amountController,
    required this.remarkController,
  });

  String category;
  final TextEditingController amountController;
  final TextEditingController remarkController;
}

// ── Data holder for merged list ──
class _EntryItem {
  const _EntryItem({
    required this.id,
    required this.isIn,
    required this.category,
    required this.amount,
    required this.note,
    this.expenseType = AppConstants.expenseTypeWork,
    this.date,
  });

  final String id;
  final bool isIn;
  final String category;
  final double amount;
  final String note;
  final String expenseType;
  final DateTime? date;
}

// ── IN / OUT toggle button ──
class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : ArcticTheme.arcticDivider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color : ArcticTheme.arcticTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : ArcticTheme.arcticTextSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
