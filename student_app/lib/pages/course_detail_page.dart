import 'package:flutter/material.dart';
import 'package:student_app/controllers/course_controller.dart';

import '../models/student.dart';
import '../models/teacher.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseController courseController;
  const CourseDetailPage({super.key, required this.courseController});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: switch (_currentIndex) {
        0 => CourseSessionsPage(courseController: widget.courseController),
        1 => CourseMembersList(courseController: widget.courseController),
        _ => Container(),
      },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.history)),
          BottomNavigationBarItem(icon: Icon(Icons.people)),
        ],
      ),
    );
  }
}

class CourseSessionsPage extends StatelessWidget {
  final CourseController courseController;

  const CourseSessionsPage({super.key, required this.courseController});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Course Sessions'));
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
              return _buildHeader("Teachers");
            }

            // 2. Teacher List
            if (index <= course.teachers!.length) {
              return _buildMemberTile(
                teacher: course.teachers![index - 1],
              );
            }

            // 3. Student Header
            if (index == course.teachers!.length + 1) {
              return _buildHeader(
                "Students (${course.studentsEnrolled!.length})",
              );
            }

            // 4. Student List
            final studentIndex = index - (course.teachers!.length + 2);
            return _buildMemberTile(student: course.studentsEnrolled![studentIndex]);
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
