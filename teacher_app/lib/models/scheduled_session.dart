import 'package:cloud_firestore/cloud_firestore.dart';

import 'classroom.dart';

class ScheduledSession {
  String id;
  int weekday;
  int startHour;
  int startMin;
  int endHour;
  int endMin;
  String classroomId;
  String classroomName;
  Classroom? classroom;

  ScheduledSession({
    required this.id,
    required this.startHour,
    required this.startMin,
    required this.endHour,
    required this.endMin,
    required this.weekday,
    required this.classroomId,
    required this.classroomName,
    this.classroom,
  });

  String _formatTo12Hour(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    int h = hour % 12;
    if (h == 0) h = 12;
    final m = minute.toString().padLeft(2, '0');
    final hStr = h.toString().padLeft(2, '0');

    return '$hStr:$m $period';
  }

  String get startTimeString {
    return _formatTo12Hour(startHour, startMin);
  }

  String get endTimeString {
    return _formatTo12Hour(endHour, endMin);
  }

  String get fullTimeRange => '$startTimeString - $endTimeString';

  factory ScheduledSession.fromMap(Map<String, dynamic> json) {
    return ScheduledSession(
      id: json['id'],
      startHour: int.parse(json['start_hour'] ?? '0'),
      endHour: int.parse(json['end_hour'] ?? '0'),
      startMin: int.parse(json['start_min'] ?? '0'),
      endMin: int.parse(json['end_hour'] ?? '0'),
      weekday: int.parse(json['end_min'] ?? '0'),
      classroomId: json['classroom_id'] ?? '',
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
      'classroom_id': classroomId,
      'classroom_name': classroomName,
    };
  }

  factory ScheduledSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledSession(
      id: doc.id,
      startHour: data['start_hour'] ?? 0,
      endHour: data['end_hour'] ?? 0,
      startMin: data['start_min'] ?? 0,
      endMin: data['end_min'] ?? 0,
      weekday: data['weekday'] ?? 0,
      classroomId: data['classroom_id'] ?? '',
      classroomName: data['classroom_name'] ?? '',
    );
  }

  String get weekdayString {
    switch (weekday) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return 'Unknown WeekDay';
    }
  }
}
