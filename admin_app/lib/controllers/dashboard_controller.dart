import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../dependency_injection.dart';
import '../models/classroom.dart';
import '../models/course.dart';
import '../models/request_notification.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class DashboardController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _username = 'Admin';
  String get username => _username;

  int _notificationCount = 0;
  int get notificationCount => _notificationCount;

  int _classroomCount = 0;
  int get classroomCount => _classroomCount;

  int _studentCount = 0;
  int get studentCount => _studentCount;

  int _teacherCount = 0;
  int get teacherCount => _teacherCount;

  int _courseCount = 0;
  int get courseCount => _courseCount;

  List<Student> _students = [];
  List<Student> get students => _students;

  List<Teacher> _teachers = [];
  List<Teacher> get teachers => _teachers;

  List<Course> _courses = [];
  List<Course> get courses => _courses;

  List<Classroom> _classrooms = [];
  List<Classroom> get classrooms => _classrooms;

  List<RequestNotification> _notifications = [];
  List<RequestNotification> get notifications => _notifications;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      // Fetch Admin name
      final userId = sl<AuthController>().user?.uid;
      if (userId != null) {
        final userDoc = await _firestore.collection('admins').doc(userId).get();
        if (userDoc.exists) {
          _username = userDoc.data()?['name'] ?? 'Admin';
        }
      }

      final results = await Future.wait([
        _firestore.collection('classrooms').count().get(),
        _firestore.collection('students').count().get(),
        _firestore.collection('teachers').count().get(),
        _firestore.collection('courses').count().get(),
        _firestore.collection('notifications').count().get(),
      ]);

      _classroomCount = results[0].count ?? 0;
      _studentCount = results[1].count ?? 0;
      _teacherCount = results[2].count ?? 0;
      _courseCount = results[3].count ?? 0;
      _notificationCount = results[4].count ?? 0;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudents() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final snapshot = await _firestore.collection('students').get();
      _students = snapshot.docs.map((doc) {
        return Student.fromFirestore(doc);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load students: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeachers() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final snapshot = await _firestore.collection('teachers').get();
      _teachers = snapshot.docs.map((doc) {
        return Teacher.fromFirestore(doc);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load teachers: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCourses() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final snapshot = await _firestore.collection('courses').get();
      _courses = snapshot.docs.map((doc) {
        return Course.fromFirestore(doc);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load courses: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchClassrooms() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final snapshot = await _firestore.collection('classrooms').get();
      _classrooms = snapshot.docs.map((doc) {
        return Classroom.fromFirestore(doc);
      }).toList();
    } catch (e) {
      _errorMessage = 'Failed to load classrooms: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final snapshot = await _firestore.collection('notifications').get();
      _notifications = snapshot.docs.map((doc) {
        return RequestNotification.fromFirestore(doc);
      }).toList();

      final studentIds = _notifications
          .where((n) => n.studentId != null)
          .map((n) => n.studentId!)
          .toSet()
          .toList();

      final teacherIds = _notifications
          .where((n) => n.teacherId != null)
          .map((n) => n.teacherId!)
          .toSet()
          .toList();

      final studentDocs = await Future.wait(
        studentIds.map((id) {
          return _firestore.collection('students').doc(id).get();
        }),
      );
      final teacherDocs = await Future.wait(
        teacherIds.map((id) {
          return _firestore.collection('teachers').doc(id).get();
        }),
      );

      final studentMap = {
        for (var doc in studentDocs)
          if (doc.exists) doc.id: Student.fromFirestore(doc),
      };
      final teacherMap = {
        for (var doc in teacherDocs)
          if (doc.exists) doc.id: Teacher.fromFirestore(doc),
      };

      for (var notification in _notifications) {
        if (notification.studentId != null) {
          notification.student = studentMap[notification.studentId!];
        }
        if (notification.teacherId != null) {
          notification.teacher = teacherMap[notification.teacherId!];
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void rejectRequest(RequestNotification notification) {}

  void allowRequest(RequestNotification notification) {}

  Future<void> addClassroom(String name, int capacity, String location) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      final docRef = _firestore.collection('classrooms').doc();
      final newClassroom = Classroom(
        id: docRef.id,
        name: name,
        capacity: capacity,
        location: location,
      );
      await docRef.set(newClassroom.toMap());
      notifyListeners();

      fetchClassrooms();
    } catch (e) {
      _errorMessage = 'Failed to add room.';
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }
}
