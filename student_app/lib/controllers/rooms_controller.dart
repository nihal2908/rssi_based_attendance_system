import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;

import '../models/classroom.dart';

class RoomsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Classroom> _rooms = [];
  List<Classroom> get rooms => _rooms;

  Classroom? _currentRoom;
  Classroom? get currentRoom => _currentRoom;

  File? _currentModelFile;
  File? get currentModelFile => _currentModelFile;

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
        _rooms = snapshot.docs
            .map((doc) => Classroom.fromFirestore(doc))
            .toList();
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

  Future<void> getRoomDetails(String roomId) {
    try {
      _setLoading(true);
      _clearError();
      return _firestore.collection('rooms').doc(roomId).get().then((doc) {
        if (doc.exists) {
          final room = Classroom.fromFirestore(doc);
          _currentRoom = room;
          fetchModelFromCache(roomId).catchError((_) {
            return downloadRoomConfig(roomId);
          });
          notifyListeners();
        } else {
          throw Exception('Room not found');
        }
      });
    } catch (e) {
      _errorMessage = 'Failed to fetch room details: $e';
      notifyListeners();
      return Future.error(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> downloadRoomConfig(String roomId) async {
    try {
      _setLoading(true);
      _clearError();
      // download the model trained for the room from https://example.com/model/$roomId using http package and cache it locally using path_provider
      final url =
          'https://falcon-sweet-physically.ngrok-free.app/model/$roomId';
      return http.get(Uri.parse(url)).then((response) async {
        if (response.statusCode == 200) {
          final directory = await path.getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/models/$roomId.tflite';
          final file = await File(filePath).create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);
          _currentModelFile = file;
          print('Model downloaded: ${response.body}');
        } else {
          throw Exception('Failed to download model: ${response.statusCode}');
        }
      });
    } catch (e) {
      _errorMessage = 'Failed to download room configuration: $e';
      notifyListeners();
      return Future.error(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearCache() async {
    try {
      _setLoading(true);
      _clearError();
      final directory = await path.getApplicationDocumentsDirectory();
      final modelsDir = Directory('${directory.path}/models');
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
        print('Cache cleared');
      }
    } catch (e) {
      _errorMessage = 'Failed to clear cache: $e';
      notifyListeners();
      return Future.error(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshRooms() {
    return fetchRooms();
  }

  Future<void> fetchModelFromCache(String roomId) async {
    try {
      _setLoading(true);
      _clearError();
      final directory = await path.getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/models/$roomId.tflite';
      final file = File(filePath);
      return file.exists().then((exists) {
        if (exists) {
          _currentModelFile = file;
          print('Model loaded from cache: $filePath');
        } else {
          throw Exception('Model not found in cache');
        }
      });
    } catch (e) {
      _errorMessage = 'Failed to fetch model from cache: $e';
      notifyListeners();
      return Future.error(e);
    } finally {
      _setLoading(false);
    }
  }
}
