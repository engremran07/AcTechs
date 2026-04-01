import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/admin/data/historical_jobs_import_service.dart';

class HistoricalImportScreen extends ConsumerStatefulWidget {
  const HistoricalImportScreen({super.key});

  @override
  ConsumerState<HistoricalImportScreen> createState() =>
      _HistoricalImportScreenState();
}

class _HistoricalImportScreenState
    extends ConsumerState<HistoricalImportScreen> {
  bool _isImporting = false;
  bool _deleteSourceAfterImport = true;

  Future<void> _importFiles() async {
    final l = AppLocalizations.of(context)!;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || !currentUser.isAdmin) return;

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

    setState(() => _isImporting = true);
    var importedCount = 0;
    var skippedRows = 0;
    var unresolvedTechs = 0;

    try {
      final users = await ref.read(userRepositoryProvider).usersForImport();
      for (final file in picked.files) {
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes == null || bytes.isEmpty) continue;

        final parsed = HistoricalJobsImportService.parseExcel(
          bytes: bytes,
          users: users,
          adminUid: currentUser.uid,
        );

        if (parsed.jobs.isNotEmpty) {
          importedCount += await ref
              .read(jobRepositoryProvider)
              .importJobs(parsed.jobs);
        }
        skippedRows += parsed.skippedRows;
        unresolvedTechs += parsed.unresolvedTechnicians;

        // Clear bytes and remove source file when possible to avoid storage use.
        bytes = Uint8List(0);
        if (_deleteSourceAfterImport && !kIsWeb && file.path != null) {
          try {
            final src = File(file.path!);
            if (await src.exists()) {
              await src.delete();
            }
          } catch (_) {
            // Best effort only; some providers don't allow delete on picked files.
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
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _deleteSourceAfterImport,
                    onChanged: (v) {
                      setState(() => _deleteSourceAfterImport = v);
                    },
                    title: Text(l.deleteSourceAfterImport),
                  ),
                  const SizedBox(height: 12),
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
