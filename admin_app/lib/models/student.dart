import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String id;
  String name;
  String email;
  String? avatar;
  String registrationNo;

  Student({
    required this.name,
    required this.email,
    this.avatar,
    required this.registrationNo,
    required this.id,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatar: map['avatar'],
      registrationNo: map['registration_no'] ?? '',
      id: map['id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'registrationNo': registrationNo,
    };
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'],
      registrationNo: data['registration_no'] ?? '',
      id: doc.id,
    );
  }
}
