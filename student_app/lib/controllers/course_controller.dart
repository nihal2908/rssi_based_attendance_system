import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/scheduled_session.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class CourseController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Course> _courses = [];
  List<Course> get courses => _courses;

  Course? _currentCourse;
  Course? get currentCourse => _currentCourse;
  set currentCourse(Course? course) {
    _currentCourse = course;
    notifyListeners();
  }

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCourses() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore.collection('courses').get();
      _courses = snapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch courses: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinCourse(String code) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      return _firestore
          .collection('courses')
          .where('code', isEqualTo: code)
          .get()
          .then((snapshot) async {
            if (snapshot.docs.isEmpty) {
              _errorMessage = 'Course not found';
              notifyListeners();
              return Future.error('Course not found');
            }

            final course = Course.fromFirestore(snapshot.docs.first);
            await _firestore
                .collection('course_enrollements')
                .doc(course.id)
                .update({'students_enrolled': FieldValue.arrayUnion([])});
            notifyListeners();
          });
    } catch (e) {
      _errorMessage = 'Failed to join course: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCourseSessions() async {
    if (_currentCourse == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final courseId = _currentCourse!.id;
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      if (!courseDoc.exists) {
        _errorMessage = 'Course not found';
        notifyListeners();
        return;
      }

      final sessionIds = List<String>.from(courseDoc['sessions'] ?? []);
      final sessions = await Future.wait(
        sessionIds.map((id) => _firestore.collection('sessions').doc(id).get()),
      );

      _currentCourse!.sessions = sessions
          .where((doc) => doc.exists)
          .map((doc) => Session.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch course details: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCourseMembers() async {
    if (_currentCourse == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final courseId = _currentCourse!.id;
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      if (!courseDoc.exists) {
        _errorMessage = 'Course not found';
        notifyListeners();
        return;
      }

      final teacherIds = List<String>.from(courseDoc['teachers'] ?? []);
      final studentIds = List<String>.from(courseDoc['students_enrolled'] ?? []);

      final teachers = await Future.wait(
        teacherIds.map((id) => _firestore.collection('teachers').doc(id).get()),
      );
      final students = await Future.wait(
        studentIds.map((id) => _firestore.collection('students').doc(id).get()),
      );

      _currentCourse!.teachers = teachers
          .where((doc) => doc.exists)
          .map((doc) => Teacher.fromFirestore(doc))
          .toList();
      _currentCourse!.studentsEnrolled = students
          .where((doc) => doc.exists)
          .map((doc) => Student.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch course members: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCourseSchedule() async {
    if (_currentCourse == null) return;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final courseId = _currentCourse!.id;
      final courseDoc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get();
      if (!courseDoc.exists) {
        _errorMessage = 'Course not found';
        notifyListeners();
        return;
      }

      final scheduleIds = List<String>.from(courseDoc['scheduled_sessions'] ?? []);
      final schedules = await Future.wait(
        scheduleIds.map((id) => _firestore.collection('scheduled_sessions').doc(id).get()),
      );

      _currentCourse!.scheduledSessions = schedules
          .where((doc) => doc.exists)
          .map((doc) => ScheduledSession.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch course schedule: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
