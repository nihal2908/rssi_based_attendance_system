import 'package:flutter/material.dart';

import '../controllers/rooms_controller.dart';
import '../dependency_injection.dart';
import 'room_details_page.dart';

class ClassRoomListPage extends StatefulWidget {
  const ClassRoomListPage({super.key});

  @override
  State<ClassRoomListPage> createState() => _ClassRoomListPageState();
}

class _ClassRoomListPageState extends State<ClassRoomListPage> {
  final RoomsController roomsController = sl<RoomsController>();

  @override
  void initState() {
    roomsController.fetchRooms();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classroom List')),
      body: ListenableBuilder(
        listenable: roomsController,
        builder: (_, _) {
          return ListView.builder(
            itemCount:
                roomsController.rooms.length, // Replace with actual room count
            itemBuilder: (context, index) {
              final room =
                  roomsController.rooms[index]; // Replace with actual room data
              return ListTile(
                title: Text(room.name),
                subtitle: Text(room.location),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomDetailsPage(roomId: room.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
