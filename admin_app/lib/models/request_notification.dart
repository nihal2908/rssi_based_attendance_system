import 'package:cloud_firestore/cloud_firestore.dart';

class RequestNotification {
  String title;
  String timestamp;
  String message;

  RequestNotification({
    required this.title,
    required this.timestamp,
    required this.message,
  });

  factory RequestNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestNotification(
      title: data['title'] ?? 'No Title',
      timestamp: data['timestamp'].toString(),
      message: data['message'] ?? '',
    );
  }
}
