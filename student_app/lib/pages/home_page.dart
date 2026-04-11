import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
import '../dependency_injection.dart';
import 'account_setting_page.dart';
import 'course_detail_page.dart';
import 'join_course_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = sl<AuthController>();
  final CourseController courseController = sl<CourseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attend'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingPage(),
                ),
              );
            },
            icon: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Text('My Courses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListView.builder(
              itemCount: courseController.courses.length,
              itemBuilder: (context, index) {
                final course = courseController.courses[index];
                return ListTile(
                  title: Text(course.name),
                  subtitle: Text(course.code),
                  onTap: () {
                    courseController.currentCourse = course;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(courseController: courseController),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => JoinCoursePage()),
          );
        },
        child: Text('Join Course'),
      ),
    );
  }
}
