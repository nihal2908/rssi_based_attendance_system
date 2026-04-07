import 'dart:async';

import 'package:admin_app/models/transmiter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DataCollectionPage extends StatefulWidget {
  final List<String> transmitors;
  const DataCollectionPage({super.key, required this.transmitors});

  @override
  State<DataCollectionPage> createState() => _DataCollectionPageState();
}

class _DataCollectionPageState extends State<DataCollectionPage> {
  final Map<String, Transmiter> _devicesMap = {};
  StreamSubscription? _scanSubscription;
  Timer? _cleanupTimer;
  bool _isScanning = false;
  int readingCount = 0;

  @override
  void initState() {
    super.initState();
    // Periodically remove devices that haven't been seen recently
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _removeOldDevices();
    });
  }

  void _removeOldDevices() {
    final now = DateTime.now();
    setState(() {
      _devicesMap.removeWhere(
        (id, device) => now.difference(device.lastSeen).inSeconds > 5,
      ); // 5-second threshold
    });
  }

  Future<void> _toggleScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      setState(() => _isScanning = false);
      return;
    }

    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    setState(() => _isScanning = true);

    await FlutterBluePlus.startScan(continuousUpdates: true);

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      readingCount++;
      for (ScanResult r in results) {
        final id = r.device.remoteId.str;
        final name = r.device.platformName.isEmpty
            ? "Unknown Device"
            : r.device.platformName;

        setState(() {
          if (widget.transmitors.isNotEmpty &&
              !widget.transmitors.contains(id)) {
            return;
          }
          if (_devicesMap.containsKey(id)) {
            _devicesMap[id]!.addReading(r.rssi);
          } else {
            _devicesMap[id] = Transmiter(
              id: id,
              name: name,
              initialRssi: r.rssi,
              lastSeen: DateTime.now(),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort devices by signal strength (strongest first)
    final sortedDevices = _devicesMap.values.toList();
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
                    device.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(device.name),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        device.averageRssi.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRssiColor(device.averageRssi),
                        ),
                      ),
                      const Text(
                        "Live",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
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
    _cleanupTimer?.cancel();
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
