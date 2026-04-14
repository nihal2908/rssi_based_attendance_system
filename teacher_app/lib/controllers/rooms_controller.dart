import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/classroom.dart';

class RoomsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Classroom> _rooms = [];
  List<Classroom> get rooms => _rooms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 1. Fetch all available rooms
  Future<void> fetchRooms() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore.collection('classrooms').get();

      _rooms = snapshot.docs
          .map((doc) => Classroom.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = "Failed to load classrooms: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Filter rooms by capacity or facilities (e.g., Lab vs Classroom)
  List<Classroom> filterRooms(int minCapacity) {
    return _rooms.where((room) => room.capacity >= minCapacity).toList();
  }

  // 4. Clear state (call this when navigating away)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
