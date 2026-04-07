import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/request_notification.dart';

class NotificationController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RequestNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RequestNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchNotifications() async {
    _setLoading(true);
    _clearError();
    try {
      _notifications = await _fetchNotificationsFromService();
    } catch (e) {
      _errorMessage = 'Failed to load notifications.';
    } finally {
      _setLoading(false);
    }
  }

  Future<List<RequestNotification>> _fetchNotificationsFromService() async {
    try {
      final snapshot = await _firestore.collection('notifications').get();
      return snapshot.docs
          .map((doc) => RequestNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  void allowRequest(RequestNotification notification) {}

  void rejectRequest(RequestNotification notification) {}

  bool searchMode = false;
  String searchQuery = '';

  void enterSearchMode() {
    searchMode = true;
    notifyListeners();
  }

  void exitSearchMode() {
    searchMode = false;
    searchQuery = '';
    notifyListeners();
  }

  void search(String query) {
    searchQuery = query;
    fetchNotifications();
    notifyListeners();
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

  void refreshNotifications() {
    fetchNotifications();
  }
}
