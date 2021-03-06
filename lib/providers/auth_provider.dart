import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/edit_email_response.dart';
import '../models/google_signin_response.dart';
import '../models/password_recovery_response.dart';
import '../models/sign_in_response.dart';
import '../models/sign_up_response.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  String? _email;
  String? _id;

  String? get email => _email;
  String? get id => _id;

  bool hasUser() {
    _id = _auth.currentUser?.uid;
    _email = _auth.currentUser?.email;

    return _id != null;
  }

  Future<void> createAccountInDatabase(UserCredential credential,
      {String? name}) async {
    final profile = credential.additionalUserInfo?.profile;

    _database.collection('users').doc(credential.user!.uid).set({
      'name': profile?['name'] ?? name ?? '',
      'picture': profile!['picture'],
      'my_courses': [],
    });
  }

  Future<SignInResponse> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return SignInResponse(authenticated: false, error: 'user-null');
      }

      _id = credential.user!.uid;
      _email = credential.user!.email;

      return SignInResponse(authenticated: true);
    } on FirebaseAuthException catch (e) {
      return SignInResponse(authenticated: false, error: e.code);
    } catch (e) {
      return SignInResponse(authenticated: false, error: e.toString());
    }
  }

  Future<GoogleSignInResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();

    final account = await googleSignIn.signIn();

    if (account != null) {
      final authentication = await account.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
      );

      try {
        final userCredential = await _auth.signInWithCredential(
          googleCredential,
        );

        if (userCredential.user == null) {
          return GoogleSignInResponse(authenticated: false, error: 'user-null');
        }

        _id = userCredential.user!.uid;
        _email = userCredential.user!.email;

        bool newUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        if (newUser) {
          await createAccountInDatabase(userCredential);
        }

        return GoogleSignInResponse(authenticated: true);
      } on FirebaseAuthException catch (e) {
        return GoogleSignInResponse(authenticated: false, error: e.code);
      } catch (e) {
        return GoogleSignInResponse(authenticated: false, error: e.toString());
      }
    }

    return GoogleSignInResponse(
      authenticated: false,
      error: 'user-cancelled',
    );
  }

  Future<SignUpResponse> signUp(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return SignUpResponse(authenticated: false, error: 'user-null');
      }

      await createAccountInDatabase(credential, name: name);

      return SignUpResponse(authenticated: true);
    } on FirebaseAuthException catch (e) {
      return SignUpResponse(authenticated: false, error: e.code);
    } catch (e) {
      return SignUpResponse(authenticated: false, error: e.toString());
    }
  }

  Future<PasswordRecoveryResponse> sendPasswordRecoveryEmail(
    String email,
  ) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return PasswordRecoveryResponse(sent: true);
    } on FirebaseAuthException catch (e) {
      return PasswordRecoveryResponse(sent: false, error: e.code);
    } catch (e) {
      return PasswordRecoveryResponse(sent: false, error: e.toString());
    }
  }

  Future<EditEmailResponse> editEmail(String email) async {
    try {
      await _auth.currentUser?.updateEmail(email);

      _email = email;

      notifyListeners();

      return EditEmailResponse(edited: true);
    } on FirebaseAuthException catch (e) {
      return EditEmailResponse(edited: false, error: e.code);
    } catch (e) {
      return EditEmailResponse(edited: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();

    _id = null;
    _email = null;
  }
}
