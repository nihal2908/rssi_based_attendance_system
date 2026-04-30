import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../dependency_injection.dart';
import 'login_page.dart';

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
  void dispose() {
    authController.clearError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background for depth
      appBar: AppBar(
        title: const Text('Account Settings'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          final user = authController.user;
          final currentUser = authController.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(currentUser),
                const SizedBox(height: 24),
                _buildInfoSection(user, currentUser),
                const SizedBox(height: 24),
                _buildActionsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            backgroundImage: currentUser?.avatar != null
                ? NetworkImage(currentUser!.avatar!)
                : null,
            child: currentUser?.avatar == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            currentUser?.name ?? 'Teacher Name',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic user, dynamic currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text("Email Address"),
              subtitle: Text(user.email ?? 'Not set'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              "SECURITY",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Logout Session",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authController.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
