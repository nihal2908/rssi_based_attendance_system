import 'package:flutter/material.dart';

import '../controllers/teacher_course_controller.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class CourseMembersList extends StatefulWidget {
  final TeacherCourseController courseController;
  const CourseMembersList({super.key, required this.courseController});

  @override
  State<CourseMembersList> createState() => _CourseMembersListState();
}

class _CourseMembersListState extends State<CourseMembersList> {
  late final TeacherCourseController courseController;

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
        
        final course = courseController.currentCourse;
        final int totalItems = course != null
            ? 1 + course.teachers!.length + 1 + course.studentsEnrolled!.length
            : 2;

        return RefreshIndicator(
          onRefresh: () => courseController.getCourseSessions(),
          child: courseController.errorMessage != null || course == null
              ? Center(
                  child: Text(
                    courseController.errorMessage ??
                        "There was an error loading course details",
                  ),
                )
              : ListView.builder(
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // 1. Teacher Header
                    if (index == 0) {
                      return _buildHeader(
                        "Teachers (${course.teachers!.length})",
                      );
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
                    return _buildMemberTile(
                      student: course.studentsEnrolled![studentIndex],
                    );
                  },
                ),
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
