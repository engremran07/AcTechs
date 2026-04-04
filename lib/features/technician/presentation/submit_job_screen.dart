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
  int _sharedSplitUnits = 0;
  int _sharedWindowUnits = 0;
  int _sharedFreestandingUnits = 0;
  int _sharedBracketQty = 0;
  int _sharedTeamSize = 0;
  int _techSplitShare = 0;
  int _techWindowShare = 0;
  int _techFreestandingShare = 0;
  int _techBracketShare = 0;
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
    super.dispose();
  }

  int get _effectiveBracketQty =>
      _isSharedInstall ? _techBracketShare : _bracketQty;

  int _clampShare(int nextValue, int invoiceTotal) {
    return nextValue.clamp(0, invoiceTotal < 0 ? 0 : invoiceTotal);
  }

  List<AcUnit> _unitsFromQuickTemplate() {
    final units = <AcUnit>[];
    final splitQty = _isSharedInstall ? _techSplitShare : _splitQty;
    final windowQty = _isSharedInstall ? _techWindowShare : _windowQty;
    final dolabQty = _isSharedInstall ? _techFreestandingShare : _dolabQty;
    if (splitQty > 0) {
      units.add(AcUnit(type: 'Split AC', quantity: splitQty));
    }
    if (windowQty > 0) {
      units.add(AcUnit(type: 'Window AC', quantity: windowQty));
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
    if (dolabQty > 0) {
      units.add(AcUnit(type: 'Freestanding AC', quantity: dolabQty));
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
    setState(() {
      _bracketQty = 0;
      _splitQty = 0;
      _windowQty = 0;
      _uninstallSplitQty = 0;
      _uninstallWindowQty = 0;
      _uninstallStandingQty = 0;
      _dolabQty = 0;
      _isSharedInstall = false;
      _sharedSplitUnits = 0;
      _sharedWindowUnits = 0;
      _sharedFreestandingUnits = 0;
      _sharedBracketQty = 0;
      _sharedTeamSize = 0;
      _techSplitShare = 0;
      _techWindowShare = 0;
      _techFreestandingShare = 0;
      _techBracketShare = 0;
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
      AppFeedback.error(
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
          AppFeedback.error(
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
      if (_isSharedInstall &&
          ((_techSplitShare > 0 && _techSplitShare > _sharedSplitUnits) ||
              (_techWindowShare > 0 && _techWindowShare > _sharedWindowUnits) ||
              (_techFreestandingShare > 0 &&
                  _techFreestandingShare > _sharedFreestandingUnits) ||
              (_techBracketShare > 0 &&
                  _techBracketShare > _sharedBracketQty))) {
        if (mounted) {
          AppFeedback.error(context, message: l.sharedInstallLimitError);
        }
        return;
      }

      final rawDeliveryAmount =
          double.tryParse(_deliveryAmountController.text.trim()) ?? 0;
      if (_isSharedInstall && rawDeliveryAmount > 0 && _sharedTeamSize <= 0) {
        if (mounted) {
          AppFeedback.error(context, message: l.sharedDeliverySplitInvalid);
        }
        return;
      }
      final deliveryAmount = _isSharedInstall && rawDeliveryAmount > 0
          ? rawDeliveryAmount / _sharedTeamSize
          : rawDeliveryAmount;

      final charges = InvoiceCharges(
        acBracket: _effectiveBracketQty > 0,
        bracketCount: _effectiveBracketQty,
        bracketAmount: 0,
        deliveryAmount: deliveryAmount,
        deliveryCharge: deliveryAmount > 0,
        deliveryNote: _deliveryNoteController.text.trim(),
      );

      final normalizedInvoice = _buildInvoiceNumber();
      final sharedGroupKey = _isSharedInstall
          ? '${(_selectedCompanyId ?? 'no-company')}-${normalizedInvoice.toLowerCase()}'
          : '';

      final sharedContributionUnits = _isSharedInstall
          ? _techSplitShare + _techWindowShare + _techFreestandingShare
          : _splitQty + _windowQty + _dolabQty;
      final sharedInvoiceTotalUnits =
          _sharedSplitUnits + _sharedWindowUnits + _sharedFreestandingUnits;
      final requiresApproval =
          ((_isSharedInstall
              ? approvalConfig?.sharedJobApprovalRequired
              : approvalConfig?.jobApprovalRequired) ??
          false);
      final status = requiresApproval ? JobStatus.pending : JobStatus.approved;

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
        sharedInvoiceSplitUnits: _isSharedInstall ? _sharedSplitUnits : 0,
        sharedInvoiceWindowUnits: _isSharedInstall ? _sharedWindowUnits : 0,
        sharedInvoiceFreestandingUnits: _isSharedInstall
            ? _sharedFreestandingUnits
            : 0,
        sharedInvoiceBracketCount: _isSharedInstall ? _sharedBracketQty : 0,
        sharedDeliveryTeamCount: _isSharedInstall ? _sharedTeamSize : 0,
        sharedInvoiceDeliveryAmount: _isSharedInstall ? rawDeliveryAmount : 0,
        techSplitShare: _techSplitShare,
        techWindowShare: _techWindowShare,
        techFreestandingShare: _techFreestandingShare,
        techBracketShare: _techBracketShare,
        charges: charges,
        date: _selectedDate,
        submittedAt: DateTime.now(),
        status: status,
      );

      await ref.read(jobRepositoryProvider).submitJob(job);

      if (mounted) {
        AppFeedback.success(
          context,
          message: status == JobStatus.pending ? l.jobSubmitted : l.jobSaved,
        );
        _resetForm();
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
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
    final approvalConfig = ref.watch(approvalConfigProvider).value;
    final requiresApproval =
        ((_isSharedInstall
            ? approvalConfig?.sharedJobApprovalRequired
            : approvalConfig?.jobApprovalRequired) ??
        false);

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
                            onChanged: (value) => setState(() {
                              _isSharedInstall = value;
                              if (!value) {
                                _sharedSplitUnits = 0;
                                _sharedWindowUnits = 0;
                                _sharedFreestandingUnits = 0;
                                _sharedBracketQty = 0;
                                _sharedTeamSize = 0;
                                _techSplitShare = 0;
                                _techWindowShare = 0;
                                _techFreestandingShare = 0;
                                _techBracketShare = 0;
                              }
                            }),
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
                            _SharedInstallTypeRow(
                              title: l.splitAcLabel,
                              totalValue: _sharedSplitUnits,
                              shareValue: _techSplitShare,
                              onTotalChanged: (value) => setState(() {
                                _sharedSplitUnits = value;
                                _techSplitShare = _clampShare(
                                  _techSplitShare,
                                  _sharedSplitUnits,
                                );
                              }),
                              onShareChanged: (value) => setState(() {
                                _techSplitShare = _clampShare(
                                  value,
                                  _sharedSplitUnits,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            _SharedInstallTypeRow(
                              title: l.windowAcLabel,
                              totalValue: _sharedWindowUnits,
                              shareValue: _techWindowShare,
                              onTotalChanged: (value) => setState(() {
                                _sharedWindowUnits = value;
                                _techWindowShare = _clampShare(
                                  _techWindowShare,
                                  _sharedWindowUnits,
                                );
                              }),
                              onShareChanged: (value) => setState(() {
                                _techWindowShare = _clampShare(
                                  value,
                                  _sharedWindowUnits,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            _SharedInstallTypeRow(
                              title: l.freestandingAcLabel,
                              totalValue: _sharedFreestandingUnits,
                              shareValue: _techFreestandingShare,
                              onTotalChanged: (value) => setState(() {
                                _sharedFreestandingUnits = value;
                                _techFreestandingShare = _clampShare(
                                  _techFreestandingShare,
                                  _sharedFreestandingUnits,
                                );
                              }),
                              onShareChanged: (value) => setState(() {
                                _techFreestandingShare = _clampShare(
                                  value,
                                  _sharedFreestandingUnits,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            _SharedInstallTypeRow(
                              title: l.acOutdoorBracket,
                              totalValue: _sharedBracketQty,
                              shareValue: _techBracketShare,
                              onTotalChanged: (value) => setState(() {
                                _sharedBracketQty = value;
                                _techBracketShare = _clampShare(
                                  _techBracketShare,
                                  _sharedBracketQty,
                                );
                              }),
                              onShareChanged: (value) => setState(() {
                                _techBracketShare = _clampShare(
                                  value,
                                  _sharedBracketQty,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _QtyTile(
                                    label: l.sharedTeamSize,
                                    value: _sharedTeamSize,
                                    onChanged: (value) =>
                                        setState(() => _sharedTeamSize = value),
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (!_isSharedInstall) ...[
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
                          ],
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
                          _isSubmitting
                              ? l.submitting
                              : (requiresApproval
                                    ? l.submitForApproval
                                    : l.submit),
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

  Future<void> _showManualQuantityDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '$value');

    final nextValue = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l.quantity),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                AppFeedback.error(dialogContext, message: l.enterValidQuantity);
                return;
              }
              Navigator.of(dialogContext).pop(parsed);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    controller.dispose();

    if (nextValue != null) {
      onChanged(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showManualQuantityDialog(context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? ArcticTheme.arcticCard : scheme.surface,
            border: Border.all(
              color: ArcticTheme.arcticBlue.withValues(
                alpha: isDark ? 0.18 : 0.28,
              ),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                  onPressed: value > 0 ? () => onChanged(value - 1) : null,
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 28,
                    color: value > 0
                        ? ArcticTheme.arcticTextSecondary
                        : ArcticTheme.arcticTextSecondary.withValues(
                            alpha: 0.3,
                          ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showManualQuantityDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    '$value',
                    style: textTheme.titleMedium?.copyWith(
                      color: textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                  onPressed: () => onChanged(value + 1),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 28,
                    color: ArcticTheme.arcticBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SharedInstallTypeRow extends StatelessWidget {
  const _SharedInstallTypeRow({
    required this.title,
    required this.totalValue,
    required this.shareValue,
    required this.onTotalChanged,
    required this.onShareChanged,
  });

  final String title;
  final int totalValue;
  final int shareValue;
  final ValueChanged<int> onTotalChanged;
  final ValueChanged<int> onShareChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QtyTile(
                label: l.totalOnInvoice,
                value: totalValue,
                onChanged: onTotalChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QtyTile(
                label: l.myShare,
                value: shareValue,
                onChanged: onShareChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
