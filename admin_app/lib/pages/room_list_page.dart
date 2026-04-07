import 'package:admin_app/controllers/room_controller.dart';
import 'package:admin_app/pages/add_room_page.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';
import 'room_page.dart';

class RoomListPage extends StatefulWidget {
  const RoomListPage({super.key});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  final RoomsController controller = sl<RoomsController>();

  @override
  void initState() {
    super.initState();
    controller.fetchRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (_, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.rooms.isEmpty) {
            return const Center(child: Text('No rooms available'));
          }
          return ListView.builder(
            itemCount: controller.rooms.length,
            itemBuilder: (context, index) {
              final room = controller.rooms[index];
              return ListTile(
                title: Text(room.name),
                subtitle: Text('Capacity: ${room.capacity}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomPage(roomId: room.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRoomPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
