import 'package:flutter/material.dart';
import 'package:student_app/pages/attendance_action_page.dart';

import '../controllers/course_controller.dart';
import '../models/session.dart';

class SessionDetailPage extends StatefulWidget {
  final CourseController courseController;
  final Session session;
  const SessionDetailPage({
    super.key,
    required this.courseController,
    required this.session,
  });

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  int _currentIndex = 0;
  late final Session session;
  late final CourseController courseController;

  @override
  void initState() {
    courseController = widget.courseController;
    session = widget.session;
    // courseController.currentSession = session;
    courseController.fetchSessionDetails(session.id);
    super.initState();
  }

  @override
  void dispose() {
    courseController.currentSession = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: courseController,
      builder: (_, _) {
        final List<Widget> children = [_buildInfoTab(), _buildAttendeeTab()];

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            actions: [
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          body: children[_currentIndex],
          floatingActionButton: _currentIndex == 0 && session.attendanceOpen
              ? FloatingActionButton.extended(
                  onPressed: () => _navigateToAttendance(context),
                  label: const Text("Mark Attendance"),
                  icon: const Icon(Icons.how_to_reg),
                  backgroundColor: Colors.blueAccent,
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.info), label: "Details"),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: "Attendees",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Time Card using your custom getters
        Card(
          child: ListTile(
            leading: const Icon(Icons.access_time_filled, color: Colors.blue),
            title: const Text("Schedule"),
            subtitle: Text(session.formattedTimeRange),
          ),
        ),

        // Teacher Card
        _sectionHeader("Instructor"),
        if (session.teacher != null)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(session.teacher!.name),
            subtitle: Text(session.teacher!.email),
          )
        else
          const ListTile(title: Text("Loading instructor details...")),

        // Classroom Card
        _sectionHeader("Classroom & Tech"),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Room: ${session.classroomName}"),
                if (session.classroom != null) ...[
                  const Divider(),
                  Text("Location: ${session.classroom!.location}"),
                  Text("Capacity: ${session.classroom!.capacity} Students"),
                  const SizedBox(height: 8),
                  const Text(
                    "Configured Devices:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: session.classroom!.devices
                        .map(
                          (d) => Chip(
                            label: Text(
                              d,
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Loading classroom specifications...",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeTab() {
    final attendees = session.attendees ?? [];

    if (attendees.isEmpty) {
      return const Center(child: Text("No attendees found or loading..."));
    }

    return ListView.builder(
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final student = attendees[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: student.avatar != null
                ? NetworkImage(student.avatar!)
                : null,
            child: student.avatar == null ? const Icon(Icons.person) : null,
          ),
          title: Text(student.name),
          subtitle: Text("Reg: ${student.registrationNo}"),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context) async {
    if (session.classroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Room not assigned to this session"),
        ),
      );
      return;
    }
    
    final didMarkAttendance = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (context) => AttendanceActionPage(classroom: session.classroom!),
    ),
  );

  if (didMarkAttendance == true && mounted) {
    // Refresh the session details to show the new attendee
    courseController.fetchSessionDetails(session.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance marked successfully!")),
    );
  }
  }
}
