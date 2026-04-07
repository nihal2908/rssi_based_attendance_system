import 'package:admin_app/controllers/room_controller.dart';
import 'package:flutter/material.dart';

import '../dependency_injection.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final RoomsController controller = sl<RoomsController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Room')),
      body: Form(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Room Name'),
              ),
              TextFormField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Room Location'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.addRoom(
                    nameController.text.trim(),
                    int.parse(capacityController.text.trim()),
                    locationController.text.trim(),
                  );
                },
                child: const Text('Add Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
