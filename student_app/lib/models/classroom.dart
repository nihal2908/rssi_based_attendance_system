import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  String id;
  String name;
  String location;
  int capacity;
  bool configured = false;
  List<String> devices = [];

  Classroom({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    this.configured = false,
    this.devices = const [],
  });

  factory Classroom.fromMap(Map<String, dynamic> map) {
    return Classroom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      capacity: map['capacity'] ?? 0,
      configured: map['configured'] ?? false,
      devices: List<String>.from(map['devices'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'configured': configured,
      'devices': devices,
    };
  }

  factory Classroom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Classroom(
      id: data['id'] ?? '',
      name: data['name'] ?? 'No name',
      capacity: data['capacity'] ?? '',
      location: data['location'] ?? '',
      configured: data['configured'] ?? false,
      devices: List<String>.from(data['devices'] ?? []),
    );
  }
}
