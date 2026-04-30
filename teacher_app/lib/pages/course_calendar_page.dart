import 'package:flutter/material.dart';

import '../controllers/teacher_course_controller.dart';
import '../models/classroom.dart';
import 'room_picker_page.dart';

class CourseCalendarPage extends StatefulWidget {
  final TeacherCourseController courseController;
  const CourseCalendarPage({super.key, required this.courseController});

  @override
  State<CourseCalendarPage> createState() => _CourseCalendarPageState();
}

class _CourseCalendarPageState extends State<CourseCalendarPage> {
  late final TeacherCourseController courseController;

  @override
  void initState() {
    courseController = widget.courseController;
    courseController.getCourseSchedule();
    super.initState();
  }

  @override
  void dispose() {
    courseController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule')),
      body: ListenableBuilder(
        listenable: courseController,
        builder: (context, _) {
          if (courseController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions =
              courseController.currentCourse?.scheduledSessions ?? [];
          return RefreshIndicator(
            onRefresh: () => courseController.getCourseSchedule(),
            child: courseController.errorMessage != null
                ? Center(child: Text(courseController.errorMessage!))
                : sessions.isEmpty
                ? const Center(child: Text("No schedule found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (_, index) {
                      final s = sessions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            _buildDayIndicator(s.weekdayString),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.fullTimeRange,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Room: ${s.classroomName}",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddScheduleSheet,
        label: const Text("Add Schedule"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayIndicator(String day) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          day.substring(0, 3).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showAddScheduleSheet() async {
    int selectedDay = 1;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);
    Classroom? selectedRoom;
    List<String> days = const [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Weekly Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Day Picker
              DropdownButtonFormField<int>(
                initialValue: selectedDay,
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(value: i + 1, child: Text(days[i])),
                ),
                onChanged: (val) => setSheetState(() => selectedDay = val!),
                decoration: const InputDecoration(labelText: "Day of Week"),
              ),

              // Start Time Pickers
              ListTile(
                title: Text("Start: ${start.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (t != null) setSheetState(() => start = t);
                },
              ),

              // End Time Pickers
              ListTile(
                title: Text("End: ${end.format(context)}"),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (t != null) setSheetState(() => end = t);
                },
              ),

              // Room Selector
              ListTile(
                title: Text(selectedRoom?.name ?? "Select Room"),
                subtitle: Text(
                  selectedRoom == null ? "No room selected" : "Classroom set",
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final room = await Navigator.push<Classroom>(
                    context,
                    MaterialPageRoute(builder: (_) => const RoomPickerPage()),
                  );
                  if (room != null) setSheetState(() => selectedRoom = room);
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: selectedRoom == null
                    ? null
                    : () async {
                        await courseController.addScheduledSession(
                          weekday: selectedDay,
                          startTime: start,
                          endTime: end,
                          roomId: selectedRoom!.id,
                          roomName: selectedRoom!.name,
                        );
                        Navigator.pop(context);
                      },
                child: const Text("SAVE SCHEDULE"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
