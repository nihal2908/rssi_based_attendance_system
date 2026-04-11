import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../dependency_injection.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _authService = sl<AuthService>();
    _user = _authService.getCurrentUser();
  }

  late final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    print('called register');
    _setLoading(true);
    _clearError();
    try {
      await _authService.register(name, email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to sign in.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to sign in.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    print('called login');
    _setLoading(true);
    _clearError();
    try {
      await _authService.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to sign in.';
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to sign in.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      _user = _authService.getCurrentUser();
      final snapshot = await _firestore
          .collection('teachers')
          .doc(_user!.uid)
          .get();
      return snapshot.data() ?? {};
      // notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to fetch user data.';
      return {};
    } catch (_) {
      _errorMessage = 'Failed to fetch user data.';
      return {};
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.logout();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to sign out.';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Failed to sign out.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
