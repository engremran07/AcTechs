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
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<UserModel>> allUsers() {
    return _usersRef.snapshots().map(
      (snap) => snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
    );
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    try {
      await _usersRef.doc(uid).update({'isActive': isActive});
    } on FirebaseException catch (e) {
      debugPrint('toggleUserActive error: `${e.code} — `${e.message}');
      throw ExpenseException.userSaveFailed();
    }
  }

  Future<void> updateLanguage(String uid, String language) async {
    try {
      await _usersRef.doc(uid).update({'language': language});
    } on FirebaseException catch (e) {
      debugPrint('updateLanguage error: `${e.code} — `${e.message}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Create a new technician user via a secondary Firebase App so the
  /// admin session is preserved (createUserWithEmailAndPassword signs in
  /// as the new user on the primary app).
  Future<void> createTechnician({
    required String name,
    required String email,
    required String password,
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

      // Create the Firestore user document (uses the primary Firestore)
      await _usersRef.doc(uid).set({
        'name': name,
        'email': email,
        'role': AppConstants.roleTechnician,
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
      debugPrint('updateUser error: `${e.code} — `${e.message}');
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
      debugPrint('updateSelfName error: `${e.code} — `${e.message}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Soft-delete: deactivate the user. Firestore rules prevent hard delete.
  Future<void> deactivateUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({'isActive': false});
    } on FirebaseException catch (e) {
      debugPrint('deactivateUser error: `${e.code} — `${e.message}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Bulk toggle active status for a list of user IDs.
  Future<void> bulkToggleActive(List<String> uids, bool isActive) async {
    try {
      final batch = firestore.batch();
      for (final uid in uids) {
        batch.update(_usersRef.doc(uid), {'isActive': isActive});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('bulkToggleActive error: `${e.code} — `${e.message}');
      throw ExpenseException.userSaveFailed();
    }
  }

  /// Send a password reset email — uses Firebase Auth (free, no cloud fn needed).
  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordReset error: `${e.code} — `${e.message}');
      throw const ExpenseException(
        'reset_failed',
        'Could not send reset email. Check the address and try again.',
        'ری سیٹ ای میل نہیں بھیجی جا سکی۔ پتہ چیک کریں اور دوبارہ کوشش کریں۔',
        'تعذر إرسال البريد الإلكتروني لإعادة التعيين. تحقق من العنوان وحاول مرة أخرى.',
      );
    }
  }

  /// Soft-delete: marks user inactive + timestamp.
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('deleteUser error: `${e.code} — `${e.message}');
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
}
