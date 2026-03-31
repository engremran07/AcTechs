import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/category_translator.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';

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
  final _bracketAmountController = TextEditingController();
  final _deliveryAmountController = TextEditingController();
  final _deliveryNoteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<AcUnit> _acUnits = [const AcUnit(type: 'Split AC', quantity: 1)];
  bool _isSubmitting = false;
  bool _hasBracket = false;
  bool _hasDelivery = false;
  String? _selectedCompanyId;
  String _selectedCompanyName = '';
  String _selectedCompanyPrefix = '';

  @override
  void dispose() {
    _invoiceController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _bracketAmountController.dispose();
    _deliveryAmountController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  void _addUnit() {
    setState(() {
      _acUnits.add(const AcUnit(type: 'Split AC', quantity: 1));
    });
  }

  void _removeUnit(int index) {
    if (_acUnits.length > 1) {
      setState(() => _acUnits.removeAt(index));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _invoiceController.clear();
    _clientNameController.clear();
    _clientContactController.clear();
    _bracketAmountController.clear();
    _deliveryAmountController.clear();
    _deliveryNoteController.clear();
    setState(() {
      _acUnits
        ..clear()
        ..add(const AcUnit(type: 'Split AC', quantity: 1));
      _hasBracket = false;
      _hasDelivery = false;
      _selectedCompanyId = null;
      _selectedCompanyName = '';
      _selectedCompanyPrefix = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_acUnits.isEmpty) {
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.addServiceFirst,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final charges = InvoiceCharges(
        acBracket: _hasBracket,
        bracketAmount:
            double.tryParse(_bracketAmountController.text.trim()) ?? 0,
        deliveryCharge: _hasDelivery,
        deliveryAmount:
            double.tryParse(_deliveryAmountController.text.trim()) ?? 0,
        deliveryNote: _deliveryNoteController.text.trim(),
      );

      final job = JobModel(
        techId: user.uid,
        techName: user.name,
        companyId: _selectedCompanyId ?? '',
        companyName: _selectedCompanyName,
        invoiceNumber: _buildInvoiceNumber(),
        clientName: _clientNameController.text.trim(),
        clientContact: _clientContactController.text.trim(),
        acUnits: List.from(_acUnits),
        charges: charges,
        date: _selectedDate,
        submittedAt: DateTime.now(),
        status: JobStatus.pending,
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
          child: FormFocusTraversal(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  const SizedBox(height: 8),
                  companiesAsync
                      .when(
                        data: (companies) => companies.isEmpty
                            ? const SizedBox.shrink()
                            : DropdownButtonFormField<String>(
                                initialValue: _selectedCompanyId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: l.selectCompany,
                                  prefixIcon: Icon(
                                    Icons.apartment_rounded,
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                      l.noCompany,
                                      style: TextStyle(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                    ),
                                  ),
                                  ...companies.map(
                                    (company) => DropdownMenuItem(
                                      value: company.id,
                                      child: Text(company.name),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  CompanyModel? selectedCompany;
                                  for (final company in companies) {
                                    if (company.id == value) {
                                      selectedCompany = company;
                                      break;
                                    }
                                  }
                                  setState(() {
                                    _selectedCompanyId = value?.isEmpty ?? true
                                        ? null
                                        : value;
                                    _selectedCompanyName =
                                        selectedCompany?.name ?? '';
                                    _selectedCompanyPrefix =
                                        selectedCompany?.invoicePrefix ?? '';
                                  });
                                },
                                // Company selection is optional
                              ),
                        loading: () =>
                            const ArcticShimmer(height: 56, count: 1),
                        error: (_, __) => const SizedBox.shrink(),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _invoiceController,
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: _selectedCompanyPrefix.isEmpty
                          ? l.invoiceNumber
                          : l.invoiceSuffix,
                      prefixIcon: Icon(
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
                    const SizedBox(height: 4),
                  ],
                  TextFormField(
                    controller: _clientNameController,
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.clientNameOptional,
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientContactController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.clientPhone,
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: ArcticTheme.arcticTextSecondary,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.required : null,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),

                  // ── AC Services ──
                  Row(
                    children: [
                      _SectionHeader(
                        icon: Icons.ac_unit_rounded,
                        title: l.acServices,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addUnit,
                        icon: const Icon(Icons.add_circle_rounded, size: 20),
                        label: Text(l.add),
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 8),

                  ...List.generate(_acUnits.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ArcticTheme.arcticCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey('ac_type_$i'),
                              initialValue: _acUnits[i].type,
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: l.serviceType,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              items: AppConstants.acUnitTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        translateCategory(t, l),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _acUnits[i] = _acUnits[i].copyWith(type: v);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _acUnits[i].quantity > 1
                                    ? () {
                                        setState(() {
                                          _acUnits[i] = _acUnits[i].copyWith(
                                            quantity: _acUnits[i].quantity - 1,
                                          );
                                        });
                                      }
                                    : null,
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                  color: _acUnits[i].quantity > 1
                                      ? ArcticTheme.arcticTextSecondary
                                      : ArcticTheme.arcticTextSecondary
                                            .withValues(alpha: 0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '${_acUnits[i].quantity}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _acUnits[i] = _acUnits[i].copyWith(
                                      quantity: _acUnits[i].quantity + 1,
                                    );
                                  });
                                },
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  size: 22,
                                  color: ArcticTheme.arcticBlue,
                                ),
                              ),
                            ],
                          ),
                          if (_acUnits.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: ArcticTheme.arcticError,
                                size: 20,
                              ),
                              onPressed: () => _removeUnit(i),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── Additional Charges ──
                  _SectionHeader(
                    icon: Icons.attach_money_rounded,
                    title: l.additionalCharges,
                  ),
                  const SizedBox(height: 8),
                  ArcticCard(
                    child: Column(
                      children: [
                        // AC Bracket
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.acOutdoorBracket),
                          subtitle: Text(l.bracketSubtitle),
                          secondary: const Icon(
                            Icons.handyman_outlined,
                            color: ArcticTheme.arcticBlue,
                          ),
                          value: _hasBracket,
                          onChanged: (v) => setState(() => _hasBracket = v),
                        ),
                        if (_hasBracket) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bracketAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: l.bracketCharge,
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
                        const Divider(height: 24),
                        // Delivery Charge
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.deliveryCharge),
                          subtitle: Text(l.deliverySubtitle),
                          secondary: const Icon(
                            Icons.local_shipping_outlined,
                            color: ArcticTheme.arcticBlue,
                          ),
                          value: _hasDelivery,
                          onChanged: (v) => setState(() => _hasDelivery = v),
                        ),
                        if (_hasDelivery) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deliveryAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: l.deliveryChargeAmount,
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deliveryNoteController,
                            textInputAction: TextInputAction.done,
                            enableInteractiveSelection: true,
                            decoration: InputDecoration(
                              hintText: l.locationNote,
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: ArcticTheme.arcticTextSecondary,
                              ),
                              isDense: true,
                            ),
                          ),
                        ],
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
    );
  }

  String _buildInvoiceNumber() {
    final entered = _invoiceController.text.trim();
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
