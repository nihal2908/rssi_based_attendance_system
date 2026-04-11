import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/room.dart';

class RoomsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchRooms() {
    try {
      _setLoading(true);
      _clearError();
      return _firestore.collection('rooms').get().then((snapshot) {
        _rooms = snapshot.docs.map((doc) => Room.fromFirestore(doc as Map<String, dynamic>)).toList();
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to fetch rooms: $e';
      notifyListeners();
      return Future.error(e);
    } finally {
      _setLoading(false);
    }
  }
}