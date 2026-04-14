import 'package:flutter/material.dart';

import '../controllers/teacher_course_controller.dart';
import '../dependency_injection.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final TeacherCourseController courseController =
      sl<TeacherCourseController>();

  @override
  void dispose() {
    courseController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Create New Course"), elevation: 0),
      body: ListenableBuilder(
        listenable: courseController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Setup your Classroom",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Students will use the code to join your course.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Course Name Input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Course Name",
                      hintText: "e.g. Mobile Computing",
                      prefixIcon: const Icon(Icons.book),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? "Enter course name" : null,
                  ),
                  const SizedBox(height: 20),

                  // Course Code Input
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "Course Code",
                      hintText: "e.g. CS101",
                      prefixIcon: const Icon(Icons.vpn_key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "", // Hides the character counter
                    ),
                    validator: (val) =>
                        val!.length < 3 ? "Code too short" : null,
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton(
                    onPressed: courseController.isLoading
                        ? null
                        : () => _handleCreate(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: courseController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "CREATE COURSE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

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
            ),
          );
        },
      ),
    );
  }

  void _handleCreate(BuildContext context) async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid name and code")),
      );
      return;
    }

    final success = await courseController.createCourse(name: name, code: code);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Successfully created course!"),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      courseController.fetchAssignedCourses();
      Navigator.pop(context);
    }
  }
}
