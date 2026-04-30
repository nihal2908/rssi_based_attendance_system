import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Signin with Google
  Future<User?> loginWithGoogle() async {
    final Completer<User?> completer = Completer<User?>();

    try {
      if (!_googleSignIn.supportsAuthenticate()) return null;

      await _googleSignIn.initialize(hostedDomain: 'mnnit.ac.in');

      // Subscribe to the stream
      late StreamSubscription subscription;
      subscription = _googleSignIn.authenticationEvents.listen((
        GoogleSignInAuthenticationEvent event,
      ) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          try {
            // Get credentials from the event
            final AuthCredential credential = GoogleAuthProvider.credential(
              idToken: event.user.authentication.idToken,
            );

            // Sign in to Firebase
            final userCred = await _firebaseAuth.signInWithCredential(
              credential,
            );
            final user = userCred.user;

            if (user != null) {
              final firestore = FirebaseFirestore.instance;
              final userDoc = await firestore
                  .collection('students')
                  .doc(user.uid)
                  .get();

              if (!userDoc.exists) {
                final email = event.user.email;
                final parts = email.split('@')[0].split('.');
                final registrationNo = parts.length > 1
                    ? parts.last
                    : 'Unknown';
                await firestore.collection('students').doc(user.uid).set({
                  'id': user.uid,
                  'name': event.user.displayName ?? '',
                  'registration_no': registrationNo,
                  'email': email,
                  'face_id_configured': false,
                  'face_id_request_id': null,
                  'avatar': event.user.photoUrl,
                  'courses_enrolled': [],
                });
              }
              // Complete the future with the user
              completer.complete(user);
            } else {
              completer.complete(null);
            }
          } catch (e) {
            completer.completeError(e);
          } finally {
            subscription.cancel();
          }
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          await _firebaseAuth.signOut();
          if (!completer.isCompleted) completer.complete(null);
          subscription.cancel();
        } else {
          if (!completer.isCompleted) completer.complete(null);
          subscription.cancel();
        }
      });

      // Actually trigger the UI
      await _googleSignIn.authenticate();

      final user = await completer.future;
      subscription.cancel();
      return user;
    } catch (e) {
      return null;
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<User?> register(
    String name,
    String registrationNo,
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('students').doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'name': name,
        'registration_no': registrationNo,
        'email': email,
        'face_id_configured': false,
        'face_id_request_id': null,
        'avatar': null,
        'courses_enrolled': [],
      });
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Check authentication status
  Future<bool> checkAuth() async {
    final user = _firebaseAuth.currentUser;
    return user != null;
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Listen to auth state changes
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
