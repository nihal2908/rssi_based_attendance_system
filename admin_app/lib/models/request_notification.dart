import 'package:cloud_firestore/cloud_firestore.dart';

import 'student.dart';
import 'teacher.dart';

class RequestNotification {
  String id;
  String title;
  DateTime timestamp;
  String? studentId;
  Student? student;
  String? teacherId;
  Teacher? teacher;
  String? message;

  RequestNotification({
    required this.id,
    this.studentId,
    this.teacherId,
    this.message,
    required this.timestamp,
    required this.title,
  });

  factory RequestNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestNotification(
      title: data['title'] ?? 'No Title',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      message: data['message'],
      teacherId: data['teacher_id'],
      studentId: data['student_id'],
      id: doc.id,
    );
  }
}
