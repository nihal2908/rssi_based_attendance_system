import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  String id;
  String name;
  int capacity;
  String location;
  bool configured;

  Room({
    required this.id,
    required this.name,
    required this.capacity,
    required this.location,
    this.configured = false,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: data['id'] ?? '',
      name: data['name'] ?? 'No name',
      capacity: data['capacity'] ?? '',
      location: data['location'] ?? '',
      configured: data['configured'] ?? false,
    );
  }

  factory Room.fromMap(Map<String, dynamic> data) {
    return Room(
      id: data['id'] ?? '',
      name: data['name'] ?? 'No name',
      capacity: data['capacity'] ?? '',
      location: data['location'] ?? '',
      configured: data['configured'] ?? false,
    );
  }
}
