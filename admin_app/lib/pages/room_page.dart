import 'package:admin_app/controllers/room_controller.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';
import '../models/room.dart';
import 'room_configiration_page.dart';

class RoomPage extends StatefulWidget {
  final String roomId;
  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late final String roomId;
  final RoomsController controller = sl<RoomsController>();

  @override
  void initState() {
    roomId = widget.roomId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.getRoomDetails(roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room Details'), actions: [
              IconButton(
                onPressed: () {
                  controller.deleteRoom(roomId).then((_) {
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting room: $error')),
                    );
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              )
            ],),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room Details'), actions: [
              IconButton(
                onPressed: () {
                  controller.deleteRoom(roomId).then((_) {
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting room: $error')),
                    );
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              )
            ],),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final room = Room.fromMap(snapshot.data as Map<String, dynamic>);
        return Scaffold(
          appBar: AppBar(title: Text(room.name), actions: [
              IconButton(
                onPressed: () {
                  controller.deleteRoom(roomId).then((_) {
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting room: $error')),
                    );
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              )
            ],),
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RoomConfigurationPage(roomId: room.id),
                      ),
                    );
                  },
                  child: const Text('Configure Room'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
