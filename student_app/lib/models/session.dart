import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/models/classroom.dart';

import 'student.dart';
import 'teacher.dart';

class Session {
  String id;
  String name;
  DateTime startTime;
  DateTime endTime;
  String classroomName;
  Classroom? classroom;
  bool attendanceOpen;
  Teacher? teacher;
  List<Student>? attendees;

  Session({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.attendanceOpen,
    this.teacher,
    this.attendees,
    required this.classroomName,
    this.classroom,
  });

  factory Session.fromMap(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      name: json['name'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      classroomName: json['classroom_name'] ?? '',
      attendanceOpen: json['attendance_open'] ?? false,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'classroom_name': classroomName,
      'attendance_open': attendanceOpen,
      'name': name,
    };
  }

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      name: data['name'] ?? '',
      startTime: DateTime.parse(data['start_time']),
      endTime: DateTime.parse(data['end_time']),
      classroomName: data['classroom_name'] ?? '',
      attendanceOpen: data['attendance_open'] ?? false,
    );
  }
}
