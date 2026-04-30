import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../dependency_injection.dart';
import 'courses_list_page.dart';
import 'notifications_list_page.dart';
import 'classrooms_list_page.dart';
import 'students_list_page.dart';
import 'teachers_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController dashboardController = sl<DashboardController>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dashboardController.fetchDashboardData();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dashboardController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              "Welcome, ${dashboardController.username}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          body: dashboardController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Notification Section in Body ---
                      _buildNotificationBanner(context),

                      const SizedBox(height: 24),
                      const Text(
                        "System Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Sleek Grid for Stats ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildStatCard(
                            context,
                            title: "Courses",
                            count: dashboardController.courseCount,
                            icon: Icons.auto_stories,
                            color: Colors.blue,
                            onTap: () =>
                                _navigate(context, const CoursesListPage()),
                          ),
                          _buildStatCard(
                            context,
                            title: "Teachers",
                            count: dashboardController.teacherCount,
                            icon: Icons.supervisor_account,
                            color: Colors.orange,
                            onTap: () =>
                                _navigate(context, const TeachersListPage()),
                          ),
                          _buildStatCard(
                            context,
                            title: "Students",
                            count: dashboardController.studentCount,
                            icon: Icons.school,
                            color: Colors.green,
                            onTap: () =>
                                _navigate(context, const StudentsListPage()),
                          ),
                          _buildStatCard(
                            context,
                            title: "Classrooms",
                            count: dashboardController.classroomCount,
                            icon: Icons.meeting_room,
                            color: Colors.purple,
                            onTap: () =>
                                _navigate(context, const ClassroomsListPage()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => dashboardController.isLoading
                ? null
                : dashboardController.fetchDashboardData(),
            backgroundColor: Colors.blue[700],
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Refresh", style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBanner(BuildContext context) {
    return InkWell(
      onTap: () => _navigate(context, const NotificationsListPage()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.notifications_active, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "You have ${dashboardController.notificationCount} pending alerts",
                    style: TextStyle(color: Colors.blue[50]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
