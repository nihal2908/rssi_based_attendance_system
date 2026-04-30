import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../dependency_injection.dart';

class AddClassroomPage extends StatefulWidget {
  const AddClassroomPage({super.key});

  @override
  State<AddClassroomPage> createState() => _AddClassroomPageState();
}

class _AddClassroomPageState extends State<AddClassroomPage> {
  final DashboardController controller = sl<DashboardController>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    capacityController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Register New Classroom',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),

                _buildInputField(
                  label: "Classroom Name",
                  hint: "e.g. NLH 1 or Lab 302",
                  controller: nameController,
                  icon: Icons.meeting_room_outlined,
                  validator: (val) => val!.isEmpty ? "Enter room name" : null,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: "Seating Capacity",
                  hint: "e.g. 150",
                  controller: capacityController,
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? "Enter capacity" : null,
                ),
                const SizedBox(height: 20),

                _buildInputField(
                  label: "Classroom Location",
                  hint: "e.g. Academic Building, 2nd Floor",
                  controller: locationController,
                  icon: Icons.location_on_outlined,
                  validator: (val) => val!.isEmpty ? "Enter location" : null,
                ),
                const SizedBox(height: 40),

                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Room Identification",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.purple[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter the details below to register a new classroom into the tracking system.",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.purple[300]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purple[400]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            await controller.addClassroom(
              nameController.text.trim(),
              int.parse(capacityController.text.trim()),
              locationController.text.trim(),
            );
            // Optionally pop after success or show a snackbar
            Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Register Classroom',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
