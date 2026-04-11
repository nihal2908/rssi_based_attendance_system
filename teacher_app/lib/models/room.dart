class Room {
  String id;
  String name;
  String location;
  String teacher;
  int capacity;

  Room({
    required this.id,
    required this.name,
    required this.location,
    required this.teacher,
    required this.capacity,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      teacher: map['teacher'] ?? '',
      capacity: map['capacity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'teacher': teacher,
      'capacity': capacity,
    };
  }

  factory Room.fromFirestore(Map<String, dynamic> map) {
    return Room(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      teacher: map['teacher'] ?? '',
      capacity: map['capacity'] ?? 0,
    );
  }
}
