import 'package:flutter/material.dart';
import '../controllers/classroom_controller.dart';
import '../dependency_injection.dart';
import 'data_collection_page.dart';

class ClassroomConfigurationPage extends StatefulWidget {
  final String classroomId;
  const ClassroomConfigurationPage({super.key, required this.classroomId});

  @override
  State<ClassroomConfigurationPage> createState() =>
      _ClassroomConfigurationPageState();
}

class _ClassroomConfigurationPageState
    extends State<ClassroomConfigurationPage> {
  late final ClassroomController controller;
  final List<TextEditingController> _macControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    controller = sl<ClassroomController>(param1: widget.classroomId);
  }

  @override
  void dispose() {
    for (var c in _macControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addNewTransmitter() {
    setState(() {
      _macControllers.add(TextEditingController());
    });
  }

  void _removeTransmitter(int index) {
    if (_macControllers.length > 1) {
      setState(() {
        _macControllers[index].dispose();
        _macControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Configure Hardware',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildInstructionHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _macControllers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildTransmitterField(index),
            ),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildInstructionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RSSI Transmitters",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Register the MAC addresses or BSSIDs of the ESP32/BLE beacons installed in this room.",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransmitterField(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _macControllers[index],
                decoration: const InputDecoration(
                  labelText: 'Device MAC / BSSID',
                  hintText: 'XX:XX:XX:XX:XX:XX',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            ),
            if (_macControllers.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _removeTransmitter(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter() {
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addNewTransmitter,
              icon: const Icon(Icons.add),
              label: const Text("Add Device"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _handleStartCollection(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Start Collecting Data",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartCollection() {
    final transmitters = _macControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (transmitters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one transmitter address"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataCollectionPage(
          classroomId: widget.classroomId,
          transmitters: transmitters,
        ),
      ),
    );
    // print("Navigating with: $transmitters");
  }
}
