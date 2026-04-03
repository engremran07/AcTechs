import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';

class SubmitJobScreen extends ConsumerStatefulWidget {
  const SubmitJobScreen({super.key});

  @override
  ConsumerState<SubmitJobScreen> createState() => _SubmitJobScreenState();
}

class _SubmitJobScreenState extends ConsumerState<SubmitJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _deliveryAmountController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  int _bracketQty = 0;
  int _splitQty = 0;
  int _windowQty = 0;
  int _uninstallSplitQty = 0;
  int _uninstallWindowQty = 0;
  int _uninstallStandingQty = 0;
  int _dolabQty = 0;
  bool _isSharedInstall = false;
  int _techSplitShare = 0;
  int _techWindowShare = 0;
  int _techFreestandingShare = 0;
  final _sharedSplitUnitsController = TextEditingController();
  final _sharedWindowUnitsController = TextEditingController();
  final _sharedFreestandingUnitsController = TextEditingController();
  final _sharedTeamSizeController = TextEditingController();
  String? _selectedCompanyId;
  String _selectedCompanyName = '';
  String _selectedCompanyPrefix = '';

  @override
  void dispose() {
    _invoiceController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _deliveryAmountController.dispose();
    _deliveryNoteController.dispose();
    _descriptionController.dispose();
    _sharedSplitUnitsController.dispose();
    _sharedWindowUnitsController.dispose();
    _sharedFreestandingUnitsController.dispose();
    _sharedTeamSizeController.dispose();
    super.dispose();
  }

  List<AcUnit> _unitsFromQuickTemplate() {
    final units = <AcUnit>[];
    if (_splitQty > 0) {
      units.add(AcUnit(type: 'Split AC', quantity: _splitQty));
    }
    if (_windowQty > 0) {
      units.add(AcUnit(type: 'Window AC', quantity: _windowQty));
    }
    if (_uninstallSplitQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallSplit,
          quantity: _uninstallSplitQty,
        ),
      );
    }
    if (_uninstallWindowQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallWindow,
          quantity: _uninstallWindowQty,
        ),
      );
    }
    if (_uninstallStandingQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallFreestanding,
          quantity: _uninstallStandingQty,
        ),
      );
    }
    if (_dolabQty > 0) {
      units.add(AcUnit(type: 'Freestanding AC', quantity: _dolabQty));
    }
    return units;
  }

  String _normalizeContact(String raw) {
    final trimmed = raw.trim();
    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _invoiceController.clear();
    _clientNameController.clear();
    _clientContactController.clear();
    _deliveryAmountController.clear();
    _deliveryNoteController.clear();
    _descriptionController.clear();
    _sharedSplitUnitsController.clear();
    _sharedWindowUnitsController.clear();
    _sharedFreestandingUnitsController.clear();
    _sharedTeamSizeController.clear();
    setState(() {
      _bracketQty = 0;
      _splitQty = 0;
      _windowQty = 0;
      _uninstallSplitQty = 0;
      _uninstallWindowQty = 0;
      _uninstallStandingQty = 0;
      _dolabQty = 0;
      _isSharedInstall = false;
      _techSplitShare = 0;
      _techWindowShare = 0;
      _techFreestandingShare = 0;
      _selectedCompanyId = null;
      _selectedCompanyName = '';
      _selectedCompanyPrefix = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;
    final quickUnits = _unitsFromQuickTemplate();

    if (quickUnits.isEmpty) {
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.addServiceFirst,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final asyncUser = ref.read(currentUserProvider);
      if (!asyncUser.hasValue || asyncUser.value == null) {
        if (mounted) {
          ErrorSnackbar.show(
            context,
            message: asyncUser.isLoading
                ? AppLocalizations.of(context)!.userDataLoading
                : AppLocalizations.of(context)!.couldNotSubmitJob,
          );
        }
        return;
      }
      final user = asyncUser.value!;
      final approvalConfig = ref.read(approvalConfigProvider).value;
      final sharedSplitUnits =
          int.tryParse(_sharedSplitUnitsController.text.trim()) ?? 0;
      final sharedWindowUnits =
          int.tryParse(_sharedWindowUnitsController.text.trim()) ?? 0;
      final sharedFreestandingUnits =
          int.tryParse(_sharedFreestandingUnitsController.text.trim()) ?? 0;
      final sharedTeamSize =
          int.tryParse(_sharedTeamSizeController.text.trim()) ?? 0;
      if (_isSharedInstall &&
          ((_splitQty > 0 && _splitQty > sharedSplitUnits) ||
              (_windowQty > 0 && _windowQty > sharedWindowUnits) ||
              (_dolabQty > 0 && _dolabQty > sharedFreestandingUnits))) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.sharedInstallLimitError);
        }
        return;
      }

      final rawDeliveryAmount =
          double.tryParse(_deliveryAmountController.text.trim()) ?? 0;
      if (_isSharedInstall && rawDeliveryAmount > 0 && sharedTeamSize <= 0) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.sharedDeliverySplitInvalid);
        }
        return;
      }
      final deliveryAmount = _isSharedInstall && rawDeliveryAmount > 0
          ? rawDeliveryAmount / sharedTeamSize
          : rawDeliveryAmount;

      final charges = InvoiceCharges(
        acBracket: _bracketQty > 0,
        bracketCount: _bracketQty,
        bracketAmount: 0,
        deliveryAmount: deliveryAmount,
        deliveryCharge: deliveryAmount > 0,
        deliveryNote: _deliveryNoteController.text.trim(),
      );

      final normalizedInvoice = _buildInvoiceNumber();
      final sharedGroupKey = _isSharedInstall
          ? '${(_selectedCompanyId ?? 'no-company')}-${normalizedInvoice.toLowerCase()}'
          : '';

      final sharedContributionUnits = _splitQty + _windowQty + _dolabQty;
      final sharedInvoiceTotalUnits =
          sharedSplitUnits + sharedWindowUnits + sharedFreestandingUnits;

      final job = JobModel(
        techId: user.uid,
        techName: user.name,
        companyId: _selectedCompanyId ?? '',
        companyName: _selectedCompanyName,
        invoiceNumber: normalizedInvoice,
        clientName: _clientNameController.text.trim(),
        clientContact: _normalizeContact(_clientContactController.text),
        acUnits: quickUnits,
        expenseNote: _descriptionController.text.trim(),
        isSharedInstall: _isSharedInstall,
        sharedInstallGroupKey: sharedGroupKey,
        sharedInvoiceTotalUnits: _isSharedInstall ? sharedInvoiceTotalUnits : 0,
        sharedContributionUnits: _isSharedInstall ? sharedContributionUnits : 0,
        sharedInvoiceSplitUnits: _isSharedInstall ? sharedSplitUnits : 0,
        sharedInvoiceWindowUnits: _isSharedInstall ? sharedWindowUnits : 0,
        sharedInvoiceFreestandingUnits: _isSharedInstall
            ? sharedFreestandingUnits
            : 0,
        sharedDeliveryTeamCount: _isSharedInstall ? sharedTeamSize : 0,
        sharedInvoiceDeliveryAmount: _isSharedInstall ? rawDeliveryAmount : 0,
        techSplitShare: _techSplitShare,
        techWindowShare: _techWindowShare,
        techFreestandingShare: _techFreestandingShare,
        charges: charges,
        date: _selectedDate,
        submittedAt: DateTime.now(),
        status:
            ((_isSharedInstall
                    ? approvalConfig?.sharedJobApprovalRequired
                    : approvalConfig?.jobApprovalRequired) ??
                false)
            ? JobStatus.pending
            : JobStatus.approved,
      );

      await ref.read(jobRepositoryProvider).submitJob(job);

      if (mounted) {
        SuccessSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.jobSubmitted,
        );
        _resetForm();
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        ErrorSnackbar.show(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(activeCompaniesProvider);

    return AppShortcuts(
      onSubmit: _isSubmitting ? null : _submit,
      child: Scaffold(
        appBar: AppBar(title: Text(l.submitInvoice)),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: FormFocusTraversal(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── AC Services (single source of truth) ──
                    _SectionHeader(
                      icon: Icons.ac_unit_rounded,
                      title: l.acServices,
                    ),
                    const SizedBox(height: 8),
                    ArcticCard(
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l.sharedInstall),
                            subtitle: Text(l.sharedInstallHint),
                            value: _isSharedInstall,
                            onChanged: (value) =>
                                setState(() => _isSharedInstall = value),
                          ),
                          if (_isSharedInstall) ...[
                            const SizedBox(height: 8),
                            Text(
                              l.sharedInstallMixHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _sharedSplitUnitsController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: l.sharedInvoiceSplitUnits,
                                      labelText: l.sharedInvoiceSplitUnits,
                                      prefixIcon: const Icon(
                                        Icons.ac_unit_rounded,
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sharedWindowUnitsController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: l.sharedInvoiceWindowUnits,
                                      labelText: l.sharedInvoiceWindowUnits,
                                      prefixIcon: const Icon(
                                        Icons.window_rounded,
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        _sharedFreestandingUnitsController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText:
                                          l.sharedInvoiceFreestandingUnits,
                                      labelText:
                                          l.sharedInvoiceFreestandingUnits,
                                      prefixIcon: const Icon(
                                        Icons.weekend_rounded,
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sharedTeamSizeController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      hintText: l.sharedTeamSize,
                                      labelText: l.sharedTeamSize,
                                      prefixIcon: const Icon(
                                        Icons.groups_rounded,
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: _QtyTile(
                                  label: l.splits,
                                  value: _splitQty,
                                  onChanged: (v) =>
                                      setState(() => _splitQty = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QtyTile(
                                  label: l.windowAc,
                                  value: _windowQty,
                                  onChanged: (v) =>
                                      setState(() => _windowQty = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _QtyTile(
                                  label: l.standing,
                                  value: _dolabQty,
                                  onChanged: (v) =>
                                      setState(() => _dolabQty = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QtyTile(
                                  label: l.acOutdoorBracket,
                                  value: _bracketQty,
                                  onChanged: (v) =>
                                      setState(() => _bracketQty = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _QtyTile(
                                  label: l.uninstallSplit,
                                  value: _uninstallSplitQty,
                                  onChanged: (v) =>
                                      setState(() => _uninstallSplitQty = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QtyTile(
                                  label: l.uninstallWindow,
                                  value: _uninstallWindowQty,
                                  onChanged: (v) =>
                                      setState(() => _uninstallWindowQty = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _QtyTile(
                                  label: l.uninstallStanding,
                                  value: _uninstallStandingQty,
                                  onChanged: (v) =>
                                      setState(() => _uninstallStandingQty = v),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descriptionController,
                            textInputAction: TextInputAction.next,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: l.descriptionLabel,
                              prefixIcon: const Icon(
                                Icons.notes_rounded,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 80.ms),

                    // ── My Installation Share ──
                    if (_splitQty + _windowQty + _dolabQty > 0) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.person_pin_circle_rounded,
                        title: l.myShare,
                      ),
                      const SizedBox(height: 8),
                      ArcticCard(
                        child: Column(
                          children: [
                            if (_splitQty > 0)
                              _QtyTile(
                                label: l.splits,
                                value: _techSplitShare,
                                onChanged: (v) => setState(
                                  () => _techSplitShare = v.clamp(0, _splitQty),
                                ),
                              ),
                            if (_splitQty > 0 &&
                                (_windowQty > 0 || _dolabQty > 0))
                              const SizedBox(height: 8),
                            if (_windowQty > 0)
                              _QtyTile(
                                label: l.windowAc,
                                value: _techWindowShare,
                                onChanged: (v) => setState(
                                  () =>
                                      _techWindowShare = v.clamp(0, _windowQty),
                                ),
                              ),
                            if (_windowQty > 0 && _dolabQty > 0)
                              const SizedBox(height: 8),
                            if (_dolabQty > 0)
                              _QtyTile(
                                label: l.standing,
                                value: _techFreestandingShare,
                                onChanged: (v) => setState(
                                  () => _techFreestandingShare =
                                      v.clamp(0, _dolabQty),
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 90.ms),
                    ],
                    const SizedBox(height: 20),

                    // ── Date Picker ──
                    _SectionHeader(icon: Icons.calendar_today, title: l.date),
                    const SizedBox(height: 8),
                    ArcticCard(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 30),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: ArcticTheme.arcticBlue,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(l.tapToChange, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),

                    // ── Invoice Details ──
                    _SectionHeader(
                      icon: Icons.receipt_long_rounded,
                      title: l.invoiceDetails,
                    ),
                    const SizedBox(height: 16),
                    companiesAsync
                        .when(
                          data: (companies) => companies.isEmpty
                              ? const SizedBox.shrink()
                              : CompanySelectorField(
                                  companies: companies,
                                  selectedCompanyId: _selectedCompanyId,
                                  includeNoCompanyOption: true,
                                  hintText: l.selectCompany,
                                  onChanged: (selectedCompany) {
                                    setState(() {
                                      _selectedCompanyId = selectedCompany?.id;
                                      _selectedCompanyName =
                                          selectedCompany?.name ?? '';
                                      _selectedCompanyPrefix =
                                          selectedCompany?.invoicePrefix ?? '';
                                    });
                                  },
                                ),
                          loading: () =>
                              const ArcticShimmer(height: 56, count: 1),
                          error: (e, _) => const SizedBox.shrink(),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _invoiceController,
                      textInputAction: TextInputAction.next,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: _selectedCompanyPrefix.isEmpty
                            ? l.invoiceNumber
                            : l.invoiceSuffix,
                        labelText: l.invoiceNumber,
                        prefixIcon: const Icon(
                          Icons.receipt_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l.required : null,
                    ).animate().fadeIn(delay: 120.ms),
                    if (_selectedCompanyPrefix.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l.invoicePrefix}: $_selectedCompanyPrefix',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ArcticTheme.arcticBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientNameController,
                      textInputAction: TextInputAction.next,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: l.clientNameOptional,
                        labelText: l.clientName,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientContactController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      enableInteractiveSelection: true,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+\-\s\(\)]'),
                        ),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        hintText: l.clientPhone,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: ArcticTheme.arcticTextSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l.required;
                        return _normalizeContact(v).isEmpty
                            ? l.enterValidPhone
                            : null;
                      },
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 28),

                    // ── Additional Charges ──
                    _SectionHeader(
                      icon: Icons.attach_money_rounded,
                      title: l.additionalCharges,
                    ),
                    const SizedBox(height: 8),
                    ArcticCard(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l.deliverySubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deliveryAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: _isSharedInstall
                                  ? l.sharedInvoiceDeliveryAmount
                                  : l.deliveryChargeAmount,
                              prefixIcon: const Icon(
                                Icons.payments_outlined,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                              isDense: true,
                            ),
                          ),
                          if (_isSharedInstall) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l.sharedDeliverySplitHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deliveryNoteController,
                            textInputAction: TextInputAction.done,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: l.locationNote,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 32),

                    // ── Submit ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArcticTheme.arcticDarkBg,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? l.submitting : l.submitForApproval,
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildInvoiceNumber() {
    var entered = _invoiceController.text.trim();
    final upper = entered.toUpperCase();
    if (upper.startsWith('INV-')) {
      entered = entered.substring(4).trim();
    } else if (upper.startsWith('INV ')) {
      entered = entered.substring(4).trim();
    }
    if (_selectedCompanyPrefix.isEmpty || entered.isEmpty) return entered;
    final prefix = _selectedCompanyPrefix.trim();
    if (entered.startsWith(prefix)) return entered;
    return '$prefix-$entered';
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ArcticTheme.arcticBlue),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _QtyTile extends StatelessWidget {
  const _QtyTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? ArcticTheme.arcticCard : scheme.surface,
        border: Border.all(
          color: ArcticTheme.arcticBlue.withValues(alpha: isDark ? 0.18 : 0.28),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: textTheme.bodySmall,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: value > 0 ? () => onChanged(value - 1) : null,
            child: Icon(
              Icons.remove_circle_outline,
              size: 20,
              color: value > 0
                  ? ArcticTheme.arcticTextSecondary
                  : ArcticTheme.arcticTextSecondary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: textTheme.titleSmall?.copyWith(
              color: textTheme.titleSmall?.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(value + 1),
            child: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: ArcticTheme.arcticBlue,
            ),
          ),
        ],
      ),
    );
  }
}
