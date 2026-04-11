import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/models/classroom.dart';

class ScheduledSession {
  String id;
  int weekday;
  int startHour;
  int startMin;
  int endHour;
  int endMin;
  String classroomName;
  Classroom? classroom;

  ScheduledSession({
    required this.id,
    required this.startHour,
    required this.startMin,
    required this.endHour,
    required this.endMin,
    required this.weekday,
    required this.classroomName,
    this.classroom,
  });

  factory ScheduledSession.fromMap(Map<String, dynamic> json) {
    return ScheduledSession(
      id: json['id'],
      startHour: int.parse(json['start_hour'] ?? '0'),
      endHour: int.parse(json['end_hour'] ?? '0'),
      startMin: int.parse(json['start_min'] ?? '0'),
      endMin: int.parse(json['end_hour'] ?? '0'),
      weekday: int.parse(json['end_min'] ?? '0'),
      classroomName: json['classroom_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_hour': startHour,
      'end_hour': endHour,
      'start_min': startMin,
      'end_min': endMin,
      'weekday': weekday,
      'classroom_name': classroomName,
    };
  }

  factory ScheduledSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledSession(
      id: doc.id,
      startHour: int.parse(data['start_hour'] ?? '0'),
      endHour: int.parse(data['end_hour'] ?? '0'),
      startMin: int.parse(data['start_min'] ?? '0'),
      endMin: int.parse(data['end_min'] ?? '0'),
      weekday: int.parse(data['weekday'] ?? '0'),
      classroomName: data['classroom_name'] ?? '',
    );
  }
}
