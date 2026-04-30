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
import '../utils/invite_code_generator.dart';
import 'auth_controller.dart';

class TeacherCourseController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Course> _assignedCourses = [];
  List<Course> get assignedCourses => _assignedCourses;

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAssignedCourses() async {
    final authController = sl<AuthController>();
    final teacherId = authController.user?.uid;

    if (teacherId == null) {
      _errorMessage = "User not authenticated";
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. Directly get course IDs from the teacher document
      final teacherDoc = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .get();

      if (!teacherDoc.exists) {
        throw Exception("Teacher profile not found");
      }

      final courseIds = List<String>.from(teacherDoc['courses_assigned'] ?? []);

      if (courseIds.isEmpty) {
        _assignedCourses = [];
        return;
      }

      // 2. Fetch course details
      final courseDocs = await Future.wait(
        courseIds.map((id) => _firestore.collection('courses').doc(id).get()),
      );

      _assignedCourses = courseDocs
          .where((doc) => doc.exists)
          .map((doc) => Course.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = "Failed to load courses: $e";
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

  Future<void> addScheduledSession({
    required int weekday,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String roomId,
    required String roomName,
  }) async {
    if (_currentCourse == null) return;
    try {
      _isLoading = true;
      final sessionRef = _firestore.collection('scheduled_sessions').doc();

      final newSession = {
        'id': sessionRef.id,
        'course_id': _currentCourse!.id,
        'weekday': weekday,
        'start_hour': startTime.hour,
        'start_min': startTime.minute,
        'end_hour': endTime.hour,
        'end_min': endTime.minute,
        'classroom_id': roomId,
        'classroom_name': roomName,
      };

      final batch = _firestore.batch();
      batch.set(sessionRef, newSession);
      batch.update(_firestore.collection('courses').doc(_currentCourse!.id), {
        'scheduled_sessions': FieldValue.arrayUnion([sessionRef.id]),
      });

      await batch.commit();
      await getCourseSchedule();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSession({
    required String name,
    required String classroomId,
    required String classroomName,
    required String teacherId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final sessionRef = _firestore.collection('sessions').doc();

      final sessionData = {
        'id': sessionRef.id,
        'course_id': _currentCourse!.id,
        'name': name,
        'classroom_id': classroomId,
        'classroom_name': classroomName,
        'teacher_id': teacherId,
        'start_time': startTime,
        'end_time': endTime,
        'attendance_open': false,
        'attendees': [],
      };

      final batch = _firestore.batch();
      batch.set(sessionRef, sessionData);

      batch.update(_firestore.collection('courses').doc(_currentCourse!.id), {
        'sessions': FieldValue.arrayUnion([sessionRef.id]),
      });

      await batch.commit();
      await getCourseSessions();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCourse({
    required String name,
    required String code,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final authController = sl<AuthController>();
      final teacherId = authController.user?.uid;

      // Generate a unique invite code for the course
      final inviteCode = await _getUniqueInviteCode();

      // Generate a unique ID for the course
      final courseRef = _firestore.collection('courses').doc();

      final batch = _firestore.batch();

      // 1. Create the Course Document
      batch.set(courseRef, {
        'id': courseRef.id,
        'name': name,
        'code': code.toUpperCase().trim(),
        'invite_code': inviteCode,
        'teachers': [teacherId],
        'sessions': [],
        'scheduled_sessions': [],
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Initialize the Enrollment record
      batch.set(
        _firestore.collection('course_enrollements').doc(courseRef.id),
        {'course_id': courseRef.id, 'students_enrolled': []},
      );

      // 3. Link course to Teacher's document
      batch.update(_firestore.collection('teachers').doc(teacherId), {
        'courses_assigned': FieldValue.arrayUnion([courseRef.id]),
      });

      await batch.commit();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create course: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _getUniqueInviteCode() async {
    final firestore = FirebaseFirestore.instance;
    bool isUnique = false;
    String code = "";

    while (!isUnique) {
      code = InviteCodeGenerator.generate();

      final codeDocRef = firestore.collection('invite_codes').doc(code);

      try {
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(codeDocRef);

          if (snapshot.exists) {
            throw Exception("Code Taken");
          } else {
            transaction.set(codeDocRef, {
              'created_at': FieldValue.serverTimestamp(),
              'status': 'active',
            });
            isUnique = true;
          }
        });
      } catch (e) {
        // print("Collision detected for $code, retrying...");
      }
    }

    return code;
  }

  Future<bool> joinCourse({required String code}) async {
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

      // check if teacher is already assigned to the course
      final assignedTeachers = List<String>.from(
        snapshot.docs.first['teachers'] ?? [],
      );
      if (assignedTeachers.contains(userId)) {
        _errorMessage = 'You are already assigned to this course';
        return false;
      }

      await _firestore.collection('courses').doc(courseId).update({
        'teachers': FieldValue.arrayUnion([userId]),
      });

      await _firestore.collection('teachers').doc(userId).update({
        'courses_assigned': FieldValue.arrayUnion([courseId]),
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

  Future<void> updateAttendanceStatus(String sessionId, bool isLive) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'is_live': isLive,
        'start_time': isLive ? FieldValue.serverTimestamp() : null,
        'end_time': !isLive ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleAttendance(String sessionId, bool isOpen) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('sessions').doc(sessionId).update({
        'attendance_open': isOpen,
        if (isOpen) 'attendance_started_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleManualAttendance(
    String sessionId,
    String studentId,
    bool isPresent,
  ) async {
    try {
      final docRef = _firestore.collection('sessions').doc(sessionId);

      if (isPresent) {
        await docRef.update({
          'attendees': FieldValue.arrayUnion([studentId]),
        });
      } else {
        await docRef.update({
          'attendees': FieldValue.arrayRemove([studentId]),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
