import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/room.dart';

class RoomsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRooms() async {
    _setLoading(true);
    _clearError();
    try {
      final snapshot = await _firestore.collection('rooms').get();
      _rooms = snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load rooms.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addRoom(String name, int capacity, String location) async {
    _setLoading(true);
    _clearError();
    try {
      final docRef = _firestore.collection('rooms').doc();
      final newRoom = Room(
        id: docRef.id,
        name: name,
        capacity: capacity,
        location: location,
      );
      await docRef.set({
        'id': docRef.id,
        'name': name,
        'capacity': capacity,
        'location': location,
      });
      _rooms.add(newRoom);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add room.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestore.collection('rooms').doc(roomId).delete();
      _rooms.removeWhere((room) => room.id == roomId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete room.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getRoomDetails(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        throw Exception('Room not found');
      }
    } catch (e) {
      throw Exception('Failed to load room details');
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
