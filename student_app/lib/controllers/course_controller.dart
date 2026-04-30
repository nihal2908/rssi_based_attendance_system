import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';
import '../models/classroom.dart';
import '../models/course.dart';
import '../models/scheduled_session.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import 'auth_controller.dart';

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

  Session? _currentSession;
  Session? get currentSession => _currentSession;
  set currentSession(Session? session) {
    _currentSession = session;
    notifyListeners();
    startSessionStream(session?.id);
  }

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  StreamSubscription<DocumentSnapshot>? _sessionStreamSubscription;
  final ChangeNotifier sessionChangeNotifier = ChangeNotifier();

  void startSessionStream(String? sessionId) async {
    _sessionStreamSubscription?.cancel();
    if (sessionId != null) {
      _sessionStreamSubscription = _firestore
          .collection('sessions')
          .doc(sessionId)
          .snapshots()
          .listen((snapshot) async {
            print("Session document updated: ${snapshot.id}");
            if (snapshot.exists) {
              final updatedSession = snapshot.data() as Map<String, dynamic>;
              if (_currentSession != null &&
                  _currentSession!.id == updatedSession['id']) {
                final attendeeIds = List<String>.from(
                  updatedSession['attendees'] ?? [],
                );
                currentSession?.attendees = _currentCourse?.studentsEnrolled
                    ?.where((student) => attendeeIds.contains(student.id))
                    .toList();
                _currentSession?.attendanceOpen =
                    updatedSession['attendance_open'] ?? false;

                sessionChangeNotifier.notifyListeners();
              }
            }
          });
    }
  }

  Future<void> fetchCourses() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final authController = sl<AuthController>();
      final userId = authController.user?.uid;
      if (userId == null) {
        _errorMessage = 'User not logged in';
        notifyListeners();
        return;
      }

      final userDataSnapshot = await _firestore
          .collection('students')
          .doc(userId)
          .get();
      if (!userDataSnapshot.exists) {
        _errorMessage = 'User data not found';
        notifyListeners();
        return;
      }

      final enrolledCourseIds = List<String>.from(
        userDataSnapshot['courses_enrolled'] ?? [],
      );
      // print(enrolledCourseIds);
      if (enrolledCourseIds.isEmpty) {
        _courses = [];
        notifyListeners();
        return;
      }

      final courseSnapshots = await Future.wait(
        enrolledCourseIds.map(
          (id) => _firestore.collection('courses').doc(id).get(),
        ),
      );

      _courses = courseSnapshots
          .map((doc) => Course.fromFirestore(doc))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch courses: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinCourse(String code) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('courses')
          .where('invite_code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _errorMessage = 'Course not found';
        return false;
      }

      final AuthController authController = sl<AuthController>();
      final userId = authController.user?.uid;
      if (userId == null) {
        _errorMessage = 'User not logged in';
        return false;
      }

      final courseId = snapshot.docs.first.id;

      // check for student id already enrolled
      final enrollmentDoc = await _firestore
          .collection('course_enrollements')
          .doc(courseId)
          .get();

      if (enrollmentDoc.exists) {
        final enrolledStudents = List<String>.from(
          enrollmentDoc['students_enrolled'] ?? [],
        );
        if (enrolledStudents.contains(userId)) {
          _errorMessage = 'Already enrolled in this course';
          return false;
        }
      }

      await _firestore.collection('course_enrollements').doc(courseId).update({
        'students_enrolled': FieldValue.arrayUnion([userId]),
      });

      await _firestore.collection('students').doc(userId).update({
        'courses_enrolled': FieldValue.arrayUnion([courseId]),
      });

      return true;
    } catch (e) {
      _errorMessage = 'Failed to join course: ${e.toString()}';
      return false;
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
      final teachers = await Future.wait(
        teacherIds.map((id) => _firestore.collection('teachers').doc(id).get()),
      );
      _currentCourse!.teachers = teachers
          .where((doc) => doc.exists)
          .map((doc) => Teacher.fromFirestore(doc))
          .toList();

      final studentIds = List<String>.from(
        await _firestore
            .collection('course_enrollements')
            .doc(courseId)
            .get()
            .then(
              (doc) => doc.exists
                  ? List<String>.from(doc['students_enrolled'] ?? [])
                  : [],
            ),
      );
      final students = await Future.wait(
        studentIds.map((id) => _firestore.collection('students').doc(id).get()),
      );
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

      final scheduleIds = List<String>.from(
        courseDoc['scheduled_sessions'] ?? [],
      );
      final schedules = await Future.wait(
        scheduleIds.map(
          (id) => _firestore.collection('scheduled_sessions').doc(id).get(),
        ),
      );

      _currentCourse!.scheduledSessions =
          schedules
              .where((doc) => doc.exists)
              .map((doc) => ScheduledSession.fromFirestore(doc))
              .toList()
            ..sort((a, b) {
              int dayCompare = a.weekday.compareTo(b.weekday);
              if (dayCompare == 0) {
                return a.startHour.compareTo(b.startHour);
              }
              return dayCompare;
            });

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch course schedule: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCompleteCourseDetails() async {
    await Future.wait([
      getCourseSchedule(),
      getCourseMembers(),
      getCourseSessions(),
    ]);
  }

  Future<void> fetchSessionDetails(String id) async {
    if (_currentCourse == null) return Future.error('No course selected');
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final sessionData =
          (await _firestore.collection('sessions').doc(id).get()).data();
      if (sessionData == null) {
        _errorMessage = 'Session not found';
        notifyListeners();
        return;
      }

      final teacherId = sessionData['teacher_id'];
      final attendeeIds = List<String>.from(sessionData['attendees'] ?? []);
      final classroomId = sessionData['classroom_id'];

      _currentSession!.teacher = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .get()
          .then((doc) => doc.exists ? Teacher.fromFirestore(doc) : null);

      _currentSession!.attendees =
          await Future.wait(
            attendeeIds.map(
              (id) => _firestore.collection('students').doc(id).get(),
            ),
          ).then(
            (docs) => docs
                .where((doc) => doc.exists)
                .map((doc) => Student.fromFirestore(doc))
                .toList(),
          );

      _currentSession!.classroom = await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .get()
          .then((doc) => doc.exists ? Classroom.fromFirestore(doc) : null);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch session details: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
