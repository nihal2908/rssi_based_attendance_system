import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dependency_injection.dart';
import '../models/teacher.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Teacher? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Teacher? get currentUser => _currentUser;
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
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.register(name, email, password);
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

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    clearError();
    try {
      final user = await _authService.loginWithGoogle();
      if (user == null) {
        _errorMessage = 'Google Sign-In failed or was cancelled.';
        return false;
      }
      _user = _authService.getCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Google Sign-In failed.';
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
          .collection('teachers')
          .doc(_user!.uid)
          .get();

      if (snapshot.exists) {
        _currentUser = Teacher.fromFirestore(snapshot);
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }
}
