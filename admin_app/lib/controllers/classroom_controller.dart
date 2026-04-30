import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/classroom.dart';
import '../models/course.dart';
import '../models/session.dart';
import '../models/teacher.dart';

class ClassroomController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String classroomId;

  Classroom? _currentRoom;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  // Constructor receives the ID from the Detail Page
  ClassroomController({required this.classroomId});

  // Getters
  Classroom? get currentRoom => _currentRoom;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  List<Session> _sessions = [];
  List<Session> get sessions => _sessions;

  /// Fetches the specific classroom document by ID
  Future<void> fetchRoomDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .get();

      if (doc.exists) {
        _currentRoom = Classroom.fromFirestore(doc);
      } else {
        _errorMessage = "Classroom not found in database.";
      }
      fetchRoomSessions();
    } catch (e) {
      _errorMessage = "Error fetching classroom: ${e.toString()}";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomSessions() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('sessions')
          .where('classroom_id', isEqualTo: classroomId)
          .orderBy('start_time', descending: true)
          .get();

      List<Session> sessions = snapshot.docs
          .map((doc) => Session.fromFirestore(doc))
          .toList();

      if (sessions.isNotEmpty) {
        // 1. Collect all unique IDs to avoid redundant fetches
        final teacherIds = sessions.map((s) => s.teacherId).toSet().toList();
        final courseIds = sessions.map((s) => s.courseId).toSet().toList();

        // 2. Fetch all required Teachers and Courses in parallel
        final teacherDocs = await _firestore
            .collection('teachers')
            .where(FieldPath.documentId, whereIn: teacherIds)
            .get();
        final courseDocs = await _firestore
            .collection('courses')
            .where(FieldPath.documentId, whereIn: courseIds)
            .get();

        // 3. Create mapping for quick lookups
        final teacherMap = {
          for (var doc in teacherDocs.docs) doc.id: Teacher.fromFirestore(doc),
        };
        final courseMap = {
          for (var doc in courseDocs.docs) doc.id: Course.fromFirestore(doc),
        };

        // 4. Attach the full objects to each session
        for (var session in sessions) {
          session.teacher = teacherMap[session.teacherId];
          session.course = courseMap[session.courseId];
        }
      }

      _sessions = sessions;
    } catch (e) {
      debugPrint("History Fetch Error: $e");
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
}
