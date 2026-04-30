import 'package:cloud_firestore/cloud_firestore.dart';

import 'scheduled_session.dart';
import 'session.dart';
import 'student.dart';
import 'teacher.dart';

class Course {
  String id;
  String name;
  String code;
  String inviteCode;
  List<Teacher>? teachers;
  List<Student>? studentsEnrolled;
  List<Session>? sessions;
  List<ScheduledSession>? scheduledSessions;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.inviteCode,
    this.sessions,
    this.scheduledSessions,
    this.studentsEnrolled,
    this.teachers,
  });

  factory Course.fromMap(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      inviteCode: json['invite_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'code': code, 'invite_code': inviteCode};
  }

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      inviteCode: data['invite_code'] ?? '',
    );
  }
}
