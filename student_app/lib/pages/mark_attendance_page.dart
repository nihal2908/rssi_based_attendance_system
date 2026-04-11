import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MarkAttendancePage extends StatefulWidget {
  final String roomId;
  final List<String> transmitors;

  const MarkAttendancePage({
    super.key,
    required this.roomId,
    required this.transmitors,
  });

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  Map<String, List<int>> rssiMap = {};
  StreamSubscription? _scanSub;
  Timer? _timer;

  bool isScanning = false;
  String result = "Not checked";

  @override
  void initState() {
    super.initState();
    for (var t in widget.transmitors) {
      rssiMap[t] = [];
    }
  }

  // ------------------ START SCAN ------------------
  Future<void> startScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    await FlutterBluePlus.turnOn();

    setState(() {
      isScanning = true;
      result = "Scanning...";
    });

    // clear previous data
    for (var key in rssiMap.keys) {
      rssiMap[key] = [];
    }

    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
    );

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (var r in results) {
        final name = r.device.platformName;

        if (widget.transmitors.contains(name)) {
          rssiMap[name]?.add(r.rssi);
        }
      }
    });

    // scan for 5 seconds
    _timer = Timer(const Duration(seconds: 5), () async {
      await stopScan();
      runModel();
    });
  }

  // ------------------ STOP SCAN ------------------
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _timer?.cancel();

    setState(() {
      isScanning = false;
    });
  }

  // ------------------ MEDIAN ------------------
  int getMedian(List<int> list) {
    if (list.isEmpty) return -100;
    list.sort();
    return list[list.length ~/ 2];
  }

  // ------------------ PREPARE INPUT ------------------
  List<int> prepareInput() {
    List<int> input = [];

    for (var t in widget.transmitors) {
      final readings = rssiMap[t] ?? [];
      int median = getMedian(readings);

      input.add(median); // ⚠️ normalization
    }

    return input;
    // return [-67, -57, -43, -60];
  }

  // ------------------ LOAD MODEL ------------------
  Future<Interpreter> loadModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/models/${widget.roomId}.tflite";

    return Interpreter.fromFile(File(path));
  }

  // ------------------ RUN MODEL ------------------
  Future<void> runModel() async {
    try {
      final interpreter = await loadModel();

      final input = [prepareInput()];
      final output = List.filled(1 * 1, 0.0).reshape([1, 1]);

      interpreter.run(input, output);

      double score = output[0][0];

      setState(() {
        result = score > 0.8 ? "INSIDE ✅ ($score)" : "OUTSIDE ❌ ($score)";
      });

      print("Input: $input");
      print("Output: $score");
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Result: $result", style: const TextStyle(fontSize: 18)),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: const Text("Check Attendance"),
          ),

          const SizedBox(height: 20),

          ...widget.transmitors.map((t) {
            return Text("$t → ${rssiMap[t]?.length ?? 0} readings");
          }),
        ],
      ),
    );
  }
}
