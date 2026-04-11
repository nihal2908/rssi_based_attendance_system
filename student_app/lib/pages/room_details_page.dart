import 'package:flutter/material.dart';

import '../controllers/rooms_controller.dart';
import '../dependency_injection.dart';
import 'mark_attendance_page.dart';

class RoomDetailsPage extends StatefulWidget {
  final String roomId;
  const RoomDetailsPage({required this.roomId, super.key});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  late final String roomId;
  final RoomsController controller = sl<RoomsController>();

  @override
  void initState() {
    roomId = widget.roomId;
    controller.getRoomDetails(roomId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        if (controller.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final room = controller.currentRoom;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room Details')),
            body: const Center(child: Text('Room not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(room.name)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capacity: ${room.capacity}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Location: ${room.location}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${room.configured ? 'Configured' : 'Not Configured'}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),

                Text(
                  'Devices: ${room.devices.join(', ')}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    controller
                        .downloadRoomConfig(roomId)
                        .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Room configuration downloaded successfully',
                              ),
                            ),
                          );
                        })
                        .catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error downloading room configuration: $error',
                              ),
                            ),
                          );
                        });
                  },
                  child: const Text('Download Room Configurations'),
                ),
                if (room.configured) ...[
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkAttendancePage(roomId: roomId, transmitors: controller.currentRoom!.devices,),
                        ),
                      );
                    },
                    child: const Text('Mark Attendance'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
