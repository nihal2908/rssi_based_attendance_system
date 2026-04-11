import 'package:flutter/material.dart';

import '../controllers/course_controller.dart';
import '../dependency_injection.dart';

class JoinCoursePage extends StatelessWidget {
  JoinCoursePage({super.key});

  final TextEditingController _courseCodeController = TextEditingController();
  final CourseController courseController = sl<CourseController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Course')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter Course Code'),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Course Code',
              ),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final code = _courseCodeController.text.trim();
              if(code.isEmpty) return;
              courseController.joinCourse(code);
            },
            child: Text('Join'),
          ),
        ],
      )
    );
  }
}