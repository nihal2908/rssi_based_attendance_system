import 'package:admin_app/controllers/dashboard_controller.dart';
import 'package:admin_app/pages/notifications_page.dart';
import 'package:admin_app/pages/room_list_page.dart';
import 'package:admin_app/pages/room_page.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController controller = sl<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(controller.username),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                },
                icon: Badge.count(
                  count: controller
                      .notificationCount, // The number of notifications
                  child: const Icon(Icons.notifications),
                ),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Rooms'),
                        trailing: Text(controller.roomCount.toString()),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomListPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text('Teachers'),
                        trailing: Text(controller.teacherCount.toString()),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomListPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text('Students'),
                        trailing: Text(controller.studentCount.toString()),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomListPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
