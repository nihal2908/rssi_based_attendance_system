import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/classroom.dart';

class RoomController extends ChangeNotifier {
  Classroom? _currentRoom;
  Classroom? get currentRoom => _currentRoom;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String _statusMessage = "Ready";
  String get statusMessage => _statusMessage;

  // Internal state for scanning
  final Map<String, List<int>> _rssiMap = {};
  StreamSubscription? _scanSub;
  Timer? _timer;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _updateStatus(String msg) {
    _statusMessage = msg;
    notifyListeners();
  }

  Future<void> init(Classroom classroom) async {
    _currentRoom = classroom;
    _rssiMap.clear();
    for (var device in classroom.devices) {
      _rssiMap[device] = [];
    }
    notifyListeners();
  }

  // --- MODEL MANAGEMENT ---

  Future<bool> checkModelExists(String roomId) async {
    final directory = await path.getApplicationDocumentsDirectory();
    return File('${directory.path}/models/$roomId.tflite').existsSync();
  }

  Future<void> downloadRoomConfig(String roomId) async {
    _setLoading(true);
    try {
      final url =
          'https://falcon-sweet-physically.ngrok-free.app/model/$roomId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await path.getApplicationDocumentsDirectory();
        final folder = Directory('${directory.path}/models');
        if (!await folder.exists()) await folder.create(recursive: true);

        final file = File('${folder.path}/$roomId.tflite');
        await file.writeAsBytes(response.bodyBytes);
      }
    } finally {
      _setLoading(false);
    }
  }

  // --- ATTENDANCE LOGIC (BLE + ML) ---

  Future<void> startAttendanceVerification() async {
    if (_currentRoom == null) return;

    // Request Permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    await FlutterBluePlus.turnOn();

    _isScanning = true;
    _updateStatus("Scanning beacons...");

    // Clear previous readings
    _rssiMap.forEach((key, value) => value.clear());

    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
    );

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (var r in results) {
        final name = r.device.platformName;
        if (_currentRoom!.devices.contains(name)) {
          _rssiMap[name]?.add(r.rssi);
        }
      }
    });

    // Scan for 5 seconds then process
    _timer = Timer(const Duration(seconds: 5), () async {
      await _stopScan();
      await _runInference();
    });
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _timer?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> _runInference() async {
    _updateStatus("Analyzing location...");
    try {
      final directory = await path.getApplicationDocumentsDirectory();
      final pathStr = "${directory.path}/models/${_currentRoom!.id}.tflite";

      final interpreter = Interpreter.fromFile(File(pathStr));

      // Prepare Input (Mean RSSI)
      List<int> inputVector = [];
      for (var device in _currentRoom!.devices) {
        final readings = _rssiMap[device] ?? [];
        int mean = readings.isEmpty
            ? -100
            : readings.reduce((a, b) => a + b) ~/ readings.length;
        inputVector.add(mean);
      }

      final input = [inputVector];
      final output = List.filled(1, 0.0).reshape([1, 1]);

      interpreter.run(input, output);
      double score = output[0][0];
      interpreter.close();

      _updateStatus(score > 0.8 ? "SUCCESS" : "OUTSIDE_ZONE");
    } catch (e) {
      _updateStatus("Error: $e");
    }
  }
}
