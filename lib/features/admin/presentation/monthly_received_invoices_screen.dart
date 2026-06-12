import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

List<String> _parseInvoiceSheet(Uint8List bytes) {
  final workbook = excel_pkg.Excel.decodeBytes(bytes);
  if (workbook.tables.isEmpty) return [];

  final rows = workbook.tables.values.first.rows;
  if (rows.length < 2) return [];

  final header = rows.first;
  var invoiceCol = 0;
  for (var i = 0; i < header.length; i++) {
    final value = header[i]?.value?.toString().toLowerCase() ?? '';
    if (value.contains('invoice') || value.contains('inv')) {
      invoiceCol = i;
      break;
    }
  }

  final invoices = <String>[];
  for (final row in rows.skip(1)) {
    if (invoiceCol >= row.length) continue;
    final raw = row[invoiceCol]?.value?.toString().trim() ?? '';
    if (raw.isEmpty) continue;
    final normalized = InvoiceUtils.normalize(raw);
    if (normalized.isNotEmpty) invoices.add(normalized);
  }
  return invoices;
}

class MonthlyReceivedInvoicesScreen extends ConsumerStatefulWidget {
  const MonthlyReceivedInvoicesScreen({super.key});

  @override
  ConsumerState<MonthlyReceivedInvoicesScreen> createState() =>
      _MonthlyReceivedInvoicesScreenState();
}

class _MonthlyReceivedInvoicesScreenState
    extends ConsumerState<MonthlyReceivedInvoicesScreen> {
  CompanyModel? _selectedCompany;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _fileName;
  _MonthlyIntakeResult? _result;
  bool _loading = false;

  void _showError(String message) {
    AppFeedback.error(context, message: message);
  }

  Future<void> _runIntake() async {
    final l = AppLocalizations.of(context)!;
    final company = _selectedCompany;
    if (company == null) {
      _showError(l.selectCompany);
      return;
    }

    if (!mounted) return;

    final picked = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );
    if (picked == null || picked.files.isEmpty || picked.files.first.bytes == null) {
      _showError(l.importNoFileSelected);
      return;
    }

    setState(() {
      _loading = true;
      _fileName = picked.files.first.name;
      _result = null;
    });

    try {
      if (!mounted) return;
      final parsed = await compute(_parseInvoiceSheet, picked.files.first.bytes!);
      final normalizedUploaded = parsed
          .map((inv) => InvoiceUtils.normalizeWithCompanyPrefix(inv, companyPrefix: company.invoicePrefix).toLowerCase())
          .toSet();

      final repo = ref.read(jobRepositoryProvider);
      final companyClaims = await repo.fetchInvoiceClaimsForCompany(
        company.id,
        month: _selectedMonth,
      );

      final matched = <String>[];
      final missing = <String>[];
      final claimInvoices = <String>{};
      for (final claim in companyClaims) {
        final normalized = InvoiceUtils.normalizeWithCompanyPrefix(
          claim.invoiceNumber,
          companyPrefix: company.invoicePrefix,
        ).toLowerCase();
        claimInvoices.add(normalized);
        if (normalizedUploaded.contains(normalized)) {
          matched.add(claim.invoiceNumber);
        } else {
          missing.add(claim.invoiceNumber);
        }
      }
      final extraInvoices = normalizedUploaded
          .where((invoice) => !claimInvoices.contains(invoice))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _result = _MonthlyIntakeResult(
          uploadedCount: parsed.length,
          claimCount: companyClaims.length,
          matchedInvoices: matched,
          missingInvoices: missing,
          extraInvoices: extraInvoices,
          uploadedInvoices: parsed,
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('${l.reconciliation} • ${l.selectMonth}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          companiesAsync.when(
            data: (companies) => DropdownButtonFormField<CompanyModel>(
              initialValue: _selectedCompany,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.companyName,
                border: const OutlineInputBorder(),
              ),
              hint: Text(l.selectCompany),
              items: companies
                  .where((company) => company.isActive)
                  .map((company) => DropdownMenuItem(value: company, child: Text(company.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompany = value;
                  _result = null;
                  _fileName = null;
                });
              },
            ),
            loading: () => const ArcticShimmer(height: 56, count: 1),
            error: (error, _) => ErrorCard(
              exception: error is AppException ? error : NetworkException.syncFailed(),
            ),
          ),
          const SizedBox(height: 16),
          ArcticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.selectMonth, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(DateTime.now().year - 3, 1, 1),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked == null) return;
                    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(AppFormatters.monthLabel(l, _selectedMonth)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _runIntake,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(l.uploadCompanyReport),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 8),
            Text(_fileName!, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            ArcticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.reconciliation, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('${l.totalJobs}: ${_result!.claimCount}'),
                  Text('Uploaded: ${_result!.uploadedCount}'),
                  Text('Matched: ${_result!.matchedInvoices.length}'),
                  Text('Missing: ${_result!.missingInvoices.length}'),
                  Text('Extra: ${_result!.extraInvoices.length}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ResultBlock(
              title: '${l.matchedInvoices} (${_result!.matchedInvoices.length})',
              color: ArcticTheme.arcticSuccess,
              items: _result!.matchedInvoices,
            ),
            const SizedBox(height: 12),
            _ResultBlock(
              title: '${l.unmatchedInvoices} (${_result!.missingInvoices.length})',
              color: ArcticTheme.arcticWarning,
              items: _result!.missingInvoices,
            ),
            const SizedBox(height: 12),
            _ResultBlock(
              title: 'Extra in upload (${_result!.extraInvoices.length})',
              color: ArcticTheme.arcticError,
              items: _result!.extraInvoices,
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthlyIntakeResult {
  const _MonthlyIntakeResult({
    required this.uploadedCount,
    required this.claimCount,
    required this.matchedInvoices,
    required this.missingInvoices,
    required this.extraInvoices,
    required this.uploadedInvoices,
  });

  final int uploadedCount;
  final int claimCount;
  final List<String> matchedInvoices;
  final List<String> missingInvoices;
  final List<String> extraInvoices;
  final List<String> uploadedInvoices;
}

class _ResultBlock extends StatelessWidget {
  const _ResultBlock({
    required this.title,
    required this.color,
    required this.items,
  });

  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('—')
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ArcticCard(child: Text(item)),
            ),
          ),
      ],
    );
  }
}