import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/admin/data/historical_jobs_import_service.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class HistoricalImportScreen extends ConsumerStatefulWidget {
  const HistoricalImportScreen({super.key});

  @override
  ConsumerState<HistoricalImportScreen> createState() =>
      _HistoricalImportScreenState();
}

class _HistoricalImportScreenState
    extends ConsumerState<HistoricalImportScreen> {
  bool _isImporting = false;
  bool _isLoadingTechnicians = true;
  List<UserModel> _technicians = const [];
  UserModel? _selectedTechnician;
  CompanyModel? _selectedCompany;
  final TextEditingController _technicianKeywordController =
      TextEditingController();

  Future<bool> _showImportPreviewDialog(
    List<_PreparedImportBatch> preparedBatches,
  ) async {
    final l = AppLocalizations.of(context)!;
    final totalImportedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.jobs.length,
    );
    final totalSkippedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.skippedRows,
    );
    final totalUnresolvedRows = preparedBatches.fold<int>(
      0,
      (sum, b) => sum + b.parsed.unresolvedTechnicians,
    );

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final maxDialogHeight = MediaQuery.of(dialogContext).size.height * 0.68;
        return AlertDialog(
          title: Text(l.importHistoryData),
          content: SizedBox(
            width: 560,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.importHistoryData,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(l.importCompletedCount(totalImportedRows)),
                    Text(l.importSkippedCount(totalSkippedRows)),
                    Text(l.importUnresolvedTechRows(totalUnresolvedRows)),
                    const SizedBox(height: 12),
                    ...preparedBatches.map((batch) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.fileName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              ...batch.parsed.sheetSummaries.map((sheet) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${sheet.sheetName} • ${l.importCompletedCount(sheet.importedRows)} • ${l.importSkippedCount(sheet.skippedRows)} • ${l.importUnresolvedTechRows(sheet.unresolvedTechnicians)}\n'
                                    'S/W/F: ${sheet.installedSplit}/${sheet.installedWindow}/${sheet.installedFreestanding} • U S/W/F/O: ${sheet.uninstallSplit}/${sheet.uninstallWindow}/${sheet.uninstallFreestanding}/${sheet.uninstallOld}',
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.confirm),
            ),
          ],
        );
      },
    );

    return shouldProceed ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _technicianKeywordController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicians() async {
    try {
      final users = await ref.read(userRepositoryProvider).usersForImport();
      final technicians =
          users
              .where((user) => user.role == AppConstants.roleTechnician)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      if (!mounted) return;
      setState(() {
        _technicians = technicians;
        _selectedTechnician = null;
        _isLoadingTechnicians = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _technicians = const [];
        _selectedTechnician = null;
        _isLoadingTechnicians = false;
      });
    }
  }

  UserModel? _findTechnicianByUid(String? uid) {
    if (uid == null) return null;
    for (final technician in _technicians) {
      if (technician.uid == uid) {
        return technician;
      }
    }
    return null;
  }

  Future<void> _importFiles() async {
    final l = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );

    if (picked == null || picked.files.isEmpty) {
      if (mounted) {
        ErrorSnackbar.show(context, message: l.importNoFileSelected);
      }
      return;
    }

    await _runImport(sources: picked.files);
  }

  Future<void> _runImport({required List<PlatformFile> sources}) async {
    final l = AppLocalizations.of(context)!;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || !currentUser.isAdmin) return;

    final targetTechnician = _selectedTechnician;
    if (targetTechnician == null) {
      ErrorSnackbar.show(context, message: l.importTargetTechnicianRequired);
      return;
    }

    final targetCompany = _selectedCompany;
    if (targetCompany == null) {
      ErrorSnackbar.show(context, message: l.selectCompany);
      return;
    }

    setState(() => _isImporting = true);
    var importedCount = 0;
    var skippedRows = 0;
    var unresolvedTechs = 0;

    try {
      final users = await ref.read(userRepositoryProvider).usersForImport();
      final keyword = _technicianKeywordController.text.trim();
      final preparedBatches = <_PreparedImportBatch>[];

      for (final source in sources) {
        Uint8List? bytes = source.bytes;
        if (bytes == null && source.path != null) {
          bytes = await File(source.path!).readAsBytes();
        }
        if (bytes == null || bytes.isEmpty) continue;

        final parsed = HistoricalJobsImportService.parseExcel(
          bytes: bytes,
          users: users,
          adminUid: currentUser.uid,
          targetUser: targetTechnician,
          targetCompany: targetCompany,
          technicianKeyword: keyword,
        );

        preparedBatches.add(
          _PreparedImportBatch(fileName: source.name, source: source, parsed: parsed),
        );

        bytes = Uint8List(0);
      }

      if (preparedBatches.isEmpty) {
        if (mounted) {
          ErrorSnackbar.show(context, message: l.importFailedNoRows);
        }
        return;
      }

      final shouldProceed = await _showImportPreviewDialog(preparedBatches);
      if (!shouldProceed) {
        return;
      }

      for (final prepared in preparedBatches) {
        final parsed = prepared.parsed;

        if (parsed.jobs.isNotEmpty) {
          importedCount += await ref
              .read(jobRepositoryProvider)
              .importJobs(parsed.jobs);
        }
        skippedRows += parsed.skippedRows;
        unresolvedTechs += parsed.unresolvedTechnicians;

        if (!kIsWeb && prepared.source.path != null) {
          try {
            final sourceFile = File(prepared.source.path!);
            if (await sourceFile.exists()) {
              await sourceFile.delete();
            }
          } catch (_) {
            // Best effort only. Some providers may not allow deletion.
          }
        }
      }

      if (!mounted) return;
      if (importedCount == 0) {
        ErrorSnackbar.show(context, message: l.importFailedNoRows);
      } else {
        SuccessSnackbar.show(
          context,
          message:
              '${l.importCompletedCount(importedCount)} • ${l.importSkippedCount(skippedRows)}',
        );
        if (unresolvedTechs > 0) {
          ErrorSnackbar.show(
            context,
            message: l.importUnresolvedTechRows(unresolvedTechs),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackbar.show(context, message: l.importFailedNoRows);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(activeCompaniesProvider);

    CompanyModel? findCompany(String? id, List<CompanyModel> companies) {
      if (id == null) return null;
      for (final company in companies) {
        if (company.id == id) {
          return company;
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.importHistoryData)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ArcticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.importHistoryData,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.importHistoryDataSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingTechnicians)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    companiesAsync.when(
                      data: (companies) {
                        if (_selectedCompany != null &&
                            findCompany(_selectedCompany!.id, companies) ==
                                null) {
                          _selectedCompany = null;
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCompany?.id,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.company,
                            prefixIcon: const Icon(Icons.business_outlined),
                          ),
                          items: companies.map((company) {
                            return DropdownMenuItem<String>(
                              value: company.id,
                              child: Text(
                                company.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isImporting
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCompany = findCompany(
                                      value,
                                      companies,
                                    );
                                  });
                                },
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTechnician?.uid,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.importTargetTechnician,
                        prefixIcon: const Icon(Icons.engineering_rounded),
                      ),
                      items: _technicians.map((technician) {
                        return DropdownMenuItem<String>(
                          value: technician.uid,
                          child: Text(
                            '${technician.name} • ${technician.email}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isImporting
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTechnician = _findTechnicianByUid(
                                  value,
                                );
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _technicianKeywordController,
                      enabled: !_isImporting,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l.importTechnicianKeyword,
                        hintText: l.importTechnicianKeywordHint,
                        helperText: l.importTechnicianKeywordHelp,
                        prefixIcon: const Icon(Icons.filter_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFiles,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _isImporting ? l.importInProgress : l.uploadExcel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArcticTheme.arcticBlue,
                        foregroundColor: ArcticTheme.arcticDarkBg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparedImportBatch {
  const _PreparedImportBatch({
    required this.fileName,
    required this.source,
    required this.parsed,
  });

  final String fileName;
  final PlatformFile source;
  final HistoricalImportResult parsed;
}
