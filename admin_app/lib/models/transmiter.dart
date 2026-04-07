import 'dart:collection';

class EvictingQueue<T> {
  final int capacity;
  final Queue<int> _storage = Queue<int>();

  EvictingQueue(this.capacity);

  void add(int value) {
    _storage.addLast(value);
    if (_storage.length > capacity) {
      _storage.removeFirst(); // Flushes the oldest value
    }
  }

  List<int> get items => _storage.toList();
  double get average => _storage.isEmpty
      ? -100
      : _storage.reduce((a, b) => a + b) / _storage.length;
}

class Transmiter {
  final String id;
  final String name;
  final EvictingQueue rssiBuffer = EvictingQueue(20);
  DateTime lastSeen;

  Transmiter({
    required this.id,
    required this.name,
    required int initialRssi,
    required this.lastSeen,
  }) {
    rssiBuffer.add(initialRssi);
  }

  int get averageRssi {
    return (rssiBuffer.average).round();
  }

  void addReading(int rssi) {
    rssiBuffer.add(rssi);
    lastSeen = DateTime.now();
  }
}