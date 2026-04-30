import 'package:admin_app/models/classroom.dart';
import 'package:flutter/material.dart';

import '../controllers/classroom_controller.dart';
import '../dependency_injection.dart';
import '../models/session.dart';
import 'classroom_configiration_page.dart';

class ClassroomDetailsPage extends StatefulWidget {
  final String classroomId;
  const ClassroomDetailsPage({super.key, required this.classroomId});

  @override
  State<ClassroomDetailsPage> createState() => _ClassroomDetailsPageState();
}

class _ClassroomDetailsPageState extends State<ClassroomDetailsPage> {
  late final ClassroomController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<ClassroomController>(param1: widget.classroomId);
    controller.fetchRoomDetails();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final classroom = controller.currentRoom;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(classroom?.name ?? "Room Details"),
            elevation: 0,
            actions: [
              if (classroom?.configured ?? false)
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () => _navigateToConfig(context),
                ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : classroom == null
              ? const Center(child: Text("Room data not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(classroom),
                      const SizedBox(height: 24),
                      _buildInfoGrid(classroom),
                      const SizedBox(height: 24),
                      _buildHardwareSection(classroom),
                      if (!(classroom.configured)) const SizedBox(height: 40),
                      if (!(classroom.configured)) _buildConfigureCTA(context),
                      const SizedBox(height: 32),
                      _buildSessionHistory(controller.sessions),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatusHeader(Classroom classroom) {
    bool isConfigured = classroom.configured;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isConfigured ? Colors.green[600] : Colors.orange[700],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Icons.verified_user : Icons.warning_amber_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? "Operational" : "Action Required",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isConfigured
                      ? "Configured on ${_formatDate(classroom.configuredAt)}"
                      : "Hardware parameters not yet initialized.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Classroom classroom) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildInfoTile("Capacity", "${classroom.capacity} Students", Icons.people),
        _buildInfoTile("Location", classroom.location, Icons.location_on),
        _buildInfoTile(
          "Input Dim",
          "${classroom.devices.length} Devices",
          Icons.settings_input_component,
        ),
        _buildInfoTile(
          "Last Update",
          _formatDate(classroom.configuredAt),
          Icons.history,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareSection(Classroom classroom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Registered Hardware Devices",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (classroom.devices.isEmpty)
          const Text(
            "No devices registered.",
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (classroom.devices as List)
                .map(
                  (d) => Chip(
                    avatar: const Icon(Icons.bluetooth, size: 14),
                    label: Text(d),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.blueGrey, width: 0.5),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildConfigureCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Text(
            "Ready to set up RSSI Beacons?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Configure this room to enable real-time attendance tracking using localized BLE signals.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToConfig(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Initialize Configuration"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory(List<Session> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Session History",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "${sessions.length} Total",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          _buildEmptyHistory()
        else
          ListView.separated(
            shrinkWrap: true, // Required inside SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionTile(session);
            },
          ),
      ],
    );
  }

  Widget _buildSessionTile(Session session) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Date Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _formatMonth(session.startTime),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${session.startTime.day}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Session Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.course?.name ?? "Unknown Course",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.teacher != null ? session.teacher!.name : "N/A",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          // Attendance Count Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.formattedTimeRange,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                session.name,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "No past sessions found for this room.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    return months[date.month - 1];
  }

  void _navigateToConfig(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClassroomConfigurationPage(classroomId: widget.classroomId),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    // Basic formatting logic for your Firestore Timestamps
    if (date == null) return "N/A";
    return "${date.day}/${date.month}/${date.year}";
  }
}
