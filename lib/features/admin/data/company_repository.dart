import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(firestore: FirebaseFirestore.instance);
});

class CompanyRepository {
  CompanyRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      firestore.collection(AppConstants.companiesCollection);

  Stream<List<CompanyModel>> allCompanies() {
    return _ref
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(CompanyModel.fromFirestore).toList());
  }

  Stream<List<CompanyModel>> activeCompanies() {
    return _ref
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(CompanyModel.fromFirestore).toList());
  }

  Future<void> createCompany({
    required String name,
    required String invoicePrefix,
  }) async {
    try {
      await _ref.add({
        'name': name,
        'invoicePrefix': invoicePrefix,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> updateCompany({
    required String id,
    required String name,
    required String invoicePrefix,
  }) async {
    try {
      await _ref.doc(id).update({'name': name, 'invoicePrefix': invoicePrefix});
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> toggleCompanyActive(String id, bool isActive) async {
    try {
      await _ref.doc(id).update({'isActive': isActive});
    } catch (_) {
      throw ExpenseException.userSaveFailed();
    }
  }
}
