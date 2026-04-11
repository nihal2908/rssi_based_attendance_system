// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:admin_app/models/transmiter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DataCollectionPage extends StatefulWidget {
  final String roomId;
  final List<String> transmitors;
  const DataCollectionPage({
    super.key,
    required this.roomId,
    required this.transmitors,
  });

  @override
  State<DataCollectionPage> createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {
  late final Map<String, Transmiter> _deviceDataMap;
  late final Map<String, int> _deviceIndexMap;

  StreamSubscription? _scanSubscription;
  bool _isScanning = false;
  int readingCount = 0;
  bool _insideRoom = true;

  Timer? _snapshotTimer;
  final List<List<int>> _insideData = [];
  final List<List<int>> _outsideData = [];

  @override
  void initState() {
    _deviceIndexMap = {
      for (int i = 0; i < widget.transmitors.length; i++)
        widget.transmitors[i]: i,
    };
    _deviceDataMap = {};
    for (String device in widget.transmitors) {
      _deviceDataMap[device] = Transmiter(
        name: device,
        initialRssi: -100,
        lastSeen: DateTime.now(),
      );
    }
    super.initState();
  }

  void _takeSnapshot() {
    if (!_isScanning) return;

    List<int> tuple = [];
    for (String device in widget.transmitors) {
      int? index = _deviceIndexMap[device];
      Transmiter? deviceData = _deviceDataMap[device];

      if (index == null || deviceData == null) {
        tuple.add(-100);
        continue;
      }

      if (DateTime.now().difference(deviceData.lastSeen).inSeconds > 5) {
        tuple.add(-100);
      } else {
        tuple.add(deviceData.averageRssi);
      }
    }

    setState(() {
      if (_insideRoom) {
        _insideData.add(tuple);
      } else {
        _outsideData.add(tuple);
      }
    });
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _snapshotTimer?.cancel();
      setState(() => _isScanning = false);
      return;
    }

    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    await FlutterBluePlus.turnOn();

    setState(() => _isScanning = true);

    _snapshotTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _takeSnapshot();
    });

    await FlutterBluePlus.startScan(
      continuousUpdates: true,
      // oneByOne: true,
      androidScanMode: AndroidScanMode.lowLatency,
    );

    print(_insideRoom ? "Inside Room:" : "Outside Room:");

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      readingCount += results.length;
      // print(results.length);
      for (ScanResult r in results) {
        // final id = r.device.remoteId.str;
        final name = r.device.platformName.isEmpty
            ? "Unknown"
            : r.device.platformName;

        // print(name);
        if (widget.transmitors.isNotEmpty &&
            !widget.transmitors.contains(name)) {
          return;
        }
        final rssi = r.rssi;
        // print('$_deviceIndexMap[name]: $rssi');
        setState(() {
          _deviceDataMap[name]!.addReading(rssi);
        });
      }
    });
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "Please don't close the app...\nSending data to server",
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // ------------------ 1. PREPARE JSON ------------------
      final payload = {"inside": _insideData, "outside": _outsideData};

      // ------------------ 2. SEND TO MODEL SERVER ------------------
      final response = await http.post(
        Uri.parse(
          "https://falcon-sweet-physically.ngrok-free.app/train/${widget.roomId}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception("Model server failed: ${response.body}");
      }

      // ------------------ 3. PREPARE DEVICE LIST ------------------
      final devices = widget.transmitors.map((id) {
        return {
          "id": id,
          "name": id, // you can customize later
        };
      }).toList();

      final firestore = FirebaseFirestore.instance;

      // ------------------ 4. STORE DEVICES COLLECTION ------------------
      for (var device in devices) {
        await firestore.collection("devices").doc(device["id"]).set(device);
      }

      // ------------------ 5. UPDATE ROOM DOCUMENT ------------------
      await firestore.collection("rooms").doc(widget.roomId).set({
        "devices": widget.transmitors,
        "configured": true,
        "configured_at": FieldValue.serverTimestamp(),
        "training_data": jsonEncode(payload),
      }, SetOptions(merge: true));

      // ------------------ SUCCESS ------------------
      Navigator.pop(context); // close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data sent & model trained successfully ✅"),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDevices = _deviceDataMap.values.toList();
    // ..sort((a, b) => b.averageRssi.compareTo(a.averageRssi));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Bluetooth Monitor"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text("Count: ${sortedDevices.length}")),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Scanning for nearby signals...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                ElevatedButton(
                  onPressed: _toggleScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.red : Colors.green,
                  ),
                  child: Text(
                    _isScanning ? "STOP" : "START",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.bluetooth, color: Colors.blue),
              title: Text(
                "Readings taken:",
                // style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Text(
                "$readingCount",
                // style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ToggleButtons(
              isSelected: [_insideRoom, !_insideRoom],
              onPressed: (index) {
                setState(() {
                  _insideRoom = index == 0;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Inside Room"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Outside Room"),
                ),
              ],
            ),
          ),
          // Add this inside your Column in build()
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Tuples Collected: Inside: ${_insideData.length} | Outside: ${_outsideData.length}",
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _exportData,
                  child: const Text("Export CSV to Console"),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: sortedDevices.length,
              itemBuilder: (context, index) {
                final device = sortedDevices[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRssiColor(device.averageRssi),
                    child: const Icon(Icons.bluetooth, color: Colors.white),
                  ),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(device.id ?? 'Unknown'),
                  trailing: Text(
                    device.averageRssi.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getRssiColor(device.averageRssi),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    // _cleanupTimer?.cancel();
    _scanSubscription?.cancel();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Data Collection')),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Text('Collecting data from transmitors:'),
  //           ...widget.transmitors.map((t) => Text(t)),
  //           const SizedBox(height: 20),
  //           const CircularProgressIndicator(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
