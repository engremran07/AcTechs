import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: FirebaseFirestore.instance);
});

class UserRepository {
  UserRepository({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      firestore.collection(AppConstants.usersCollection);

  Stream<List<UserModel>> allTechnicians() {
    return _usersRef
        .where('role', isEqualTo: 'technician')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<UserModel>> allUsers() {
    return _usersRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Future<List<UserModel>> usersForImport() async {
    try {
      final snap = await _usersRef.get();
      return snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('usersForImport error code: ${e.code}');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    try {
      await _usersRef.doc(uid).update({'isActive': isActive});
    } on FirebaseException catch (e) {
      debugPrint('toggleUserActive error code: ${e.code}');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> updateLanguage(String uid, String language) async {
    try {
      await _usersRef.doc(uid).update({'language': language});
    } on FirebaseException catch (e) {
      debugPrint('updateLanguage error code: ${e.code}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Create a new user (technician or admin) via a secondary Firebase App.
  /// Admin session is preserved since createUserWithEmailAndPassword on a
  /// secondary app doesn't sign out the primary auth context.
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    final appName = 'userCreation_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // Use a secondary Firebase App to avoid signing out the admin
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final normalizedRole = role.trim().toLowerCase() == AppConstants.roleAdmin
          ? AppConstants.roleAdmin
          : AppConstants.roleTechnician;

      // Create the Firestore user document with the specified role
      await _usersRef.doc(uid).set({
        'name': name,
        'email': email,
        'role': normalizedRole,
        'isActive': true,
        'language': 'en',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clean up: sign out from secondary and delete the temp app
      await secondaryAuth.signOut();
      await secondaryApp.delete();
      secondaryApp = null;
    } catch (e) {
      // Always clean up the secondary app
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          throw const JobException(
            'user_exists',
            'A user with this email already exists.',
            'اس ای میل سے پہلے سے ایک صارف موجود ہے۔',
            'يوجد مستخدم بهذا البريد الإلكتروني بالفعل.',
          );
        }
        if (e.code == 'weak-password') {
          throw const JobException(
            'weak_password',
            'Password must be at least 6 characters.',
            'پاس ورڈ کم از کم ۶ حروف کا ہونا چاہیے۔',
            'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
          );
        }
      }
      throw JobException.saveFailed();
    }
  }

  /// Update user name in Firestore (email display only — auth email unchanged).
  Future<void> updateUser({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _usersRef.doc(uid).update({'name': name, 'email': email});
    } on FirebaseException catch (e) {
      debugPrint('updateUser error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_permission',
          'Permission denied. Are you still logged in as admin?',
          'اجازت نہیں ہے۔ کیا آپ ابھی ایڈمن کے طور پر لاگ ان ہیں؟',
          'لا يوجد إذن. هل أنت لا تزال مسجل دخولاً كمسؤول؟',
        );
      }
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Update own display name (any authenticated user).
  Future<void> updateSelfName(String uid, String name) async {
    try {
      await _usersRef.doc(uid).update({'name': name});
    } on FirebaseException catch (e) {
      debugPrint('updateSelfName error code: ${e.code}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Backward-compatibility: technicianonly wrapper for createUser.
  Future<void> createTechnician({
    required String name,
    required String email,
    required String password,
  }) async => createUser(
    name: name,
    email: email,
    password: password,
    role: AppConstants.roleTechnician,
  );

  /// Bulk toggle active status for a list of user IDs.
  Future<void> bulkToggleActive(List<String> uids, bool isActive) async {
    try {
      final batch = firestore.batch();
      for (final uid in uids) {
        batch.update(_usersRef.doc(uid), {'isActive': isActive});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('bulkToggleActive error code: ${e.code}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Send a password reset email — uses Firebase Auth (free, no cloud fn needed).
  ///
  /// [ActionCodeSettings] configure the deep-link so Android can offer to
  /// reopen the app after the user resets their password in the browser, and
  /// the continue URL gives users a clear landing page post-reset.
  Future<void> sendPasswordReset(String email) async {
    try {
      final settings = ActionCodeSettings(
        url: 'https://actechs-d415e.web.app',
        handleCodeInApp: false,
        androidPackageName: 'com.actechs.ac_techs',
        androidInstallApp: false,
        // Match app minimum supported Android API level.
        androidMinimumVersion: '29',
      );
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordReset error code: ${e.code}');
      if (e.code == 'network-request-failed') {
        throw AuthException.resetNetworkError();
      }
      if (e.code == 'too-many-requests') {
        throw AuthException.resetRateLimit();
      }
      throw AuthException.resetFailed();
    }
  }

  /// Delete user by marking as inactive in Firestore (soft-delete).
  /// - Sign-in is blocked via isActive check in auth_repository.dart
  /// - User will not appear in team list (filtered by isActive=true)
  /// - Firebase Auth account deletion requires Admin SDK (Cloud Functions).
  ///   For free tier: Auth account persists but cannot log in. For full cleanup
  ///   use Firebase Console to delete Auth or deploy Cloud Function.
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('deleteUser error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_permission',
          'Permission denied. Are you still logged in as admin?',
          'اجازت نہیں ہے۔ کیا آپ ابھی ایڈمن کے طور پر لاگ ان ہیں؟',
          'لا يوجد إذن. هل أنت لا تزال مسجل دخولاً كمسؤول؟',
        );
      }
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Verify admin password by re-authenticating with Firebase Auth.
  /// Throws [AdminException.wrongPassword] on bad password.
  Future<void> verifyAdminPassword(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw AdminException.noPermission();
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on AdminException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyAdminPassword error code: ${e.code}');
      throw AdminException.wrongPassword();
    } catch (_) {
      throw AdminException.wrongPassword();
    }
  }

  /// Flush the database: deletes all jobs, expenses, earnings, companies and
  /// soft-deletes all non-admin users. Admin documents are preserved.
  Future<void> flushDatabase() async {
    try {
      // Delete all operational collections in chunks (batch limit = 500).
      for (final collection in [
        AppConstants.jobsCollection,
        AppConstants.expensesCollection,
        AppConstants.earningsCollection,
        AppConstants.companiesCollection,
      ]) {
        await _deleteCollectionInChunks(collection);
      }

      // Soft-delete non-admin users (keep admin accounts intact).
      final usersSnap = await _usersRef.get();
      if (usersSnap.docs.isNotEmpty) {
        final batch = firestore.batch();
        for (final doc in usersSnap.docs) {
          final role =
              doc.data()['role'] as String? ?? AppConstants.roleTechnician;
          if (role != AppConstants.roleAdmin) {
            batch.update(doc.reference, {
              'isActive': false,
              'deletedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      debugPrint('flushDatabase error code: ${e.code}');
      if (e.code == 'permission-denied') {
        throw const AdminException(
          'admin_flush_permission_denied',
          'Database flush is blocked by security rules. Contact admin support.',
          'ڈیٹا بیس فلش سیکیورٹی رولز کی وجہ سے بلاک ہے۔ ایڈمن سپورٹ سے رابطہ کریں۔',
          'تم حظر مسح قاعدة البيانات بواسطة قواعد الأمان. تواصل مع دعم المسؤول.',
        );
      }
      throw AdminException.flushFailed();
    }
  }

  /// Deletes all documents in [collectionName] in chunks of 400.
  Future<void> _deleteCollectionInChunks(String collectionName) async {
    const chunkSize = 400;
    while (true) {
      final snap = await firestore
          .collection(collectionName)
          .limit(chunkSize)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
