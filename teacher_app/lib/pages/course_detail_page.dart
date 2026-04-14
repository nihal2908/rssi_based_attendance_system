import 'package:flutter/material.dart';

import '../controllers/teacher_course_controller.dart';
import 'course_members_page.dart';
import 'course_sessions_page.dart';

class CourseDetailPage extends StatefulWidget {
  final TeacherCourseController courseController;
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
