import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/room_controller.dart';
import '../dependency_injection.dart';
import '../models/classroom.dart';

class AttendanceActionPage extends StatefulWidget {
  final String sessionId;
  final Classroom classroom;
  const AttendanceActionPage({required this.classroom, required this.sessionId, super.key});

  @override
  State<AttendanceActionPage> createState() => _AttendanceActionPageState();
}

class _AttendanceActionPageState extends State<AttendanceActionPage> {
  final RoomController _controller = sl<RoomController>();
  bool _modelExists = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _controller.init(widget.classroom);
    _modelExists = await _controller.checkModelExists(widget.classroom.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        // Automatically pop if attendance is successful
        if (_controller.statusMessage == "SUCCESS") {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context, true);
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Verify Location")),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildRoomHeader(widget.classroom),
                const Spacer(),
                Text(
                  _controller.statusMessage,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                if (_controller.isScanning) const CircularProgressIndicator(),
                if (!_controller.isScanning) ...[
                  if (!_modelExists)
                    ElevatedButton(
                      onPressed: () async {
                        await _controller.downloadRoomConfig(
                          widget.classroom.id,
                        );
                        _setup();
                      },
                      child: const Text("Download Config"),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _controller.startAttendanceVerification(widget.sessionId),
                        child: const Text("Verify My Location"),
                      ),
                    ),
                ],
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomHeader(Classroom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              room.location,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
