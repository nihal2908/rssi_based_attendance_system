import 'package:cloud_firestore/cloud_firestore.dart';

import 'classroom.dart';
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
    required this.classroomName,
    this.teacher,
    this.attendees,
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
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'classroom_name': classroomName,
      'attendance_open': attendanceOpen,
      'teacher_id': teacher?.toMap(),
      'attendee_ids': attendees?.map((s) => s.toMap()).toList(),
      'classroom_id': classroom?.toMap(),
    };
  }

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      name: data['name'] ?? '',
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      classroomName: data['classroom_name'] ?? '',
      attendanceOpen: data['attendance_open'] ?? false,
    );
  }

  String _formattedTime(DateTime time) {
    final hour = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get formattedStartTime {
    return _formattedTime(startTime);
  }

  String get formattedEndTime {
    return _formattedTime(endTime);
  }

  String get formattedTimeRange {
    return '$formattedStartTime - $formattedEndTime';
  }
}
