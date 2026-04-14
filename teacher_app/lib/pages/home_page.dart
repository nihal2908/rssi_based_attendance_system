import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/teacher_course_controller.dart';
import '../dependency_injection.dart';
import 'account_setting_page.dart';
import 'course_detail_page.dart';
import 'create_course_page.dart';
import 'join_course_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController authController = sl<AuthController>();
  final TeacherCourseController courseController =
      sl<TeacherCourseController>();

  @override
  void initState() {
    courseController.fetchAssignedCourses();
    super.initState();
  }

  @override
  void dispose() {
    courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attend',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingPage(),
                ),
              ),
              icon: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: courseController,
        builder: (context, _) {
          if (courseController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(courseController.errorMessage!),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => courseController.fetchAssignedCourses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseController.assignedCourses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildWelcomeHeader();
                }

                final course = courseController.assignedCourses[index - 1];
                return _buildCourseCard(course);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            // Wrap fits the content height automatically
            children: [
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('Create New Course'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateCoursePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Join with Code'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JoinCoursePage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back,",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const Text(
            "Your Courses",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.book_outlined, color: Colors.blue),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            course.code,
            style: TextStyle(color: Colors.grey[600], letterSpacing: 1.1),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          courseController.currentCourse = course;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CourseDetailPage(courseController: courseController),
            ),
          );
        },
      ),
    );
  }
}
