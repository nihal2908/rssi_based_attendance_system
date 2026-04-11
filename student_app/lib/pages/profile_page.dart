import 'package:flutter/material.dart';
import 'package:student_app/controllers/auth_controller.dart';
import 'package:student_app/pages/login_page.dart';

import '../dependency_injection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController controller = sl<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: FutureBuilder(
          future: controller.fetchUserData(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (asyncSnapshot.hasError) {
              return Text('Error: ${asyncSnapshot.error}');
            }
            final userData = asyncSnapshot.data;
            if (userData == null) {
              return const Text('No user data found.');
            }
            final bool faceIDConfigured =
                userData['face_id_configured'] != null &&
                userData['face_id_configured'];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Name: ${userData['name'] ?? 'N/A'}'),
                Text('Email: ${userData['email'] ?? 'N/A'}'),
                Text(
                  'Registration no: ${userData['registration_no'] ?? 'N/A'}',
                ),

                Text(
                  'Face ID status: ${faceIDConfigured ? 'Configured' : 'Not Configured'}',
                ),
                if (faceIDConfigured) const SizedBox(height: 20),
                if (!faceIDConfigured)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Configure Face ID'),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await controller.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
