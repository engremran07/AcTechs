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

  Stream<User?> get authStateChanges => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

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

      // Auto-create Firestore doc for users created via Firebase Console
      if (!userDoc.exists) {
        await userDocRef.set({
          'name': credential.user!.displayName ?? email.split('@')[0],
          'email': email,
          'role': AppConstants.roleTechnician,
          'isActive': true,
          'language': 'en',
          'createdAt': FieldValue.serverTimestamp(),
          'autoCreated': true,
        });
        userDoc = await userDocRef.get();
      } else {
        // Sync Firebase Auth changes to Firestore (e.g., email or displayName
        // changed in the Firebase Console will now reflect in the app).
        final authEmail = credential.user!.email ?? '';
        final authDisplayName = credential.user!.displayName;
        final data = userDoc.data() ?? {};
        final Map<String, dynamic> updates = {};

        if (authEmail.isNotEmpty && data['email'] != authEmail) {
          updates['email'] = authEmail;
        }
        if (authDisplayName != null &&
            authDisplayName.isNotEmpty &&
            data['name'] != authDisplayName) {
          updates['name'] = authDisplayName;
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
    return firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
