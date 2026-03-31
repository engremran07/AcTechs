import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/admin/data/company_repository.dart';

final allCompaniesProvider = StreamProvider<List<CompanyModel>>((ref) {
  return ref.watch(companyRepositoryProvider).allCompanies();
});

final activeCompaniesProvider = StreamProvider<List<CompanyModel>>((ref) {
  return ref.watch(companyRepositoryProvider).activeCompanies();
});
