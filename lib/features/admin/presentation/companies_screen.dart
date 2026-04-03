import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/data/company_repository.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  Future<void> _showCompanyDialog([CompanyModel? company]) async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: company?.name ?? '');
    final prefixCtrl = TextEditingController(
      text: company?.invoicePrefix ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(company == null ? l.addCompany : l.editCompany),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.companyName,
                  prefixIcon: const Icon(Icons.apartment_rounded),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? l.required : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: prefixCtrl,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.invoicePrefix,
                  prefixIcon: const Icon(Icons.tag_rounded),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? l.required : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      if (company == null) {
        await ref
            .read(companyRepositoryProvider)
            .createCompany(
              name: nameCtrl.text.trim(),
              invoicePrefix: prefixCtrl.text.trim(),
            );
        if (!mounted) return;
        AppFeedback.success(context, message: l.companyCreated);
      } else {
        await ref
            .read(companyRepositoryProvider)
            .updateCompany(
              id: company.id,
              name: nameCtrl.text.trim(),
              invoicePrefix: prefixCtrl.text.trim(),
            );
        if (!mounted) return;
        AppFeedback.success(context, message: l.companyUpdated);
      }
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _toggleCompany(CompanyModel company, bool isActive) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(companyRepositoryProvider)
          .toggleCompanyActive(company.id, isActive);
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: isActive ? l.companyActivated : l.companyDeactivated,
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.companies)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCompanyDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(l.addCompany),
      ),
      body: SafeArea(
        child: companiesAsync.when(
          data: (companies) {
            if (companies.isEmpty) {
              return Center(
                child: Text(
                  l.noCompaniesYet,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }

            return ArcticRefreshIndicator(
              onRefresh: () async => ref.invalidate(allCompaniesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: companies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return ArcticCard(
                    onTap: () => _showCompanyDialog(company),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ArcticTheme.arcticBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: ArcticTheme.arcticBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${l.invoicePrefix}: ${company.invoicePrefix}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: company.isActive,
                          activeTrackColor: ArcticTheme.arcticSuccess,
                          onChanged: (value) => _toggleCompany(company, value),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.03);
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: ArcticShimmer(count: 5),
          ),
          error: (error, _) => error is AppException
              ? Center(child: ErrorCard(exception: error))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
