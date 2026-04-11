import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  String id;
  String name;
  String email;

  Teacher({required this.id, required this.name, required this.email});

  factory Teacher.fromMap(Map<String, dynamic> json) {
    return Teacher(id: json['id'], name: json['name'], email: json['email']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'email': email};
  }

  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teacher(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
