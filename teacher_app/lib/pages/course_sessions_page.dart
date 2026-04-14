
import 'package:flutter/material.dart';

import '../controllers/teacher_course_controller.dart';
import '../models/classroom.dart';
import '../models/scheduled_session.dart';
import 'course_calendar_page.dart';
import 'room_picker_page.dart';
import 'session_detail_page.dart';

class CourseSessionsPage extends StatefulWidget {
  final TeacherCourseController courseController;

  const CourseSessionsPage({super.key, required this.courseController});

  @override
  State<CourseSessionsPage> createState() => _CourseSessionsPageState();
}

class _CourseSessionsPageState extends State<CourseSessionsPage> {
  late final TeacherCourseController courseController;

  @override
  void initState() {
    courseController = widget.courseController;
    courseController.getCourseSessions();
    super.initState();
  }

  @override
  void dispose() {
    courseController.currentSession = null;
    courseController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeroHeader(),
          Expanded(
            child: ListenableBuilder(
              listenable: courseController,
              builder: (context, _) {
                if (courseController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (courseController.errorMessage != null) {
                  return Center(child: Text(courseController.errorMessage!));
                }
                final sessions = courseController.currentCourse?.sessions ?? [];
                if (sessions.isEmpty) {
                  return const Center(child: Text("No history found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (_, index) => _buildSessionCard(sessions[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewSessionTypeSelector,
        label: const Text("New Session"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final course = courseController.currentCourse;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.name ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  course?.code ?? "",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CourseCalendarPage(courseController: courseController),
              ),
            ),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(dynamic session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: session.attendanceOpen ? Colors.green : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          session.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${session.classroomName} • ${session.formattedTimeRange}",
        ),
        trailing: session.attendanceOpen
            ? const Badge(label: Text("LIVE"), backgroundColor: Colors.green)
            : const Icon(Icons.chevron_right),
        onTap: () {
          widget.courseController.currentSession = session;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailPage(
                courseController: widget.courseController,
                session: session,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewSessionTypeSelector() {
    courseController.getCompleteCourseDetails();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                "Create New Session",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat, color: Colors.blue),
              title: const Text("From Weekly Schedule"),
              subtitle: const Text("Autofill room and time from timetable"),
              onTap: () {
                Navigator.pop(context);
                _showScheduledSelector();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_task, color: Colors.green),
              title: const Text("Custom Session"),
              subtitle: const Text("Manually set all details"),
              onTap: () {
                Navigator.pop(context);
                _showCreateSessionForm();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduledSelector() {
    final schedules = courseController.currentCourse?.scheduledSessions ?? [];

    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No weekly schedules defined for this course."),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(schedule.weekdayString[0])),
                title: Text(
                  "${schedule.weekdayString} @ ${schedule.fullTimeRange}",
                ),
                subtitle: Text("Room: ${schedule.classroomName}"),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateSessionForm(session: schedule);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCreateSessionForm({ScheduledSession? session}) {
    final nameController = TextEditingController();
    String? selectedTeacherId =
        courseController.currentCourse?.teachers?.first.id;
    String? selectedRoomId = session?.classroomId;
    String? selectedRoomName = session?.classroomName;
    TimeOfDay? selectedStartTime = session != null
        ? TimeOfDay(hour: session.startHour, minute: session.startMin)
        : null;

    TimeOfDay? selectedEndTime = session != null
        ? TimeOfDay(hour: session.endHour, minute: session.endMin)
        : null;
    int weekDay = session != null ? session.weekday : DateTime.now().weekday;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Session Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Session Name",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTeacherId,
                    items: courseController.currentCourse?.teachers
                        ?.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => selectedTeacherId = val,
                    decoration: const InputDecoration(
                      labelText: "Assign Teacher",
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(selectedRoomName ?? "Select Room"),
                    subtitle: Text(
                      selectedRoomName == null
                          ? "No room selected"
                          : "Classroom set",
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final room = await Navigator.push<Classroom>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoomPickerPage(),
                        ),
                      );
                      if (room != null) {
                        setDialogState(() {
                          selectedRoomName = room.name;
                          selectedRoomId = room.id;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: Text(
                            selectedStartTime != null
                                ? "Start: ${selectedStartTime!.format(context)}"
                                : "Select Start Time",
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: selectedStartTime ?? TimeOfDay.now(),
                            );
                            if (t != null) {
                              setDialogState(() => selectedStartTime = t);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          title: Text(
                            selectedEndTime != null
                                ? "End: ${selectedEndTime!.format(context)}"
                                : "Select End Time",
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: selectedEndTime ?? TimeOfDay.now(),
                            );
                            if (t != null) {
                              setDialogState(() => selectedEndTime = t);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      selectedRoomId == null ||
                      selectedTeacherId == null ||
                      selectedStartTime == null ||
                      selectedEndTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in all fields."),
                      ),
                    );
                    return;
                  } else {
                    await courseController.createSession(
                      name: nameController.text.trim(),
                      classroomId: selectedRoomId!,
                      classroomName: selectedRoomName!,
                      teacherId: selectedTeacherId!,
                      startTime: _getCorrectTime(
                        weekDay,
                        selectedStartTime!.hour,
                        selectedStartTime!.minute,
                      ),
                      endTime: _getCorrectTime(
                        weekDay,
                        selectedEndTime!.hour,
                        selectedEndTime!.minute,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _getCorrectTime(int weekday, int hour, int minute) {
    final now = DateTime.now();
    final sessionDate = now.add(Duration(days: weekday - now.weekday));
    return DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      hour,
      minute,
    );
  }
}
