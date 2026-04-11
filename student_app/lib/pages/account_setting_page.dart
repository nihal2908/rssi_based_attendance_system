import 'package:flutter/material.dart';
import 'package:student_app/controllers/auth_controller.dart';
import 'package:student_app/pages/login_page.dart';

import '../dependency_injection.dart';

class AccountSettingPage extends StatefulWidget {
  const AccountSettingPage({super.key});

  @override
  State<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  final AuthController authController = sl<AuthController>();

  @override
  void initState() {
    authController.fetchUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Settings')),
      body: ListenableBuilder(
        listenable: authController,
        builder: (_, _) {
          final user = authController.user;
          if (user == null) {
            return Center(child: Text('No user logged in'));
          }
          final currentUser = authController.currentUser;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: currentUser != null
                        ? NetworkImage(
                            currentUser.avatar ??
                                'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png',
                          )
                        : null,
                  ),
                ),
                Text('Email: ${user.email}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text(
                  'Name: ${currentUser?.name ?? 'Not available'}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Name: ${currentUser?.registrationNo ?? 'Not available'}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          await authController.logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
        },
        child: Text('LOGOUT'),
      ),
    );
  }
}
