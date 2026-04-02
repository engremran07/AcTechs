import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/constants/app_constants.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  AuthRepository({required this.auth, required this.firestore});

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Stream<User?> get authStateChanges => auth.userChanges().asyncMap((user) async {
    if (user != null) {
      await _syncProfileFromAuth(user);
    }
    return user;
  });

  User? get currentUser => auth.currentUser;

  Future<void> _syncProfileFromAuth(User user) async {
    try {
      final userDocRef = firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid);
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) return;

      final data = userDoc.data() ?? {};
      final updates = <String, dynamic>{};
      final authEmail = (user.email ?? '').trim();
      final authDisplayName = (user.displayName ?? '').trim();

      if (authEmail.isNotEmpty && data['email'] != authEmail) {
        updates['email'] = authEmail;
      }
      if (authDisplayName.isNotEmpty && data['name'] != authDisplayName) {
        updates['name'] = authDisplayName;
      }

      if (updates.isNotEmpty) {
        await userDocRef.update(updates);
      }
    } on FirebaseException catch (e) {
      debugPrint('profile sync Firestore error: ${e.code} — ${e.message}');
    } catch (e) {
      debugPrint('profile sync unknown error: $e');
    }
  }

  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final userDocRef = firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);
      var userDoc = await userDocRef.get();
      final authEmail = credential.user!.email ?? '';
      final authDisplayName = credential.user!.displayName;

      if (!userDoc.exists) {
        await auth.signOut();
        throw AuthException.accountNotProvisioned();
      } else {
        await _syncProfileFromAuth(credential.user!);
        userDoc = await userDocRef.get();
        // Sync Firebase Auth changes to Firestore (e.g., email or displayName
        // changed in the Firebase Console will now reflect in the app).
        final data = userDoc.data() ?? {};
        final Map<String, dynamic> updates = {};
        final rawRole = (data['role'] as String? ?? '').trim().toLowerCase();
        final normalizedRole = rawRole == 'admin' || rawRole == 'administrator'
            ? AppConstants.roleAdmin
            : AppConstants.roleTechnician;

        if (authEmail.isNotEmpty && data['email'] != authEmail) {
          updates['email'] = authEmail;
        }
        if (authDisplayName != null &&
            authDisplayName.isNotEmpty &&
            data['name'] != authDisplayName) {
          updates['name'] = authDisplayName;
        }
        if (data['role'] != normalizedRole) {
          updates['role'] = normalizedRole;
        }
        if (updates.isNotEmpty) {
          await userDocRef.update(updates);
          userDoc = await userDocRef.get();
        }
      }

      final user = UserModel.fromFirestore(userDoc);

      if (!user.isActive) {
        await auth.signOut();
        throw AuthException.accountDisabled();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } on FirebaseException catch (e) {
      // If user profile document cannot be read (for example permission denied
      // or doc path mismatch), force sign-out to avoid auth/profile drift.
      await auth.signOut();
      debugPrint('signIn Firestore error: ${e.code} — ${e.message}');
      if (e.code == 'permission-denied') {
        throw AuthException.accountNotProvisioned();
      }
      if (e.code == 'unavailable') {
        throw NetworkException.offline();
      }
      throw AuthException.wrongCredentials();
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException.wrongCredentials();
    }
  }

  /// Update the current user's display name in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String name) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;
      // Update Firebase Auth displayName
      await user.updateDisplayName(name);
      // Update Firestore
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'name': name});
    } on FirebaseException catch (e) {
      debugPrint('updateDisplayName error: ${e.code} — ${e.message}');
      throw AuthException.updateFailed();
    }
  }

  Future<void> _reauthenticateWithPassword(String currentPassword) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException.sessionExpired();
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw AuthException.wrongCredentials();
      }
      if (e.code == 'too-many-requests') {
        throw AuthException.tooManyAttempts();
      }
      throw AuthException.updateFailed();
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    try {
      await _reauthenticateWithPassword(currentPassword);
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();

      await user.verifyBeforeUpdateEmail(newEmail);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') throw AuthException.invalidEmail();
      if (e.code == 'email-already-in-use') {
        throw AuthException.emailAlreadyInUse();
      }
      if (e.code == 'requires-recent-login') {
        throw AuthException.recentLoginRequired();
      }
      if (e.code == 'network-request-failed') {
        throw NetworkException.offline();
      }
      throw AuthException.updateFailed();
    } on FirebaseException {
      throw AuthException.updateFailed();
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _reauthenticateWithPassword(currentPassword);
      final user = auth.currentUser;
      if (user == null) throw AuthException.sessionExpired();

      await user.updatePassword(newPassword);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw AuthException.weakPassword();
      if (e.code == 'requires-recent-login') {
        throw AuthException.recentLoginRequired();
      }
      if (e.code == 'network-request-failed') {
        throw NetworkException.offline();
      }
      throw AuthException.updateFailed();
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
    // NOTE: We do NOT call firestore.terminate() / clearPersistence() here.
    // Doing so kills the singleton Firestore instance, breaking all
    // subsequent Firestore operations after re-login. Instead, provider
    // invalidation in SignInNotifier ensures data isolation between sessions.
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = auth.currentUser;
    if (user == null) return null;

    final doc = await firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    final controller = StreamController<UserModel?>();
    final sub = firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            controller.add(doc.exists ? UserModel.fromFirestore(doc) : null);
          },
          onError: (error, stackTrace) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              debugPrint('userStream permission denied for uid=$uid');
              controller.add(null);
              return;
            }
            controller.addError(error, stackTrace);
          },
        );

    controller.onCancel = () async {
      await sub.cancel();
    };

    return controller.stream;
  }
}
