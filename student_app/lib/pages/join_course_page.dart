import 'package:flutter/material.dart';

import '../controllers/course_controller.dart';
import '../dependency_injection.dart';

class JoinCoursePage extends StatefulWidget {
  const JoinCoursePage({super.key});

  @override
  State<JoinCoursePage> createState() => _JoinCoursePageState();
}

class _JoinCoursePageState extends State<JoinCoursePage> {
  final TextEditingController _courseCodeController = TextEditingController();
  final CourseController courseController = sl<CourseController>();

  @override
  void dispose() {
    courseController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Join New Course'), elevation: 0),
      body: ListenableBuilder(
        listenable: courseController,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock your classroom',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask your teacher for the course code, then enter it below to get started.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Enhanced TextField
                TextField(
                  controller: _courseCodeController,
                  autofocus: true,
                  textCapitalization:
                      TextCapitalization.characters, // Codes are usually CAPS
                  decoration: InputDecoration(
                    labelText: 'Course Code',
                    hintText: 'e.g. CS101-ABC',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 24),

                // Loading / Action Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: courseController.isLoading
                        ? null
                        : () => _handleJoin(context),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: courseController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Join Course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Error Message Display
                if (courseController.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: Text(
                        courseController.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleJoin(BuildContext context) async {
    final code = _courseCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid code")),
      );
      return;
    }

    final success = await courseController.joinCourse(code);

    if (success && context.mounted) {
      // Show a success message and go back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Successfully joined course!"),
        ),
      );
      Navigator.pop(context, success);
    }
  }
}
