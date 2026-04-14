import 'package:flutter/material.dart';

import '../controllers/rooms_controller.dart';
import '../dependency_injection.dart';

class RoomPickerPage extends StatefulWidget {
  const RoomPickerPage({super.key});

  @override
  State<RoomPickerPage> createState() => _RoomPickerPageState();
}

class _RoomPickerPageState extends State<RoomPickerPage> {
  String searchQuery = "";
  final RoomsController roomsController = sl<RoomsController>();

  @override
  void initState() {
    super.initState();
    roomsController.fetchRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Classroom"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search room...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: roomsController,
        builder: (_, _) {
          if (roomsController.isLoading) return const Center(child: CircularProgressIndicator());
          
          final filteredRooms = roomsController.rooms.where((r) => 
            r.name.toLowerCase().contains(searchQuery)).toList();

          return ListView.builder(
            itemCount: filteredRooms.length,
            itemBuilder: (context, index) {
              final room = filteredRooms[index];
              return ListTile(
                leading: const Icon(Icons.meeting_room),
                title: Text(room.name),
                subtitle: Text("Capacity: ${room.capacity}"),
                onTap: () => Navigator.pop(context, room),
              );
            },
          );
        },
      ),
    );
  }
}