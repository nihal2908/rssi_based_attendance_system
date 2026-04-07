import 'package:admin_app/controllers/notification_controller.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationController controller = sl<NotificationController>();

  @override
  void initState() {
    super.initState();
    controller.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Requests'),
        actions: [
          IconButton(
            onPressed: controller.refreshNotifications,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: controller.enterSearchMode,
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (_, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.notifications.isEmpty) {
            return const Center(child: Text('No new requests'));
          }
          return ListView.builder(
            itemCount: controller.notifications.length,
            itemBuilder: (_, index) {
              final notification = controller.notifications[index];
              return ListTile(
                title: Text(notification.title),
                subtitle: Text(notification.message),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        controller.rejectRequest(notification);
                      },
                      child: Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        controller.allowRequest(notification);
                      },
                      child: Text('Allow'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
