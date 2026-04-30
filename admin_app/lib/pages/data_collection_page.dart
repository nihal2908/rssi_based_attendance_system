import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../models/transmiter.dart';

class DataCollectionPage extends StatefulWidget {
  final String classroomId;
  final List<String> transmitters;
  const DataCollectionPage({
    super.key,
    required this.classroomId,
    required this.transmitters,
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
      for (int i = 0; i < widget.transmitters.length; i++)
        widget.transmitters[i]: i,
    };
    _deviceDataMap = {};
    for (String device in widget.transmitters) {
      _deviceDataMap[device] = Transmiter(
        name: device,
        initialRssi: -100,
        lastSeen: DateTime.now(),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final sortedDevices = _deviceDataMap.values.toList();

    return PopScope(
      canPop: false, // Prevents the back button from working automatically
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show confirmation dialog
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Signal Acquisition",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildControlPanel(),
            _buildStatsBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.sensors, size: 18, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    "LIVE TRANSMITTER FEED",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blueGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sortedDevices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final device = sortedDevices[index];
                  return _buildDeviceCard(device);
                },
              ),
            ),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildToggleOption(
                  title: "Inside Room",
                  isSelected: _insideRoom,
                  onTap: () => setState(() => _insideRoom = true),
                  activeColor: Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleOption(
                  title: "Outside Room",
                  isSelected: !_insideRoom,
                  onTap: () => setState(() => _insideRoom = false),
                  activeColor: Colors.orange[700]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _toggleScan,
              icon: Icon(
                _isScanning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_isScanning ? "STOP SCANNING" : "START ACQUISITION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning
                    ? Colors.redAccent
                    : Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[200]!,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Inside", "${_insideData.length}", Colors.green),
          Container(height: 20, width: 1, color: Colors.grey[300]),
          _buildStatItem("Outside", "${_outsideData.length}", Colors.orange),
          Container(height: 20, width: 1, color: Colors.grey[300]),
          _buildStatItem("Packets", "$readingCount", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(Transmiter device) {
    final color = _getRssiColor(device.averageRssi);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Last seen: Just now",
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${device.averageRssi} dBm",
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              _buildSignalIndicator(device.averageRssi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIndicator(int rssi) {
    int bars = 0;
    if (rssi > -90) bars = 1;
    if (rssi > -80) bars = 2;
    if (rssi > -70) bars = 3;
    if (rssi > -60) bars = 4;

    return Row(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(left: 2),
          width: 3,
          height: (index + 1) * 3.0,
          decoration: BoxDecoration(
            color: index < bars ? _getRssiColor(rssi) : Colors.grey[200],
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    bool canExport = _insideData.length > 10 && _outsideData.length > 10;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: canExport ? _exportData : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[200],
          ),
          child: const Text(
            "Train ML Model & Save Room",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("How to collect data?"),
        content: const Text(
          "1. Select 'Inside Room' and walk around the classroom for 1-2 minutes.\n\n2. Select 'Outside Room' and walk in the corridor or nearby areas.\n\n3. Ensure you collect at least 50-100 tuples for each state for better ML accuracy.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -65) return Colors.green;
    if (rssi > -85) return Colors.orange;
    return Colors.red;
  }

  // Dialog to confirm exit
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Discard Data?"),
            content: const Text(
              "You have collected active signal data. Leaving this page will discard all unsaved tuples. Are you sure?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("DISCARD"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _takeSnapshot() {
    if (!_isScanning) return;

    List<int> tuple = [];
    for (String device in widget.transmitters) {
      int? index = _deviceIndexMap[device];
      Transmiter? deviceData = _deviceDataMap[device];

      if (index == null || deviceData == null) {
        tuple.add(100);
        continue;
      }

      if (DateTime.now().difference(deviceData.lastSeen).inSeconds > 5) {
        tuple.add(100);
      } else {
        tuple.add(deviceData.averageRssi.abs());
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
    int count = 0;
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
      withNames: widget.transmitters,
      androidScanMode: AndroidScanMode.lowLatency,
      removeIfGone: Duration(seconds: 3),
    );

    print(_insideRoom ? "Inside Room:" : "Outside Room:");

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      readingCount += results.length;
      // print(results.length);
      for (ScanResult r in results) {
        print('$count: $readingCount: ${r.device.platformName}');
        // final id = r.device.remoteId.str;
        final name = r.device.platformName.isEmpty
            ? "Unknown"
            : r.device.platformName;

        // print(name);
        if (widget.transmitters.isNotEmpty &&
            !widget.transmitters.contains(name)) {
          return;
        }
        final rssi = r.rssi;
        // print('$_deviceIndexMap[name]: $rssi');
        setState(() {
          count++;
          _deviceDataMap[name]!.addReading(rssi.abs());
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
          "https://falcon-sweet-physically.ngrok-free.app/train/${widget.classroomId}",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception("Model server failed: ${response.body}");
      }

      // ------------------ 3. PREPARE DEVICE LIST ------------------
      final devices = widget.transmitters.map((id) {
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
      await firestore.collection("classrooms").doc(widget.classroomId).set({
        "devices": widget.transmitters,
        "configured": true,
        "configured_at": FieldValue.serverTimestamp(),
        "input_dim": widget.transmitters.length,
        "training_data": jsonEncode(payload),
      }, SetOptions(merge: true));

      // ------------------ SUCCESS ------------------
      Navigator.pop(context); // close dialog
      Navigator.pop(
        context,
        true,
      ); // close data collection page with success result

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data sent & model trained successfully")),
      );
    } catch (e) {
      Navigator.pop(context); // close dialog
      // Navigator.pop(
      //   context,
      //   false,
      // ); // close data collection page with failure result

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
