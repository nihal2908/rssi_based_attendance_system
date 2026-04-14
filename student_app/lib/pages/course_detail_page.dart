import 'package:flutter/material.dart';
import 'package:student_app/controllers/course_controller.dart';

import '../models/student.dart';
import '../models/teacher.dart';
import 'session_detail_page.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseController courseController;
  const CourseDetailPage({super.key, required this.courseController});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.courseController.currentCourse?.name ?? "Course"),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: "Sessions"),
              Tab(icon: Icon(Icons.people_outline), text: "Members"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CourseSessionsPage(courseController: widget.courseController),
            CourseMembersList(courseController: widget.courseController),
          ],
        ),
      ),
    );
  }
}

class CourseSessionsPage extends StatefulWidget {
  final CourseController courseController;

  const CourseSessionsPage({super.key, required this.courseController});

  @override
  State<CourseSessionsPage> createState() => _CourseSessionsPageState();
}

class _CourseSessionsPageState extends State<CourseSessionsPage> {
  late final CourseController courseController;

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
    return Column(
      children: [
        _buildHeroHeader(),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.courseController,
            builder: (context, _) {
              if (widget.courseController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final sessions =
                  widget.courseController.currentCourse?.sessions ?? [];
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
    );
  }

  Widget _buildHeroHeader() {
    final course = widget.courseController.currentCourse;
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
                builder: (_) => CourseCalendarPage(
                  courseController: widget.courseController,
                ),
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
}

class CourseMembersList extends StatefulWidget {
  final CourseController courseController;
  const CourseMembersList({super.key, required this.courseController});

  @override
  State<CourseMembersList> createState() => _CourseMembersListState();
}

class _CourseMembersListState extends State<CourseMembersList> {
  late final CourseController courseController;

  @override
  void initState() {
    courseController = widget.courseController;
    courseController.getCourseMembers();
    super.initState();
  }

  @override
  void dispose() {
    courseController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: courseController,
      builder: (_, _) {
        if (courseController.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (courseController.errorMessage != null) {
          return Center(child: Text(courseController.errorMessage!));
        }
        final course = courseController.currentCourse;
        if (course == null) {
          return Center(
            child: Text('There was an error loading course details'),
          );
        }
        final int totalItems =
            1 + course.teachers!.length + 1 + course.studentsEnrolled!.length;

        return ListView.builder(
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // 1. Teacher Header
            if (index == 0) {
              return _buildHeader("Teachers (${course.teachers!.length})");
            }

            // 2. Teacher List
            if (index <= course.teachers!.length) {
              return _buildMemberTile(teacher: course.teachers![index - 1]);
            }

            // 3. Student Header
            if (index == course.teachers!.length + 1) {
              return _buildHeader(
                "Students (${course.studentsEnrolled!.length})",
              );
            }

            // 4. Student List
            final studentIndex = index - (course.teachers!.length + 2);
            return _buildMemberTile(
              student: course.studentsEnrolled![studentIndex],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildMemberTile({Teacher? teacher, Student? student}) {
    final name = teacher?.name ?? student?.name ?? 'Unknown';
    final isTeacher = teacher != null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTeacher ? Colors.blue : Colors.grey[300],
        child: Text(name[0].toUpperCase()),
      ),
      title: Text(name),
    );
  }
}

class CourseCalendarPage extends StatefulWidget {
  final CourseController courseController;
  const CourseCalendarPage({super.key, required this.courseController});

  @override
  State<CourseCalendarPage> createState() => _CourseCalendarPageState();
}

class _CourseCalendarPageState extends State<CourseCalendarPage> {
  late final CourseController courseController;

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
          final sessions =
              courseController.currentCourse?.scheduledSessions ?? [];
          return ListView.builder(
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
          );
        },
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
}
