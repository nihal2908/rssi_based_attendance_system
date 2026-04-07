import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardController extends ChangeNotifier{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = 'Admin';
  int _notificationCount = 0;
  int _roomCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  int _studentCount = 0;
  int _teacherCount = 0;
  
  String get username => _username;
  int get notificationCount => _notificationCount;
  int get roomCount => _roomCount;
  int get studentCount => _studentCount;
  int get teacherCount => _teacherCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    try {
      final snapshot = await _firestore.collection('dashboard').doc('data').get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _username = data['username'] ?? 'Admin';
        _notificationCount = data['notificationCount'] ?? 0;
        _roomCount = data['roomCount'] ?? 0;
        _studentCount = data['studentCount'] ?? 0;
        _teacherCount = data['teacherCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

}