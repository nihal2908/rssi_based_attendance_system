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
  int average() {
    if (_storage.isEmpty) {
      return -100;
    } else {
      int avg = _storage.reduce((a, b) => a + b) ~/ _storage.length;
      // final list = _storage.toList();
      // list.sort();
      // int median = list.length % 2 == 1
      //     ? list[list.length ~/ 2]
      //     : ((list[list.length ~/ 2 - 1] + list[list.length ~/ 2]) / 2).round();
      // return median;
      return avg;
    }
  }
}

class Transmiter {
  final String? id;
  final String name;
  final EvictingQueue rssiBuffer = EvictingQueue(10);
  DateTime lastSeen;

  Transmiter({
    this.id,
    required this.name,
    required int initialRssi,
    required this.lastSeen,
  }) {
    rssiBuffer.add(initialRssi);
  }

  int get averageRssi {
    return rssiBuffer.average();
  }

  void addReading(int rssi) {
    rssiBuffer.add(rssi);
    lastSeen = DateTime.now();
  }
}
