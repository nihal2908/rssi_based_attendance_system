import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dependency_injection.dart';
import '../models/student.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Student? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Student? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthController() : _authService = sl<AuthService>() {
    _authService.authStateChanges().listen((User? newUser) {
      _user = newUser;
      if (newUser == null) {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> register({
    required String name,
    required String registrationNo,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.register(name, registrationNo, email, password);
      _user = _authService.getCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Registration failed.';
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.login(email, password);
      _user = _authService.getCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed.';
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUserData() async {
    if (_user == null || _currentUser != null) return;

    _setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('students')
          .doc(_user!.uid)
          .get();

      if (snapshot.exists) {
        _currentUser = Student.fromFirestore(snapshot);
      } else {
        _errorMessage = "Student profile not found.";
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch user data.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    clearError();
    try {
      await _authService.logout();
      _user = null;
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateFaceIDRequest() async {
    if (_user == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final batch = _firestore.batch();
      final requestRef = _firestore.collection('face_id_requests').doc();
      final studentRef = _firestore.collection('students').doc(_user!.uid);

      batch.set(requestRef, {
        'id': requestRef.id,
        'user_id': _user!.uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(studentRef, {'face_id_request_id': requestRef.id});

      await batch.commit();
    } catch (e) {
      _errorMessage = 'Failed to generate Face ID request.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }
}
